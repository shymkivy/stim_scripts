function Mstate = configureMstate

Mstate.anim = 'xx0';
Mstate.unit = '000';
Mstate.expt = '000';

Mstate.hemi = 'left';

Mstate.screenDist = 15;  % was 25 yuriy
Mstate.monitor = 'YS2'; %'LIN';  %This should match the default at the primary. Otherwise, they will differ, but only at startup

% Mstate.screenDist = 10;  
% Mstate.monitor = 'YS'; 

%'updateMonitor.m' happens in 'screenconfig.m' at startup

Mstate.running = 0;

Mstate.syncSize = 2; % Armel Changed this from value (cm)
                       
