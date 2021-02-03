% controls the minimal arduino script

% params

paradigm_duration = 1800;  %  sec


%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogInputChannel('Dev1','ai0','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,0]);


%% run paradigm

start_paragm = now*1e5;

while (start_paragm - now*1e5)<paradigm_duration
    
    lick = 0;
    % wait for lick
    while ~lick
        data_in = inputSingleScan(session);
    end
    
    
    
end