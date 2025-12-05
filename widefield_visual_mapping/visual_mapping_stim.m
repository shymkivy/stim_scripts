addpath(genpath('functions'));

%%
clear
close all

Screen('Preference', 'SkipSyncTests', 1);
Priority(1);  %Make sure priority is set to "real-time"  

% priorityLevel=MaxPriority(w);
% Priority(priorityLevel);

stim1 = 'PG';   % 'PG', 'FG', 'RD', 'FN', 'MP' 'CM'
Pstate = configurePstate(stim1); %Use grater as the default when opening

Mstate = configureMstate();

%configCom(primaryIP);
%configSync;

% Make sure to uncomment the shutter once daq is connected
%configShutter; 

[Mstate, screenPTR, screenNum] = screenconfig(Mstate);

loopTrial = -1;

if strcmpi(stim1, 'PG')
    [Gtxtr, TDim] = makeGratingTexture_periodic(Pstate, Mstate, screenPTR, screenNum);
    Stxtr = makeSyncTexture(Mstate, screenPTR, screenNum);
    playgrating_periodic(Mstate, Pstate, screenPTR, screenNum, loopTrial, Gtxtr, TDim, Stxtr);
elseif strcmpi(stim1, 'FG')
    [Gtxtr, TDim, Masktxtr, domains, probRatios] = makeGratingTexture_flash(Mstate, Pstate, screenPTR, screenNum, loopTrial);
    Stxtr = makeSyncTexture(Mstate, screenPTR, screenNum);
    playgrating_flashHartley(Mstate, Pstate, screenPTR, screenNum, loopTrial, Gtxtr, Masktxtr, TDim, domains, probRatios, Stxtr);
elseif strcmpi(stim1, 'RD')
    [GtxtrAll, OriAll, StimLoc, TDim] = makeRainTexture(Mstate, Pstate, screenPTR, screenNum);
    Stxtr = makeSyncTexture(Mstate, screenPTR, screenNum);
    playrain(Mstate, Pstate, screenPTR, screenNum, loopTrial, GtxtrAll, OriAll, StimLoc, TDim, Stxtr);
elseif strcmpi(stim1, 'FN')
    [Gtxtr, TDim] = makeNoiseTexture(Mstate, Pstate, screenPTR, screenNum);
    Stxtr = makeSyncTexture(Mstate, screenPTR, screenNum);
    playnoise(Mstate, Pstate, screenPTR, screenNum, loopTrial, Gtxtr, TDim, Stxtr);
elseif strcmpi(stim1, 'MP')
    playmapper(Mstate, Pstate, screenPTR, screenNum);
elseif strcmpi(stim1, 'CM')
    DotFrame = makeCohMotion(Mstate, Pstate, screenNum, loopTrial);
    Stxtr = makeSyncTexture(Mstate, screenPTR, screenNum);
    playcohmotion(Mstate, Pstate, screenPTR, screenNum, loopTrial, Stxtr, DotFrame);
end

Screen('CloseAll');

%makeGratingTexture_flash

% playgrating_periodic
% 
% 
% makeRainTexture
% playrain

%playnoise
