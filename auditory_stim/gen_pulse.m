close all
clear;

%%
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.addAnalogOutputChannel('Dev1','ao3','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
volt_cmd = [0 0 0];
session.outputSingleScan(volt_cmd);



%%
for n_tr = 1:10
    session.outputSingleScan([0 0 5]);
    pause(0.001);
    session.outputSingleScan([0 0 0]);
    pause(5);
end

%%