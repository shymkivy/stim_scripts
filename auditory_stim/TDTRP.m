function RP = TDTRP(circuitPath, deviceType, varargin)
%TDTRP  TDT RPcoX ActiveX helper.
%   RP = TDTRP(CIRCUITPATH, DEVICETYPE), where CIRCUITPATH and DEVICETYPE 
%   are strings, connect to device and load/run circuit.
%
%   RP   ActiveX object that is connected to this device
%
%   RP = TDTRP(CIRCUITPATH, DEVICETYPE,'parameter',value,...)
%
%   'parameter', value pairs
%      'INTERFACE'  string, 'USB' or 'GB' (default)
%      'NUMBER'     scalar, device number (default 1). Use if you have more
%                   than one device of the same type
%

% defaults
INTERFACE = 'GB';
NUMBER    = 1;

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

deviceType = upper(deviceType);
ALLOWED_DEVICES = {'RP2', 'RA16', 'RL2', 'RV8', 'RM1', 'RM2', ...
    'RX5', 'RX6', 'RX7', 'RX8', 'RZ2', 'RZ5', 'RZ6'};

% check if device is in our list
if ~ismember(deviceType, ALLOWED_DEVICES)
    error([deviceType ' is not a valid device type, valid devices are: ' strjoin(ALLOWED_DEVICES, ', ')]);
end

% check if file exists
if ~(exist(circuitPath,'file'))
    error([circuitPath ' doesn''t exist'])
end

% create ActiveX object
h = figure('Visible', 'off', 'HandleVisibility', 'off');
RP = actxcontrol('RPco.X', 'Parent', h);

% connect to device
eval(['RP.Connect' deviceType '(''' INTERFACE ''', ' num2str(NUMBER) ');']);

% stop any processing chains running on device
RP.Halt; 

% clears all the buffers and circuits on the device
RP.ClearCOF;

% load circuit
disp(['Loading ' circuitPath]);
RP.LoadCOF(circuitPath);

% start circuit
RP.Run; 

% check the status for errors
status=double(RP.GetStatus);
if bitget(status,1)==0;
    error(['Error connecting to ' deviceType]); 
elseif bitget(status,2)==0;
    error('Error loading circuit'); 
elseif bitget(status,3)==0
    error('Error running circuit'); 
else
    disp('Circuit loaded and running');
end
    
end
