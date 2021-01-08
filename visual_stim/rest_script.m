session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');

% session.addDigitalChannel('Dev1','Port0/Line0','OutputOnly');

% session.outputSingleScan([0,0,0]);
% session.outputSingleScan([0,0,1]);
% pause(0.1);
% session.outputSingleScan([0,0,0]);



session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,0]);

session.outputSingleScan([0,5]);
pause(0.1);
session.outputSingleScan([0,0]);


pause(5);
session.outputSingleScan([0,3]);
pause(1);
session.outputSingleScan([0,0]);
pause(5);

pause(1500)

pause(5);
session.outputSingleScan([0,3]);
pause(1);
session.outputSingleScan([0,0]);
pause(5);