%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Train and task script for deviance detection
%
%       Communication logic with arduino:
%           First serial COM (USB) connection is initiated with arduino.
%           At the start of experiment and before every trial matlab will
%           send message to arduino and wait for a signal that arduino is
%           ready. Matlab will also send information about which type of
%           trial is currently running. All trial dependent delays are
%           encoded on the arduino side.
%
%       To run experiment:
%           Upload arduino script to arduino
%           Run Voltage_recording_NI_DAQ script
%           Run this script
%
%       Requires:
%           talk_to_arduino.m
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all;

%% Main parameters

params.DOopto=0; %1=yes; 0=no opto stimulus

params.displayTime = 0.5;
params.pauseTime = 0.5;
params.trials = 650;    %650    % trials per pattern

patterns_to_run = [1 2 3 4]; % choose from angsy_patterns below, order is shuffled

inter_paradigm_pause_time = 20; %30% pause time between runs

%% output file name generation
acquisition_file_name = 'vMMN_params';

save_path = '.\vmmn_stim_output_data\';
% add time info to saved file name
temp_time = clock;
time_stamp = ['_', num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_', num2str(temp_time(4)), '_', num2str(temp_time(5))];
acquisition_file_path = [save_path, acquisition_file_name,time_stamp];
clear save_path temp_time time_stamp acquisition_file_name;


%% secondary parameters

params.Ooff=0; %volts
params.Oon=3; %foltage. if diameter of light circle is 1mm, then use 1.5.
%if .8mm, use 1.23. these give about 4mw/mm2. 1=1.59mw. 1.23=2.00mw 1.5=2.35mw. 2=3.17. 2.5=3.93. 3=4.67. 3.5=5.36 4=6.05

params.dev_probability = 1/10;
params.initial_red_num = 10;

%probab=[.01 .01 .02 .01 .01 .01 .1 .1 .3 .5 1];

% stim parameters
params.isicolor = 255/2; %1 if black, 255/2 if gray
params.ctrsts = [.015625 .03125 .0625 .125 .25 .5 .85];
params.spfrq = [.01  .02 .04 .08 .16 .32];

% first is redundant second is deviant, in radians
vmmn_angle_patterns = [0 1/2; 1/2 0; 1/4 3/4;  3/4 1/4; 1/6 4/6; 4/6 1/6]*pi;
% shuffle the experiment patterns
patterns_to_run = randsample(patterns_to_run,length(patterns_to_run)); 

% angsy= [.5 -.5];%[0 1];%[.5 -.5];%[.5 -.5];%[-.866 .5];%[1 0];%
% angsx= [.5 .5];%[1 0];%[.5 .5];%[.5 -.866];%[.5 .866];[0 1];%


%% Start OpenGL Psychtoolbox

Screen('Preference', 'SkipSyncTests', 0);
AssertOpenGL; % Make sure this is running on OpenGL Psychtoolbox:
params.screenid = max(Screen('Screens')); % Choose screen with maximum id - the secondary display on a dual-display setup for display
[params.win, params.rect] = Screen('OpenWindow',params.screenid, [255/2 255/2 255/2]); % rect is the coordinates of the screen
params.ifi = Screen('GetFlipInterval', params.win);


%% Set up NI DAQ

session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0, 0]);


%% Connecting to Arduino

% serial messages from arduino
params.arduino.serial_arduino_ready = '6';

% messages from matlab to arduino
params.arduino.serial_start_stop_exp = '5';
params.arduino.serial_trial = ['1', '2'];

% connect
disp('Setting up connection with Arduino for lick detection...');
params.arduino.com_port=serial('COM15','BaudRate',9600); % create serial communication object on arduino port

fopen(params.arduino.com_port); % initiate arduino communication
pause(3); % allow for connection to establish

params.arduino.message_back = talk_to_arduino(params.arduino.com_port, params.arduino.serial_start_stop_exp);
if params.arduino.message_back ~= params.arduino.serial_arduino_ready
    error('Could not connect to Arduino');   
end
disp('Connected...')


%% play stim
pause(5);
session.outputSingleScan([0,3]);
pause(1);
session.outputSingleScan([0,0]);
pause(5);


for exp = 1:length(patterns_to_run)
    fprintf('Experiment %d:\n', exp);
    angsy = sin(vmmn_angle_patterns(patterns_to_run(exp),:));
    angsx = cos(vmmn_angle_patterns(patterns_to_run(exp),:));
    

    vmmn_present(angsx, angsy, params, session);
    
    pause(inter_paradigm_pause_time);

end
clear exp;

pause(5);
session.outputSingleScan([0,3]);
pause(1);
session.outputSingleScan([0,0]);
pause(5);


%% psych toolbox quit
sca();

%% NI DAQ zero out
session.outputSingleScan([0,0]);

%% close arduino session
params.arduino.message_back = talk_to_arduino(params.arduino.com_port, params.arduino.serial_start_stop_exp);
if params.arduino.message_back ~= params.arduino.serial_arduino_ready
    error('Could not connect to Arduino');
end
fclose(params.arduino.com_port);


%% save stuff
save([acquisition_file_path '.mat'], 'patterns_to_run', 'vmmn_angle_patterns', 'params');