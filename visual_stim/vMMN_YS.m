%% vMMN script
%
%   last update: 3/11/19
%
%%
clear

%% parameters
% ------ Stim params ------
ops.stim_time = 0.5;                                         % sec
ops.isi_time = 0.5;
% ------ Paradigm sequence ------
ops.paradigm_sequence = {'Control', 'MMN', 'flip_MMN'};     % 3 options {'Control', 'MMN', 'flip_MMN'}, concatenate as many as you want
ops.paradigm_trial_num = [400, 600, 600];                   % how many trials for each paradigm
ops.paradigm_MMN_pattern = [0, 1, 1];                       % which patterns for MMN/flip (controls are ignored)
                                                            % 1= horz/vert; 2= 45deg;
% ------ MMN params ------
ops.initial_red_num = 20;                                   % how many redundants to start with
ops.inter_paradigm_pause_time = 60;                         % how long to pause between paragigms
ops.MMN_probab=[0.1*ones(1,20) .2 .25 .5 1]; 
% probability of deviants   % MMN_probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];   % jordan's probab

% ------ Other ------
ops.synch_pulse = 1;                                        % 1 Do you want to use led pulse for synchrinization
% ------ Stim params ------
ops.squarewave=1;                                           % do squarewaves instead of sinewaves
ops.driftingGrating = 1;                                    % use if you want to make it drifting grating
ops.isicolor=170;   % appx middle                                      % Shade of gray on screen during isi (1 if black, 255/2 if gray)
ops.ctrsts=[.015625 .03125 .0625 .125 .25 .5 .85];          % Range of contrasts to use
ops.ctrst = 7;                                                  % pick 
ops.spfrqs=[.01  .02 .04 .08 .16 .32];                      % Range of spatial freqs to use
ops.spfrq = 4;                                                  % pick 
ops.angs_rad = pi*(0:7)/8;                                  % Orientations to use, in rad
ops.MMN_patterns = [1, 5; 3, 7; 2, 6; 4, 8];                % MMN orthogonal pairs (indexing through angs_rad)


%% predicted run time
run_time = (ops.stim_time+ops.isi_time+0.025)*(sum(ops.paradigm_trial_num)) + (numel(ops.paradigm_trial_num)-1)*ops.inter_paradigm_pause_time + 20 + 120;
fprintf('Expected run duration: %.1fmin (%.fsec)\n',run_time/60,run_time);

% mag = sqrt(angsy.^2 + angsx.^2);
%%
pwd2 = fileparts(which('vMMN2_YS.m')); %mfilename
addpath([pwd2 '\functions']);
save_path = [pwd2 '\..\..\stim_scripts_output\visual\'];

temp_time = clock;
file_name = sprintf('vMMN_%d_%d_%d_stim_data_%dh_%dm.mat',temp_time(2), temp_time(3), temp_time(1)-2000, temp_time(4), temp_time(5));
clear temp_time;

%% calculate how many deviants you will get
compute_probability_dev = 0;
if compute_probability_dev
    sec1 = 0;
    num_dev = 600;
    times = [];
    probab2 = ops.MMN_probab(1);
    num_repeats = 100000;
    for ii = 1:num_repeats
        sec1 = sec1 + 1;
        if numel(ops.MMN_probab) > 1
            probab2 = ops.MMN_probab(sec1);
        end
            
        if rand(1) < probab2
            times = [times; sec1];
            sec1 = 0;
        end
    end

    temp_t = 4;
    dev_fraq = sum(times>temp_t)/num_repeats;
    fprintf('%.1f%s deviants expected with t>%d (%.1f/%d)\n' ,dev_fraq*100,'%',temp_t,dev_fraq*(num_dev-ops.initial_red_num), num_dev)
    clear temp_t dev_fraq;
    
    figure;
    histogram(times, numel(unique(times)),'Normalization', 'probability');
end

%% initialize
Screen('Preference', 'SkipSyncTests', 1);
AssertOpenGL; % Make sure this is running on OpenGL Psychtoolbox:
screenid = max(Screen('Screens')); % Choose screen with maximum id - the secondary display on a dual-display setup for display
[win, rect] = Screen('OpenWindow',screenid, [255/2 255/2 255/2]); % rect is the coordinates of the screen
ops.flipInterval = Screen('GetFlipInterval', win);

%% create stim
for designstim=1
    isi_color = [ops.isicolor ops.isicolor ops.isicolor];
    tex = zeros(1,numel(ops.angs_rad)*numel(ops.ctrst)*numel(ops.spfrq));
    angsy = sin(ops.angs_rad);
    angsx = cos(ops.angs_rad);
    for cc=ops.ctrst %contrast (out of 7)
        contrast=ops.ctrsts(cc);
        white = WhiteIndex(win); % pixel value for white
        black = BlackIndex(win); % pixel value for black
        gray = (white+black)/2;
        inc = white-gray;
        for s=ops.spfrq %determine spatial frequency
            scrsz = rect;
            [x,y] = meshgrid((-scrsz(3)/2)+1:(scrsz(3)/2)-1, (-scrsz(4)/2)+1:(scrsz(4)/2)-1);
            sp1=(.5799/10.2)*ops.spfrqs(s); %10.2 is just some scaling factor that i calibrated. do not change unless you know what youre doing!
            
            for ang=1:numel(ops.angs_rad)
                m1 = sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x));
                if ops.squarewave
                    m1 = sign(m1);
                end
                tex(ang)=Screen('MakeTexture', win, gray+((contrast*gray)*m1));
            end
        end
    end
end

Screen('FillRect', win, isi_color, rect);
Screen('Flip',win);

%% initialize DAQ
session=daq.createSession('ni');
session.addAnalogOutputChannel('Dev1','ao0','Voltage');
session.addAnalogOutputChannel('Dev1','ao1','Voltage');
session.IsContinuous = true;
%session.Rate = 10000;
session.outputSingleScan([0,0]);

%% Run trials

IF_pause_synch(10, session, ops.synch_pulse);
stim_times = cell(numel(ops.paradigm_sequence),1);
stim_ang = cell(numel(ops.paradigm_sequence),1);
stim_ctx_stdcount = cell(numel(ops.paradigm_sequence),1);
start_paradigm=GetSecs();
h = waitbar(0, 'initializeing...');
for parad_num = 1:numel(ops.paradigm_sequence)
    fprintf('Paradigm %d: %s, %d trials:\n',parad_num, ops.paradigm_sequence{parad_num}, ops.paradigm_trial_num(parad_num));
    
    % check what paradigm
    if strcmpi(ops.paradigm_sequence{parad_num}, 'control')
        cont_parad = 1;
    else
        cont_parad = 0;
        if strcmpi(ops.paradigm_sequence{parad_num}, 'mmn')
            curr_MMN_pattern = ops.MMN_patterns(ops.paradigm_MMN_pattern(parad_num),:);
        elseif strcmpi(ops.paradigm_sequence{parad_num}, 'flip_mmn')
            curr_MMN_pattern = fliplr(ops.MMN_patterns(ops.paradigm_MMN_pattern(parad_num),:));
        else
            error('unknown paradigm type, line 140');          
        end 
        stdcounts = 0;
    end
    
    stim_times{parad_num} = zeros(ops.paradigm_trial_num(parad_num),1);
    stim_ang{parad_num} = zeros(ops.paradigm_trial_num(parad_num),1);
    stim_ctx_stdcount{parad_num} = zeros(ops.paradigm_trial_num(parad_num),2);
    
    % run trials
    for trl=1:ops.paradigm_trial_num(parad_num)
        start_trial1 = GetSecs();
        
        % compute trial info
        if cont_parad
            ang=floor(rand(1)*numel(tex))+1;
            vis_volt = ang/numel(tex)*4;
        else
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
            ang = curr_MMN_pattern(ctxt);
            vis_volt = ctxt;
            stim_ctx_stdcount{parad_num}(trl,:) = [ctxt, stdcounts];
        end
        
        waitbar(trl/ops.paradigm_trial_num(parad_num), h, sprintf('Paradigm %d of %d: Trial %d, angle %d',parad_num, numel(ops.paradigm_sequence), trl, ang));
        % pause for isi
        now=GetSecs();
        while (now-start_trial1)<(ops.isi_time+rand(1)/20)
            now=GetSecs();
        end
        Screen('Flip',win);

        % draw
        start_stim = GetSecs();
        now=GetSecs();
        while (now-start_stim)<ops.stim_time
            now=GetSecs();
            Screen('DrawTexture', win, tex(ang));
            Screen('Flip',win);
            session.outputSingleScan([vis_volt,0]);
        end
        session.outputSingleScan([0,0]);

        % reset screen
        Screen('FillRect', win, isi_color, rect);
        Screen('Flip',win);
        Screen('FillRect', win, isi_color, rect);
        Screen('Flip',win);

        % record
        stim_times{parad_num}(trl) = start_stim-start_paradigm;
        stim_ang{parad_num}(trl) = ang;
        
        %fprintf('; Angle %d\n', ang);
    end
    
    if parad_num < numel(ops.paradigm_sequence)
        IF_pause_synch(ops.inter_paradigm_pause_time, session, ops.synch_pulse);
    end
    
end
close(h);
%%
IF_pause_synch(10, session, ops.synch_pulse)

%% close all
session.outputSingleScan([0,0]);
sca();

%% save info
fprintf('Saving...\n');
save([save_path, file_name, '.mat'],'ops', 'stim_times', 'stim_ang', 'stim_ctx_stdcount');
fprintf('Done\n');


%% analysis

plot_results = 1;
if plot_results
    counts_cont = [];
    counts_dev = [];
    label_dev = {};
    for parad_num = 1:numel(ops.paradigm_sequence)
        if strcmpi(ops.paradigm_sequence{parad_num}, 'control')
            counts_cont = [counts_cont; hist(stim_ang{parad_num}, 1:8)];
        elseif strcmpi(ops.paradigm_sequence{parad_num}, 'mmn')
            counts_dev = [counts_dev; sum(stim_ctx_stdcount{parad_num}(:,2)==4)];
            label_dev = [label_dev; sprintf('MMN ang=%d', ops.MMN_patterns(ops.paradigm_MMN_pattern(2),2))];
        elseif strcmpi(ops.paradigm_sequence{parad_num}, 'flip_mmn')
            counts_dev = [counts_dev; sum(stim_ctx_stdcount{parad_num}(:,2)==4)];
            label_dev = [label_dev; sprintf('MMN flip ang=%d', ops.MMN_patterns(ops.paradigm_MMN_pattern(2),1))];
        end
    end
    figure;
    for parad_num = 1:size(counts_cont,1)
        subplot(size(counts_cont,1)+1,1,parad_num);
        bar(counts_cont(parad_num,:));
        title(sprintf('Control %d',parad_num))
    end
    subplot(size(counts_cont,1)+1,1,size(counts_cont,1)+1);
    bar(categorical(label_dev), counts_dev);
    title('Numbers of Dev after 4 Red in each MMN');
    ylabel('Counts');
end


%% functions

function IF_pause_synch(pause_time, session, synch)
    
    LED_on = 3; %foltage. if diameter of light circle is 1mm, then use 1.5.
    %if .8mm, use 1.23. these give about 4mw/mm2. 1=1.59mw. 1.23=2.00mw 1.5=2.35mw. 2=3.17. 2.5=3.93. 3=4.67. 3.5=5.36 4=6.05

    % synch artifact
    if synch
        pause((pause_time - 1)/2);
        session.outputSingleScan([0,LED_on]);
        pause(1);
        session.outputSingleScan([0,0]);
        pause((pause_time - 1)/2);
    else
        pause(pause_time);
    end

end
