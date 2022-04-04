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
ops.paradigm_trial_num = [800, 1200, 1200];                   % how many trials for each paradigm
ops.paradigm_MMN_pattern = [0,1, 1];                       % which patterns for MMN/flip (controls are ignored)
                                                            % 1= horz/vert; 2= 45deg;
% ------ MMN params ------
ops.initial_red_num = 20;                                   % how many redundants to start with
ops.inter_paradigm_pause_time = 60;                         % how long to pause between paragigms
ops.MMN_probab=[0.1*ones(1,20) .2 .25 .5 1]; 

% ----- stim params ----------
% {paradigm num, 'type', angle/range, volt out}
% type options: 'dev', 'cont'
% angle for cont will tag that freq
% range red: ex [-5 -2] will tag one of red in that relative range

ops.stim_trials_volt = {1, 'cont', 3, 1};%...
                        %1, 'cont', 3, 1;...3, 'dev', [], 1
                        %2, 'dev', [], 2};   
ops.stim_delay = .01; % in sec
ops.stim_trig_duration = 0.01; % sec

                
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
save_path = [pwd2 '\..\..\stim_scripts_output\auditory\'];
circuit_path = [pwd2 '\..\RPvdsEx_circuits\'];
circuit_file_name = 'sine_mod_play_YS.rcx';

temp_time = clock;
file_name = sprintf('aMMN_tones_%d_%d_%d_stim_data_%dh_%dm',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;
%% compute stim types sequence
stim_ctx_stdcount = cell(numel(ops.paradigm_sequence),1);
stim_ang = cell(numel(ops.paradigm_sequence),1);
for n_pr = 1:numel(ops.paradigm_sequence)
    if strcmpi(ops.paradigm_sequence{n_pr}, 'control')
        samp_seq = randperm(ops.paradigm_trial_num(n_pr));
        samp_pool = repmat(1:ops.num_freqs,1,ceil(ops.paradigm_trial_num(n_pr)/ops.num_freqs));    
        stim_ang{n_pr} = samp_pool(samp_seq)';
        fprintf('paradigm %d; %d trials per freq\n', n_pr, ops.paradigm_trial_num(n_pr)/ops.num_freqs);
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
        fprintf('paradigm %d; %d deviants\n', n_pr, sum(stim_ctx_stdcount{n_pr}(:,1)==2));
    end
end


%% tag stim trials
stim_stim = cell(numel(ops.paradigm_sequence),1);
for n_tag = 1:size(ops.stim_trials_volt,1)
    pr_idx = ops.stim_trials_volt{n_tag,1};
    stim_stim_seq = f_get_stim_trials(ops.stim_trials_volt(n_tag,2:3), stim_ang{pr_idx}, stim_ctx_stdcount{pr_idx});
    if isempty(stim_stim{pr_idx})
        stim_stim{pr_idx} = stim_stim_seq*ops.stim_trials_volt{n_tag,4};
    else
        stim_stim{pr_idx}(logical(stim_stim_seq)) = stim_stim_seq*ops.stim_trials_volt{n_tag,4};
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
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.addAnalogOutputChannel('Dev1','ao2','Voltage'); % Prairie trig in (>2V)
session.addAnalogOutputChannel('Dev1','ao3','Voltage'); % SLM indicator
session.IsContinuous = true;
%session.Rate = 10000;
volt_cmd = [0 0 0 0];
session.outputSingleScan(volt_cmd);


%% Run trials
RP.Run;
RP.SetTagVal('ModulationAmp', ops.modulation_amp);

start_paradigm=now*86400;%GetSecs();

f_pause_synch(10, session, ops.synch_pulse, volt_cmd)
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
        
        if ~isempty(stim_stim{n_pr})
            SLM_volt = stim_stim{n_pr}(trl);
            trig_volt = logical(SLM_volt)*5;
        else
            SLM_volt = 0;
            trig_volt = 0;
        end
        
        waitbar(trl/ops.paradigm_trial_num(n_pr), h, sprintf('Paradigm %d of %d: Trial %d, angle %d',n_pr, numel(ops.paradigm_sequence), trl, ang));
        % pause for isi
        

        % play
        start_stim = now*86400;%GetSecs();
        RP.SetTagVal('CarrierFreq', control_carrier_freq(ang));
        volt_cmd(1) = vis_volt;
        volt_cmd(4) = SLM_volt;
        session.outputSingleScan(volt_cmd);
        session.outputSingleScan(volt_cmd);
        pause(ops.stim_delay);
        volt_cmd(3) = trig_volt;
        session.outputSingleScan(volt_cmd);
        session.outputSingleScan(volt_cmd);
        pause(ops.stim_trig_duration);
        volt_cmd(3) = 0;
        session.outputSingleScan(volt_cmd);
        session.outputSingleScan(volt_cmd);
        pause(ops.stim_time-ops.stim_delay-ops.stim_trig_duration);
        RP.SetTagVal('CarrierFreq', ops.base_freq);
        volt_cmd(1) = 0; 
        session.outputSingleScan(volt_cmd);
        session.outputSingleScan(volt_cmd);
        
        % moved isi to end and switch slm after isi 
        pause(ops.isi_time+rand(1)/20)
        volt_cmd(4) = 0; 
        session.outputSingleScan(volt_cmd);
        session.outputSingleScan(volt_cmd);
        % record
        stim_times{n_pr}(trl) = start_stim-start_paradigm;
        %fprintf('; Angle %d\n', ang);
    end
    
    if n_pr < numel(ops.paradigm_sequence)
        f_pause_synch(ops.inter_paradigm_pause_time, session, ops.synch_pulse, volt_cmd);
    end
    
end
close(h);

%%
f_pause_synch(10, session, ops.synch_pulse, volt_cmd)

%% close all
volt_cmd(1:end) = 0;
session.outputSingleScan(volt_cmd);
RP.Halt;

%% save info
fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'ops', 'stim_times', 'stim_ang', 'stim_ctx_stdcount', 'stim_stim');
fprintf('Done\n');