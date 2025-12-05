function playcohmotion(Mstate, Pstate, screenPTR, screenNum, loopTrial, Stxtr, DotFrame)

use_daq = false;

if use_daq
    %Wake up the daq:
    DaqDOut(daq, 0, 0); %I do this at the beginning because it improves timing on the call to daq below
end

Pstruct = getParamStruct(Pstate);

screenRes = Screen('Resolution',screenNum);
pixpercmX = screenRes.width/Mstate.screenXcm;
pixpercmY = screenRes.height/Mstate.screenYcm;

syncWX = round(pixpercmX*Mstate.syncSize);
syncWY = round(pixpercmY*Mstate.syncSize);

%in all of the code, we treat the screen as if it is round. this means that
%a stimulus of size x deg ends up having a size in cm of 2pi/360*x deg*monitor
%distance (this is simply the formula for the length of an arc); then
%transform from cm to pixels

sizeDotsCm=Pstruct.sizeDots*2*pi/360*Mstate.screenDist;
sizeDotsPx=round(sizeDotsCm*pixpercmX);



%%%%%%%%%%%%%%%%%%


Npreframes = ceil(Pstruct.predelay*screenRes.hz);
Nstimframes = ceil(Pstruct.stim_time*screenRes.hz);
Npostframes = ceil(Pstruct.postdelay*screenRes.hz);


%%%%%%%%%%%%%%%

%SyncLoc = [0 0 syncWX-1 syncWY-1]';
SyncLoc = [1920*2-syncWX 1080-syncWY 1920*2 1080];
SyncPiece = [0 0 syncWX-1 syncWY-1]';

[SyncLoc, SyncPiece] = f_get_sync_loc(screenRes, Mstate);

%%%%%%%%%%%%%%%

Screen(screenPTR, 'FillRect', Pstruct.background)

if Pstruct.contrast==0
    r=Pstruct.background;
    g=Pstruct.background;
    b=Pstruct.background;
else
    r=Pstruct.redgun;
    g=Pstruct.greengun;
    b=Pstruct.bluegun;
end

%%%Play predelay %%%%
Screen('DrawDots', screenPTR, DotFrame{1}, sizeDotsPx, [r g b],...
    [Pstruct.x_pos Pstruct.y_pos],Pstruct.dotType);
Screen('DrawTexture', screenPTR, Stxtr(1),SyncPiece,SyncLoc);
Screen(screenPTR, 'Flip');
if use_daq
    if loopTrial ~= -1
        digWord = 1;  %Make 1st bit high
        DaqDOut(daq, 0, digWord);
    end
end
for i = 2:Npreframes
    Screen('DrawDots', screenPTR, DotFrame{1}, sizeDotsPx, [r g b],...
        [Pstruct.x_pos Pstruct.y_pos],Pstruct.dotType);
    Screen('DrawTexture', screenPTR, Stxtr(2),SyncPiece,SyncLoc);
    Screen(screenPTR, 'Flip');
end


%%%%%Play whats in the buffer (the stimulus)%%%%%%%%%%

Screen('DrawDots', screenPTR, DotFrame{1}, sizeDotsPx, [r g b],...
    [Pstruct.x_pos Pstruct.y_pos],Pstruct.dotType);
Screen('DrawTextures', screenPTR, Stxtr(1),SyncPiece,SyncLoc);
Screen(screenPTR, 'Flip');
if use_daq
    if loopTrial ~= -1
        digWord = 3;  %toggle 2nd bit to signal stim on
        DaqDOut(daq, 0, digWord);
    end
end
for i = 2:Nstimframes
    Screen('DrawDots', screenPTR, DotFrame{i}, sizeDotsPx, [r g b],...
        [Pstruct.x_pos Pstruct.y_pos],Pstruct.dotType);
    Screen('DrawTextures', screenPTR,Stxtr(1),SyncPiece,SyncLoc);
    Screen(screenPTR, 'Flip');
end
if use_daq
    if loopTrial ~= -1
        digWord = 1;  %toggle 2nd bit to signal stim off
        DaqDOut(daq, 0, digWord);
    end
end
%%%Play postdelay %%%%
for i = 1:Npostframes-1
    Screen('DrawDots', screenPTR, DotFrame{Nstimframes}, sizeDotsPx, [r g b],...
        [Pstruct.x_pos Pstruct.y_pos],Pstruct.dotType);
    Screen('DrawTexture', screenPTR, Stxtr(2),SyncPiece,SyncLoc);
    Screen(screenPTR, 'Flip');
end
Screen('DrawDots', screenPTR, DotFrame{Nstimframes}, sizeDotsPx, [r g b],...
    [Pstruct.x_pos Pstruct.y_pos],Pstruct.dotType);
Screen('DrawTexture', screenPTR, Stxtr(1),SyncPiece,SyncLoc);
Screen(screenPTR, 'Flip');
if use_daq
    if loopTrial ~= -1
        %digWord = bitxor(digWord,7); %toggle all 3 bits (1st/2nd bits go low, 3rd bit is flipped)
        %DaqDOut(daq, 0,digWord);  
        DaqDOut(daq, 0, 0);  %Make sure 3rd bit finishes low
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('DrawTexture', screenPTR, Stxtr(2),SyncPiece,SyncLoc);  
Screen(screenPTR, 'Flip');

