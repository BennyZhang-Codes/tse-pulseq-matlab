function [denoised,info] = denoise_TGV2(noisy,alpha1,varargin)
%DENOISE_TGV2 Second-order TGV-L2 denoising with a primal-dual solver.
%
% [U,INFO] = DENOISE_TGV2(F,ALPHA1,'Alpha0',2*ALPHA1) solves
%
%   min_{u,w} 0.5*||u-f||_2^2
%       + alpha1*||grad(u)-w||_{2,1}
%       + alpha0*||E(w)||_{F,1},
%
% where E is the symmetrized gradient. Forward differences use zero
% Neumann boundary conditions and the implemented adjoints match those
% differences exactly. The default fixed primal/dual steps are deliberately
% conservative for reproducible image-domain MRI denoising.

    p = inputParser;
    p.addParameter('Alpha0',2*alpha1, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('MaxIterations',500, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 1 && x == floor(x));
    p.addParameter('Tolerance',1e-5, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
    p.addParameter('StepSize',0.125, ...
        @(x) isnumeric(x) && isscalar(x) && isfinite(x) && x > 0 && x <= 0.2);
    p.addParameter('Nonnegative',true,@(x) islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    validateattributes(noisy,{'numeric'},{'2d','real','finite','nonempty'}, ...
        mfilename,'noisy',1);
    validateattributes(alpha1,{'numeric'},{'scalar','real','finite','nonnegative'}, ...
        mfilename,'alpha1',2);
    f = double(noisy);
    if alpha1 == 0 || opt.Alpha0 == 0
        denoised = cast(noisy,'like',noisy);
        info = struct('iterations',0,'relativeChange',0,'converged',true, ...
            'alpha1',double(alpha1),'alpha0',double(opt.Alpha0));
        return
    end

    tau = opt.StepSize;
    sigma = opt.StepSize;
    theta = 1;
    u = f;
    wx = zeros(size(f));
    wy = zeros(size(f));
    p1 = zeros(size(f));
    p2 = zeros(size(f));
    q11 = zeros(size(f));
    q22 = zeros(size(f));
    q12 = zeros(size(f));
    ubar = u;
    wxbar = wx;
    wybar = wy;
    relativeChange = Inf;
    converged = false;

    for iteration = 1:opt.MaxIterations
        [ux,uy] = forwardGradient(ubar);
        p1 = p1+sigma*(ux-wxbar);
        p2 = p2+sigma*(uy-wybar);
        pNorm = max(1,hypot(p1,p2)/alpha1);
        p1 = p1./pNorm;
        p2 = p2./pNorm;

        [e11,e22,e12] = symmetricGradient(wxbar,wybar);
        q11 = q11+sigma*e11;
        q22 = q22+sigma*e22;
        q12 = q12+sigma*e12;
        qNorm = max(1,sqrt(q11.^2+q22.^2+2*q12.^2)/opt.Alpha0);
        q11 = q11./qNorm;
        q22 = q22./qNorm;
        q12 = q12./qNorm;

        uOld = u;
        wxOld = wx;
        wyOld = wy;
        u = (u-tau*gradientAdjoint(p1,p2)+tau*f)/(1+tau);
        if opt.Nonnegative
            u = max(u,0);
        end
        [ewx,ewy] = symmetricGradientAdjoint(q11,q22,q12);
        wx = wx+tau*p1-tau*ewx;
        wy = wy+tau*p2-tau*ewy;

        ubar = u+theta*(u-uOld);
        wxbar = wx+theta*(wx-wxOld);
        wybar = wy+theta*(wy-wyOld);

        if mod(iteration,10) == 0 || iteration == opt.MaxIterations
            relativeChange = norm(u(:)-uOld(:))/max(norm(uOld(:)),eps);
            if relativeChange <= opt.Tolerance
                converged = true;
                break
            end
        end
    end

    denoised = cast(u,'like',noisy);
    info = struct('iterations',iteration,'relativeChange',relativeChange, ...
        'converged',converged,'alpha1',double(alpha1), ...
        'alpha0',double(opt.Alpha0),'stepSize',tau);
end

function [dx,dy] = forwardGradient(u)
    dx = zeros(size(u));
    dy = zeros(size(u));
    dx(1:end-1,:) = u(2:end,:)-u(1:end-1,:);
    dy(:,1:end-1) = u(:,2:end)-u(:,1:end-1);
end

function adjoint = gradientAdjoint(px,py)
    adjoint = differenceAdjointX(px)+differenceAdjointY(py);
end

function [e11,e22,e12] = symmetricGradient(wx,wy)
    [wxX,wxY] = forwardGradient(wx);
    [wyX,wyY] = forwardGradient(wy);
    e11 = wxX;
    e22 = wyY;
    e12 = 0.5*(wxY+wyX);
end

function [wxAdjoint,wyAdjoint] = symmetricGradientAdjoint(q11,q22,q12)
    wxAdjoint = differenceAdjointX(q11)+differenceAdjointY(q12);
    wyAdjoint = differenceAdjointY(q22)+differenceAdjointX(q12);
end

function result = differenceAdjointX(p)
    result = zeros(size(p));
    if size(p,1) <= 1
        return
    end
    result(1,:) = -p(1,:);
    if size(p,1) > 2
        result(2:end-1,:) = p(1:end-2,:)-p(2:end-1,:);
    end
    result(end,:) = p(end-1,:);
end

function result = differenceAdjointY(p)
    result = zeros(size(p));
    if size(p,2) <= 1
        return
    end
    result(:,1) = -p(:,1);
    if size(p,2) > 2
        result(:,2:end-1) = p(:,1:end-2)-p(:,2:end-1);
    end
    result(:,end) = p(:,end-1);
end
