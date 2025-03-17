using HighOrderMRI, MRIReco
import HighOrderMRI.MRIBase: AcquisitionData, contrasts, slices, repetitions, trajectory, subsampleIndices, rawdata
import HighOrderMRI.MRIBase: uniqueidx, encSteps1, encSteps2
using MAT
T          = Float32

path       = "E:/TSE_pulseq/data/20250316"

mrds = [
    # "meas_MID00039_FID64760_pulseq_TSE_0p4_300_sli9_tr5000_te14_t10_bw159",
    # "meas_MID00040_FID64761_pulseq_TSE_0p3_400_sli9_tr5000_te14_t10_bw156",
    # "meas_MID00038_FID64759_pulseq_TSE_1p0_120_sli9_tr5000_te14_t10_bw159_Sequential",
    # "meas_MID00037_FID64758_pulseq_TSE_1p0_120_sli9_tr5000_te14_t10_bw159",
    # "meas_MID00035_FID64756_pulseq_TSE_1p0_120_sli1_tr5000_te14_t10_bw159",
    "meas_MID00051_FID64772_pulseq_TSE_1p0_120_sli9_tr5000_te14_t10_bw159_SLC",
    "meas_MID00052_FID64773_pulseq_TSE_1p0_120_sli9_tr5000_te14_t10_bw159_Sequential_SLC"
    ]



for idx = 1:length(mrds)

    mrd = mrds[idx]
    raw_file   = "$(path)/mrd/$(mrd).mrd"

    raw   = RawAcquisitionData(ISMRMRDFile(raw_file)) # get signal data
    shape = get_ksize(raw);
    nCha, nZ, nY, nX, nAvg, nSli, nCon, nPha, nRep, nSet, nSeg = shape; println(shape)
    kdata = get_kdata(raw, shape);
    kdata = dropdims(kdata, dims = tuple(findall(size(kdata) .== 1)...));
    kdims = [mrddims[idx] for idx in 1:length(shape) if shape[idx]>1];
    @info size(kdata), kdims

    kdata = sum(kdata, dims=5)[:,:,:,:,1];
    imgs = convert_ifft(kdata, dims=[2,3]);
    imgs = CoilCombineSOS(abs.(imgs), 1);

    # sliceorder = [1,3,5,7,9,11,13,15,17,19,21,23,25,2,4,6,8,10,12,14,16,18,20,22,24];
    # sliceorder = Int64.(matread(traj_mat)["acqP"]["SliceLabel"][1,:]) .+ 1
    # img[sliceorder,:,:] = img;
    # plt_image(abs.(kdata[1,:,:,1]).^0.02)
    
    imgs_rotated = similar(imgs);

    for isli in 1:nSli
        imgs_rotated[:, :, isli] = rotr90(imgs[:, :, isli]);
    end

    fig  = plt_images(imgs_rotated; dim=3, width=5, height=5, vminp=0, vmaxp=99)

    fig.savefig("$(path)/out/$(mrd).png", dpi=300, bbox_inches="tight", pad_inches=0);
end
