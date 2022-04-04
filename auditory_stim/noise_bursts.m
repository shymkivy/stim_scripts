clear;
close all;

pwd2 = fileparts(which('audio_ACmapping.m')); %mfilename
addpath([pwd2 '\functions']);
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'Band_Limited_Noise_VH.rcx';



RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);

RP.Halt;

RP.SetTagVal('Amp2',0);

RP.Run;


for n_tr = 1:10
    
    RP.SetTagVal('Amp2',10);
    pause(1);
    RP.SetTagVal('Amp2',0);
    pause(1);
    
end


RP.Halt;



