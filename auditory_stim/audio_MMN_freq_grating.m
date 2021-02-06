%% audio MMN Freq Grating script
%
%   last update: 1/22/20
%
%%
clear;
%% parameters
% ------ Stim params ------
ops.stim_time = 0.5;                                         % sec
ops.isi_time = 0.5;
% ------ Paradigm sequence ------
ops.paradigm_sequence = {'Control', 'MMN', 'flip_MMN'};     % 3 options {'Control', 'MMN', 'flip_MMN'}, concatenate as many as you want
ops.paradigm_trial_num = [400, 600, 600];                   % how many trials for each paradigm
ops.paradigm_MMN_pattern = [0,3,3];                       % which patterns for MMN/flip (controls are ignored)
                                                            % 1= horz/vert; 2= 45deg;
% ------ MMN params ------
ops.initial_red_num = 20;                                   % how many redundants to start with
ops.inter_paradigm_pause_time = 60;                         % how long to pause between paragigms
ops.MMN_probab=[0.1*ones(1,20) .2 .25 .5 1]; 

% probability of deviants   % MMN_probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];   % jordan's probab
% ------ Other ------
ops.synch_pulse = 1;      % 1 Do you want to use led pulse for synchrinization

% ------ visual stim params ------
ops.squarewave=1;                                           % do squarewaves instead of sinewaves
ops.driftingGrating = 1;                                    % use if you want to make it drifting grating
ops.isicolor=170;   % appx middle                                      % Shade of gray on screen during isi (1 if black, 255/2 if gray)
ops.ctrsts=[.015625 .03125 .0625 .125 .25 .5 .85];          % Range of contrasts to use
ops.ctrst = 7;                                                  % pick 
ops.spfrqs=[.01  .02 .04 .08 .16 .32];                      % Range of spatial freqs to use
ops.spfrq = 4;                                                  % pick 
ops.angs_rad = pi*(0:7)/8;                                  % Orientations to use, in rad
%ops.MMN_patterns = [1, 5; 3, 7; 2, 6; 4, 8];                % MMN orthogonal pairs (indexing through angs_rad)
%grating_angles = [3, 2, 1, 0, -1, -2]*pi/6;

% ----- auditory gratings stim params ------------
ops.start_freq = 2000;
ops.end_freq = 90000;
ops.resoluction_per_octave = 1/24/8;
ops.grating_angles = [5, 4, 3, 2, 1, 0, -1, -2, -3, -4]*pi/10;
ops.MMN_patterns = [1,6; 2,7; 3,8];
ops.stim_amplitude = 8; % 8 is good, seems similar to 4 with sam tones

%play_and_record = 0;

%widefield_LED = 0;


%% predicted run time
run_time = (ops.stim_time+ops.isi_time+0.025)*(sum(ops.paradigm_trial_num)) + (numel(ops.paradigm_trial_num)-1)*ops.inter_paradigm_pause_time + 20 + 120;
fprintf('Expected run duration: %.1fmin (%.fsec)\n',run_time/60,run_time);

% mag = sqrt(angsy.^2 + angsx.^2);
%%
pwd2 = fileparts(which('audio_MMN_freq_grating.m')); %mfilename
addpath([pwd2 '\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\auditory\'];
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'Continuous_Play_YS.rcx';

temp_time = clock;
file_name = sprintf('aMMN_freq_grating_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;
%% compute stim types sequence
stim_ctx_stdcount = cell(numel(ops.paradigm_sequence),1);
stim_ang = cell(numel(ops.paradigm_sequence),1);
for parad_num = 1:numel(ops.paradigm_sequence)
    if strcmpi(ops.paradigm_sequence{parad_num}, 'control')
        samp_seq = randperm(ops.paradigm_trial_num(parad_num));
        samp_pool = repmat(1:numel(ops.angs_rad),1,ceil(ops.paradigm_trial_num(parad_num)/numel(ops.angs_rad)));    
        stim_ang{parad_num} = samp_pool(samp_seq)';
    else
        stdcounts = 0;
        stim_ang{parad_num} = zeros(ops.paradigm_trial_num(parad_num),1);
        stim_ctx_stdcount{parad_num} = zeros(ops.paradigm_trial_num(parad_num),2);
        if strcmpi(ops.paradigm_sequence{parad_num}, 'mmn')
            curr_MMN_pattern = ops.MMN_patterns(ops.paradigm_MMN_pattern(parad_num),:);
        elseif strcmpi(ops.paradigm_sequence{parad_num}, 'flip_mmn')
            curr_MMN_pattern = fliplr(ops.MMN_patterns(ops.paradigm_MMN_pattern(parad_num),:));
        end
        for trl=1:ops.paradigm_trial_num(parad_num)
            if trl <= ops.initial_red_num
                ctxt = 1;
                stdcounts = stdcounts + 1;
            else
                curr_prob = ops.MMN_probab(rem(stdcounts,numel(ops.MMN_probab))+1);
                ctxt = (rand(1) < curr_prob) + 1;  % 1=red, 2=dev
                if ctxt==1
                    stdcounts=1+stdcounts;
                else
                    stdcounts=0;
                end
            end
            stim_ctx_stdcount{parad_num}(trl,:) = [ctxt, stdcounts];
            stim_ang{parad_num}(trl) = curr_MMN_pattern(ctxt);
        end
    end
end

%% initialize RZ6
[RP, fs] = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
ops.sig_dt = 1/fs; %1/195312.5; % 100kHz sampling signal

%% design stim
disp('Generating gratings...');
grating_stim = f_generate_freq_grating(ops);

% adjust amplitude
grating_stim_norm = zeros(size(grating_stim));
for ii = 1:size(grating_stim,1)
%     grating_stim_norm(ii,:) = grating_stim(ii,:)./max(abs(grating_stim(ii,:)))*stim_amplitude;
    %grating_stim_norm(ii,:) = grating_stim(ii,:)*10/(5*std(grating_stim(ii,:)));
    grating_stim_norm(ii,:) = grating_stim(ii,:)*ops.stim_amplitude/(5*std(grating_stim(ii,:)));
end

%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,0]);

%% Run trials
start_paradigm=now*86400;%GetSecs();

synch_pulse_onoff = zeros(numel(ops.paradigm_sequence)+2,2);

synch_pulse_onoff(1,:) = IF_pause_synch(10, session, ops.synch_pulse);
stim_times = cell(numel(ops.paradigm_sequence),1);
h = waitbar(0, 'initializeing...');
for parad_num = 1:numel(ops.paradigm_sequence)
    fprintf('Paradigm %d: %s, %d trials:\n',parad_num, ops.paradigm_sequence{parad_num}, ops.paradigm_trial_num(parad_num));
    
    % check what paradigm
    if strcmpi(ops.paradigm_sequence{parad_num}, 'control')
        cont_parad = 1;
    else
        cont_parad = 0;
    end
    stim_times{parad_num} = zeros(ops.paradigm_trial_num(parad_num),1);
    
    % run trials
    for trl=1:ops.paradigm_trial_num(parad_num)
        start_trial1 = now*86400;%GetSecs();
   
        ang = stim_ang{parad_num}(trl);
        if cont_parad
            vis_volt = ang/numel(ops.grating_angles)*4;
        else
            vis_volt = stim_ctx_stdcount{parad_num}(trl,1);
        end
        
        waitbar(trl/ops.paradigm_trial_num(parad_num), h, sprintf('Paradigm %d of %d: Trial %d, angle %d',parad_num, numel(ops.paradigm_sequence), trl, ang));
        % pause for isi
        pause(ops.isi_time+rand(1)/20)

        % play
        start_stim = now*86400;%GetSecs();
        session.outputSingleScan([vis_volt,0]);
        session.outputSingleScan([vis_volt,0]);
        f_RZ6_CP_play(RP, grating_stim_norm(ang,:));
        session.outputSingleScan([0,0]);
        session.outputSingleScan([0,0]);
        
        % record
        stim_times{parad_num}(trl) = start_stim-start_paradigm;
        %fprintf('; Angle %d\n', ang);
    end
    
    if parad_num < numel(ops.paradigm_sequence)
        synch_pulse_onoff(parad_num+1,:) = IF_pause_synch(ops.inter_paradigm_pause_time, session, ops.synch_pulse);
    end
    
end
close(h);

%%
synch_pulse_onoff(numel(ops.paradigm_sequence)+2,:) = IF_pause_synch(10, session, ops.synch_pulse);

synch_pulse_onoff = synch_pulse_onoff - start_paradigm;

%% close all
session.outputSingleScan([0,0]);
RP.Halt;

%% play sound

% sig2 = grating_stim_norm(3,:);
% sig2 = grating_stim_norm(3,:)'+rand(numel(grating_stim_norm(3,:)),1);
% 
% rms(grating_stim_norm(2,:))
% 
% sound(sig2, 1/sig_dt);

%% plot stuff 

%figure; cwt(sig2, 1/sig_dt);

% 
% rms(grating_stim(2,:))
% 
% figure; dwt(rand_sig,  'db4');
% [wt,f] = cwt(rand_sig, 1/sig_dt);
% 
% [wt,f] = cwt(grating_stim(2,:), 1/sig_dt);
% xrec = icwt(wt);
% 
% figure; cwt(xrec, 1/sig_dt);
% figure; imagesc(abs(wt))
% 
% 
% figure; plot(sig2);
% figure; pwelch(sig2,[],[],[],1/sig_dt);
% figure; spectrogram(grating_stim(2,:), 1000, 100, 1000, 1/sig_dt, 'yaxis'); ax = gca; ax.YScale = 'log'; ylim([2, 90]); ax.YTick = [2.5, 5, 10, 20, 40, 80];

% figure; plot(rand_sig);
% figure; pwelch(rand_sig,[],[],[],1/sig_dt);
% 
% figure; plot(sig_chirp);
% figure; pwelch(sig_chirp,[],[],[],1/sig_dt);
% figure; spectrogram(sig_chirp, 1000, 100, 1000, 1/sig_dt, 'yaxis'); ax = gca; ax.YScale = 'log'; ylim([2, 90]); ax.YTick = [2.5, 5, 10, 20, 40, 80];
% figure; pspectrum(sig_chirp,1/sig_dt,'spectrogram','TimeResolution',0.1, 'OverlapPercent',99,'Leakage',0.85)
% 
% 

%% save info
fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'ops', 'stim_times', 'stim_ang', 'stim_ctx_stdcount', 'synch_pulse_onoff');
fprintf('Done\n');

%% functions

function pulse_onoff = IF_pause_synch(pause_time, session, synch)
    
    LED_on = 3; %foltage. if diameter of light circle is 1mm, then use 1.5.
    %if .8mm, use 1.23. these give about 4mw/mm2. 1=1.59mw. 1.23=2.00mw 1.5=2.35mw. 2=3.17. 2.5=3.93. 3=4.67. 3.5=5.36 4=6.05
    
    pulse_onoff = zeros(1,2);
    % synch artifact
    if synch
        pause((pause_time - 1)/2);
        pulse_onoff(1) = now*86400;
        session.outputSingleScan([0,LED_on]);
        pause(1);
        pulse_onoff(2) = now*86400;
        session.outputSingleScan([0,0]);
        pause((pause_time - 1)/2);
    else
        pause(pause_time);
    end

end
