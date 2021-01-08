% One-channel continuous acquire example using a serial buffer
% This program writes to the buffer once it has cyled halfway through
% (double-buffering)

%close all;
clear;

%saved file name
fileName = 'test.F32';

circuit_file_name = 'Continuous_Acquire.rcx';

% connect to RZ6
RP=actxcontrol('RPco.x',[5 5 26 26]);
RP.ConnectRZ6('GB',1);
RP.Halt;
RP.ClearCOF; % Clears all the buffers and circuits

% filePath - set this to wherever the examples are stored
filePath = 'C:\Users\rylab_901c\Desktop\Yuriy_scripts\auditory_stim\saved_sounds\';
RP.LoadCOF(strcat('C:\Users\rylab_901c\Desktop\Yuriy_scripts\RPvdsEx_circuits\',circuit_file_name)); % Loads circuit

% run check
RP.Run;
if all(bitget(RP.GetStatus,1:3))
    disp('Circuit loaded and running');
else
    disp('Error loading/running circuit');
end



% size of the entire serial buffer
npts = RP.GetTagSize('dataout');  

% serial buffer will be divided into two buffers A & B
fs = RP.GetSFreq();
bufpts = npts/2; 
t=(1:bufpts)/fs;

filePath = strcat(filePath, fileName);
fnoise = fopen(filePath,'w');
    
% begin acquiring
RP.SoftTrg(1);
curindex = RP.GetTagVal('dataout');
disp(['Current buffer index 45: ' num2str(curindex)]);

% main looping section
for i = 1:10  
    
    % wait until done playing and writing A
    while(curindex < bufpts)
        curindex = RP.GetTagVal('dataout');
        %pause(.05);
    end

    % read segment A
    noise = RP.ReadTagVEX('dataout', 0, bufpts, 'F32', 'F32', 1);
    fwrite(fnoise,noise,'float32');
    
    
    % checks to see if the data transfer rate is fast enough

    if(curindex < bufpts)
        warning('Transfer rate is too slow');
    end

    % wait until start writing A 
    while(curindex > bufpts)
        curindex = RP.GetTagVal('dataout');
        pause(.05);
    end
    
    % read segment B
    noise = RP.ReadTagVEX('dataout', bufpts, bufpts, 'F32', 'F32', 1);
    fwrite(fnoise,noise,'float32');

    % make sure we're still playing A 
    if(curindex > bufpts)
        warning('Transfer rate too slow');
    end

end

fclose(fnoise);

% stop acquiring
RP.SoftTrg(2);
RP.Halt;


% fileName = 'MaiTaiPS_OFF.F32';
% % plots the last npts data points
% fs = 2e-5;
% 
% fid = fopen(fileName);
% 
% data = fread(fid, 'float32');
% data = freq_grating_stim;
% fclose(fid);
% 
% Vrms = sqrt(mean(data.^2));
% SPL = 20*log10(Vrms/(2.2*10e-3*20*10e-6));
% fprintf('SPL is %.1f\n', SPL);
% 
% 
% figure;
% plot(data);   %plot([1:length(data)]/fs*1000,data);
% title('Speaker_rec')
% xlabel('Time, ms')
% % figure;
% % pwelch(data,2000, 50, 2000, fs, 'power');
% figure;
% pwelch(data,20000, 200, 20000, fs, 'power');
% title(sprintf('%s, SPL %.1f', fileName, SPL));
% % figure;
% % spectrogram(data, 200, 50, 200, 200000, 'yaxis');
% % 
% % [pxx,f] = pwelch(data, 2000, 50, 200, fs, 'power');
% % %[pxx,f] = pwelch(data, fs, 'power');
% % figure;
% % plot(f, 20*log10(sqrt(pxx)/(2.2*10e-3*20*10e-6)));
% % ylabel('dB');
% % 
% % figure;
% % plot(10*log10(fftshift(abs(fft(data)))));x1
% x1= round(2.715e6);
% x2= round(2.896e6);
% 
% figure;
% plot(data(1,x1:x2));
% 
% data2 = data(1,x1:x2);
% 
% Vrms = sqrt(mean(data2.^2));
% SPL = 20*log10(Vrms/(2.2*10e-3*20*10e-6));
% fprintf('SPL is %.1f\n', SPL);


