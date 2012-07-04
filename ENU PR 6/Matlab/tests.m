

% SAF Test

load SimpleSample.mat

DataSamples = A;
ClkSamples  = B;
SFSamples(1) = [];
SFSamples(2) = [];

values = SAF(DataSamples,ClkSamples,SFSamples)