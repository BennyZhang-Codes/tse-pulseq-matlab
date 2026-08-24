function run_ci_tests
%RUN_CI_TESTS Execute the repository MATLAB tests and write a JUnit report.

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
results = runner.run(suite);
assertSuccess(results);
end