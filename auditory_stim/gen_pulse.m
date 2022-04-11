close all
clear;

%%
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.addAnalogOutputChannel('Dev1','ao2','Voltage'); % Prairie trig in (>2V)
session.addAnalogOutputChannel('Dev1','ao3','Voltage'); % SLM indicator
%session.Rate = 10000;
volt_cmd = [0 0 0 0];
session.outputSingleScan(volt_cmd);



%%
num_stim = 50;
stim_types = randsample(3, num_stim, true);

for n_tr = 1:num_stim
    session.outputSingleScan([0 0 5 stim_types(n_tr)]);
    pause(0.001);
    session.outputSingleScan([0 0 0 stim_types(n_tr)]);
    pause(1);
    session.outputSingleScan([0 0 0 0]);
    pause(4);
end

%%