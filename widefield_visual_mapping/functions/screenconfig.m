function [Mstate, screenPTR, screenNum] = screenconfig(Mstate)

%screens=Screen('Screens');
%screenNum=max(screens);

screenNum= 2;
screenRes1 = Screen('Resolution',1);
screenRes2 = Screen('Resolution',screenNum);

scr_endX = screenRes1.width + screenRes2.width;

screenPTR = Screen('OpenWindow', screenNum, [128 128 128], [screenRes2.width, 0, scr_endX, screenRes2.height]);  %[1920 0 5760 1080]

Screen(screenPTR,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

Mstate = updateMonitor(Mstate, screenPTR);

Screen('PixelSizes',screenPTR);

pixpercmX = screenRes2.width/Mstate.screenXcm;
pixpercmY = screenRes2.height/Mstate.screenYcm;

syncWX = round(pixpercmX*Mstate.syncSize);
syncWY = round(pixpercmY*Mstate.syncSize);

Mstate.refresh_rate = 1/Screen('GetFlipInterval', screenPTR);

%SyncLoc = [0 screenRes.height-syncWY syncWX-1 screenRes.height-1]';

%sc_res = Screen('Resolution', screenPTR);

[SyncLoc, SyncPiece] = f_get_sync_loc(screenRes2, Mstate); %yuriy
% Brice Changed here
%SyncLoc = [0 0 syncWX-1 syncWY-1]'; % Brice commented this line
%SyncLoc = [1920*2-syncWX 1080-syncWY 1920*2 1080]'; % Brice added this line
%startX = round((screenRes2.width-syncWX)/2);
%startY = round((screenRes2.height-syncWX)/2);
%SyncLoc = [startX, startY, startX+syncWX, startY+syncWY]'; %yuriy destination rect
%SyncPiece = [0 0 syncWX-1 syncWY-1]';   % yuriy source rect
%SyncPiece = [0 0 syncWX-1 syncWY-1]';
%SyncPiece = [scr_endX-syncWX 1080-syncWY scr_endX 1080]';

%Set the screen

Screen(screenPTR, 'FillRect', 128)
Screen(screenPTR, 'Flip');

wsync = Screen(screenPTR, 'MakeTexture', 0*ones(syncWY,syncWX)); % "low"

Screen('DrawTexture', screenPTR, wsync,SyncPiece,SyncLoc);
Screen(screenPTR, 'Flip');


