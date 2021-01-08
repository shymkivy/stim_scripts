clear;
DOopto=0; %1=yes; 0=no opto stimulus
record_triggers=1; %if you want to send voltage triggers from the daq
isicolor=1;%1;  %1 if black
Ooff=0; %volts@
Oon=3; %volts
displayTime=3; 
pauseTime=6;    
orientations=12;
trialsperorientation=10;
squarewave=1; %if you6 want to do squareincludeViswaves instead of sinewaves
%change settings above
Screen('Preference', 'SkipSyncTests', 1);
AssertOpenGL; % Make sure this is running on OpenGL Psychtoolbox:
screenid = max(Screen('Screens')); % Choose screen with maximum id - the secondary display on a dual-display setup for display
[win, rect] = Screen('OpenWindow',screenid, [255/2 255/2 255/2]); % rect is the coordinates of the screen
ifi = Screen('GetFlipInterval', win);
ctrsts=[.015625 .03125 .0625 .125 .25 .5 .85];
angsy=[0 1 .5 .866 -.5  -.866 -0 -1 -.5 -.866 .5  .866];
angsx=[1 0 .866 .5 .866 .5 -1 -0 -.866 -.5 -.866 -.5];
spfrq=[.01  .02 .04 .08 .16 .32];
if record_triggers==1
    session=daq.createSession('ni');
    session.addAnalogOutputChannel('Dev3','ao0','Voltage');
    session.addAnalogOutputChannel('Dev3','ao1','Voltage');
    session.IsContinuous = true;
    %session.Rate = 10000;
    session.outputSingleScan([0,Ooff]);
end


for repeata=1
for cc=7 %vary contrast accross 7 levels
    angs=ones(trialsperorientation,1);
    for o=2:orientations
        angs=vertcat(angs,zeros(trialsperorientation,1)+o);
    end
    randangs=randsample(size(angs,1),size(angs,1));
    
    for ang1=1:size(angs,1)
        ang=angs(randangs(ang1,1),1);
        fprintf('Trial %d; Angle %d\n', ang1, ang);
        contrast=ctrsts(cc); 
        white = WhiteIndex(win); % pixel value for white
        black = BlackIndex(win); % pixel value for black
        gray = (white+black)/2;
        inc = white-gray;
        for s=4 %vary spatial frequency accross 6 levels
            scrsz = rect;   
            [x,y] = meshgrid((-scrsz(3)/2)+1:(scrsz(3)/2)-1, (-scrsz(4)/2)+1:(scrsz(4)/2)-1);
            sp1=(.5799/10.2)*spfrq(s); %10.2 is just some scaling factor that i calibrated. do not change unless you know what youre doing!
             cps=2; %movement velocity. cycles per secondo
             start1 = GetSecs();
            Screen('FillRect', win, [isicolor isicolor isicolor], rect);
            Screen('Flip',win);
            framerate=60;
            for i=1:30
                ang1=ang1+(2*pi)/(framerate/cps);
                if squarewave==1
                m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)+ang1)); 
                else 
                m1 = sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)+ang1); 
                end
                tex(i)=Screen('MakeTexture', win, gray+((contrast*gray)*m1)); 
            end
            
            
            indices=1:30;
            for a=1:5
                indices=horzcat(indices,indices);
            end
            now=GetSecs();
            while (now-start1)<(pauseTime/2)
                now=GetSecs();
            end
            Screen('FillRect', win, [isicolor isicolor isicolor], rect);
            Screen('Flip',win);
            now=GetSecs();
            while (now-start1)<(pauseTime+(rand(1,1)))
                now=GetSecs();
            end
            ct=0;
            if DOopto==1
            opto=(round(rand)*Oon);
            %opto=(Oon); %commendt out if want 50%
            else opto=Ooff;
            end
                start = GetSecs();
                now=GetSecs();
                while (now-start)<1+displayTime
                    now=GetSecs();

                    if record_triggers==1
                    session.outputSingleScan([0,opto]);
                    end
                    while and((now-start)>.5,(now-start)<.5+displayTime)
                            vbl = Screen('Flip',win);    
                            ct=ct+1;
                            Screen('DrawTexture', win, tex(indices(ct)));
                            now=GetSecs;
                            if record_triggers==1
                                session.outputSingleScan([ang/4,opto]);
                            end
                    end  
                    while and((now-start)>.5+displayTime,(now-start)<1+displayTime)           
                        now=GetSecs;
                        if record_triggers==1
                            session.outputSingleScan([0,opto]);
                        end
                        Screen('FillRect', win, [isicolor isicolor isicolor], rect);
                        Screen('Flip',win);
                    end
                end    
                if record_triggers==1
                    session.outputSingleScan([0,Ooff]);
                end
                Screen('FillRect', win, [isicolor isicolor isicolor], rect);
                Screen('Flip',win);
        end
    end
end
end

% pause
pause_start = GetSecs();
pause_now=GetSecs();
while (pause_now-pause_start) < pauseTime
    pause_now=GetSecs();
end

sca();