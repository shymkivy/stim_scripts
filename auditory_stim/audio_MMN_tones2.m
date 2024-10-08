%% audio MMN tones script
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
ops.paradigm_MMN_pattern = [0,1, 1];                       % which patterns for MMN/flip (controls are ignored)
                                                            % 1= horz/vert; 2= 45deg;
% ------ MMN params ------
ops.initial_red_num = 20;                                   % how many redundants to start with
ops.inter_paradigm_pause_time = 60;                         % how long to pause between paragigms
ops.MMN_probab=[0.1*ones(1,20) .2 .25 .5 1]; 

% probability of deviants   % MMN_probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];   % jordan's probab
% ------ Other ------
ops.synch_pulse = 1;      % 1 Do you want to use led pulse for synchrinization

% ----- auditory stim params ------------
ops.start_freq = 2000;
ops.end_freq = 90000;

% ----- auditory tones stim params -------------
ops.num_freqs = 10;
ops.increase_factor = 1.5;
ops.MMN_patterns = [3,6; 4,7; 3,8]; 
ops.base_freq = 0.001; % baseline frequency
ops.modulation_amp = 4; % maybe use 2

%% predicted run time
run_time = (ops.stim_time+ops.isi_time+0.025)*(sum(ops.paradigm_trial_num)) + (numel(ops.paradigm_trial_num)-1)*ops.inter_paradigm_pause_time + 20 + 120;
fprintf('Expected run duration: %.1fmin (%.fsec)\n',run_time/60,run_time);

% mag = sqrt(angsy.^2 + angsx.^2);
%%
pwd2 = fileparts(which('audio_MMN_tones2.m')); %mfilename
addpath([pwd2 '\functions']);
addpath([pwd2 '\..\behavior\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\auditory\'];
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'sine_mod_play_YS.rcx';

temp_time = clock;
file_name = sprintf('ammn_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;
%% compute stim types sequence
stim_ctx_stdcount = cell(numel(ops.paradigm_sequence),1);
stim_ang = cell(numel(ops.paradigm_sequence),1);
for n_pr = 1:numel(ops.paradigm_sequence)
    if strcmpi(ops.paradigm_sequence{n_pr}, 'control')
        samp_seq = randperm(ops.paradigm_trial_num(n_pr));
        samp_pool = repmat(1:ops.num_freqs,1,ceil(ops.paradigm_trial_num(n_pr)/ops.num_freqs));    
        stim_ang{n_pr} = samp_pool(samp_seq)';
    else
        stdcounts = 0;
        stim_ang{n_pr} = zeros(ops.paradigm_trial_num(n_pr),1);
        stim_ctx_stdcount{n_pr} = zeros(ops.paradigm_trial_num(n_pr),2);
        if strcmpi(ops.paradigm_sequence{n_pr}, 'mmn')
            curr_MMN_pattern = ops.MMN_patterns(ops.paradigm_MMN_pattern(n_pr),:);
        elseif strcmpi(ops.paradigm_sequence{n_pr}, 'flip_mmn')
            curr_MMN_pattern = fliplr(ops.MMN_patterns(ops.paradigm_MMN_pattern(n_pr),:));
        end
        for trl=1:ops.paradigm_trial_num(n_pr)
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
            stim_ctx_stdcount{n_pr}(trl,:) = [ctxt, stdcounts];
            stim_ang{n_pr}(trl) = curr_MMN_pattern(ctxt);
        end
    end
end

%% initialize RZ6
RP = f_RZ6_CP_initialize([circuit_path circuit_file_name]);
RP.Halt;

%% design stim
% generate control frequencies
control_carrier_freq = zeros(1, ops.num_freqs);
control_carrier_freq(1) = ops.start_freq;
for ii = 2:ops.num_freqs
    control_carrier_freq(ii) = control_carrier_freq(ii-1) * ops.increase_factor;
end

%% initialize DAQ
ops.old_daq = 1;
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
volt_cmd = [0 0];
ops.volt_cmd = [0 0];
ops.old_daq = 1;

%% Run trials
RP.Run;
RP.SetTagVal('ModulationAmp', ops.modulation_amp);

start_paradigm=now*86400;%GetSecs();

f_pause_synch(10, session, ops.synch_pulse, ops);
stim_times = cell(numel(ops.paradigm_sequence),1);
h = waitbar(0, 'initializeing...');
for n_pr = 1:numel(ops.paradigm_sequence)
    fprintf('Paradigm %d: %s, %d trials:\n',n_pr, ops.paradigm_sequence{n_pr}, ops.paradigm_trial_num(n_pr));
    
    % check what paradigm
    if strcmpi(ops.paradigm_sequence{n_pr}, 'control')
        cont_parad = 1;
    else
        cont_parad = 0;
    end
    stim_times{n_pr} = zeros(ops.paradigm_trial_num(n_pr),1);
    
    % run trials
    for trl=1:ops.paradigm_trial_num(n_pr)
        start_trial1 = now*86400;%GetSecs();
   
        ang = stim_ang{n_pr}(trl);
        if cont_parad
            vis_volt = ang/ops.num_freqs*4;
        else
            vis_volt = stim_ctx_stdcount{n_pr}(trl,1);
        end
        
        waitbar(trl/ops.paradigm_trial_num(n_pr), h, sprintf('Paradigm %d of %d: Trial %d, angle %d',n_pr, numel(ops.paradigm_sequence), trl, ang));
        % pause for isi
        pause(ops.isi_time+rand(1)/20)

        % play
        start_stim = now*86400;%GetSecs();
        RP.SetTagVal('CarrierFreq', control_carrier_freq(ang));
        ops.volt_cmd(1) = vis_volt;
        session.outputSingleScan(ops.volt_cmd);
        session.outputSingleScan(ops.volt_cmd);
        pause(ops.stim_time);
        RP.SetTagVal('CarrierFreq', ops.base_freq);
        ops.volt_cmd(1) = 0;
        session.outputSingleScan(ops.volt_cmd);
        session.outputSingleScan(ops.volt_cmd);
        
        
        % record
        stim_times{n_pr}(trl) = start_stim-start_paradigm;
        %fprintf('; Angle %d\n', ang);
    end
    
    if n_pr < numel(ops.paradigm_sequence)
        f_pause_synch(ops.inter_paradigm_pause_time, session, ops.synch_pulse, ops);
    end
    
end
close(h);

%%
f_pause_synch(10, session, ops.synch_pulse, ops)

%% close all
ops.volt_cmd(1:end) = 0;
session.outputSingleScan(ops.volt_cmd);
RP.Halt;

%% save info
fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'ops', 'stim_times', 'stim_ang', 'stim_ctx_stdcount');
fprintf('Done\n');
