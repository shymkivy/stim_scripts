% This circuit and program generates band-limited noise using a ParaCoef
% The user can set the center frequency, bandwidth, and gain of the filter
% and the amplitude of the noise. 
% It checks for clipping (> +/-10 volts).


circuit_file_name = 'Band_Limited_Noise_YS.rcx';

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% loadCOF clears device memory buffers, while readCOF doesn't
RP.LoadCOF(strcat('C:\Users\YusteLab\Desktop\Yuriy\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3));
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end
RP.Halt;






% 
% RP.SetTagVal('ModulationAmp', modulation_amp);
% 
% RP.SetTagVal('CarrierFreq', control_carrier_freq(1));
% 
% RP.SetTagVal('CarrierFreq', base_freq);
% 
% % new stuff
% 
% Data_A = RP.ReadTagV('datain',0,1000);
% 
% RP.Halt;

RP.Run;

Freq=5000;
Gain=1;
Bandwidth=200;
Amp=2;

% Sets the initial settings for the filter coefficients and the noise
RP.SetTagVal('Gain',Gain); % Gain of band limited filter
RP.SetTagVal('Freq',Freq); % CenterFrequency
RP.SetTagVal('BW',Bandwidth); % Bandwidth of filter
RP.SetTagVal('Amp',Amp); % Amplitude of the Gaussian Noise
RP.SetTagVal('Enable',1); % Loads Coefficients to Biquad Filter
RP.SetTagVal('Enable',0); % Stops Coefficient generator from sending signal (saves on cycle usage)

quit=0;
while quit==0
    Clip=RP.GetTagVal('Clip'); % Checks to see if signal is clipped (top light on panel is on while clipping occurs)
    if Clip==1
        disp('Gain of filter or noise intensity is too high');
        a=input('Type 1 to change filter Gain, 2 for Amp, 3 for Both:' ); % Queries user for what they want changed
    if a==1
        Gain=input('Enter Gain value:' );
        RP.SetTagVal('Gain',Gain); % Alters coefficient Gain
    elseif a==2
        Amp=input('En0er Amplitude value:' );
        RP.SetTagVal('Amp',Amp); % Alters noise amplitude
    elseif a==3
        Amp=input('Enter Amplitude value:' ); % Alters both
        RP.SetTagVal('Amp',Amp);
            Gain=input('Enter Gain value:' );
        RP.SetTagVal('Gain',Gain);
    else
        disp('Error: Invalid response');
    end
    RP.SetTagVal('Enable',1); % Starts the coefficient generator
    RP.SetTagVal('Enable',0); % Stops ParCoef generation
end
quit=input('Continue testing? 0 for yes 1 for No: ');
end

RP.Halt;