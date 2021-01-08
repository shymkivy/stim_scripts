s1 = daq.createSession('ni');
addAnalogOutputChannel(s1,'Dev1','ao1','Voltage');

outputSingleScan(s1, 0);
pause(1)
outputSingleScan(s1, 1);
pause(1)
outputSingleScan(s1, 0);

