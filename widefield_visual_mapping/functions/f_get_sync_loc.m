function [SyncLoc, SyncPiece] = f_get_sync_loc(screenRes, Mstate)

pixpercmX = screenRes.width/Mstate.screenXcm;
pixpercmY = screenRes.height/Mstate.screenYcm;

syncWX = round(pixpercmX*Mstate.syncSize);
syncWY = round(pixpercmY*Mstate.syncSize);

startX = 0;
startY = screenRes.height - syncWY;
SyncLoc = [startX, startY, startX+syncWX, startY+syncWY]'; %yuriy destination rect
SyncPiece = [0 0 syncWX-1 syncWY-1]';   % yuriy source rect

