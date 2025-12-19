session=daq('ni');
%session.addinput(ops.daq_dev,'ai0','Voltage'); % record licks from sensor
%session.Channels(1).Range = [-10 10];
%session.Channels(1).TerminalConfig = 'SingleEnded';
%session.addoutput(ops.daq_dev,'ao0','Voltage'); % Stim type
%session.addoutput(ops.daq_dev,'ao1','Voltage'); % LED
session.addoutput('Dev2','Port0/Line0','Digital'); % LEDbh
session.addoutput('Dev2','Port0/Line1','Digital'); % Reward

f_write_daq_out(session, [0,0], 0);% [stim_type, LED, LED_behavior, solenoid] [AO AO DO DO]

% start with some water
f_write_daq_out(session, [1,1], 0); % write(arduino_port, 3, 'uint8');
pause(1);
f_write_daq_out(session, [0,0], 0);