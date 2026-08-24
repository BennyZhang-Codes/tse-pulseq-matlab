function run_ci_tests
%RUN_CI_TESTS Execute repository tests and write CI artifacts.

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root,'pulseq')));
addpath(fullfile(root,'utils'), fullfile(root,'prep'), ...
    fullfile(root,'recon','matlab'), fullfile(root,'tests'));

artifactDir = fullfile(root,'artifacts');
if ~exist(artifactDir,'dir')
    mkdir(artifactDir);
end

suite = testsuite(fullfile(root,'tests'), 'IncludeSubfolders', true);
runner = matlab.unittest.TestRunner.withTextOutput;

runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat( ...
    fullfile(artifactDir,'junit.xml')));

coverageFolders = [ ...
    string(fullfile(root,'prep')), ...
    string(fullfile(root,'utils')), ...
    string(fullfile(root,'recon','matlab'))];
coverageFormat = matlab.unittest.plugins.codecoverage.CoberturaFormat( ...
    fullfile(artifactDir,'coverage.xml'));
coveragePlugin = matlab.unittest.plugins.CodeCoveragePlugin.forFolder( ...
    coverageFolders, ...
    'IncludingSubfolders', true, ...
    'Producing', coverageFormat);
runner.addPlugin(coveragePlugin);

results = runner.run(suite);
assertSuccess(results);
end
