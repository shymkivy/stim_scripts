function [RP, fs] = f_RZ6_CP_initialize(circuit_file_name)

%% Initialize Amplifier 

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% filePath - set this to wherever the examples are stored

RP.LoadCOF(strcat('C:\Users\rylab_901c\Desktop\Yuriy_scripts\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3))
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end

% get device sampling frequency
fs = RP.GetSFreq();


end