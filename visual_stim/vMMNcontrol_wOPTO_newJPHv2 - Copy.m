clear

DOopto=0; %1=yes; 0=no opto stimulus

displayTime =.5;
pauseTime=1;
trials=400;


%dont forget to change the display time! and contrast if you care....
record_triggers=1; %if you want to send voltage triggers from the daq

Ooff=0; %volts
Oon=3; %foltage. if diameter of light circle is 1mm, then use 1.5.
%if .8mm, use 1.23. these give about 4mw/mm2. 1=1.59mw. 1.23=2.00mw 1.5=2.35mw. 2=3.17. 2.5=3.93. 3=4.67. 3.5=5.36 4=6.05

probab=[.01 .01 .02 .1 .1 .1 .1 .5 .5 .5 1];

squarewave=1; %if you want to do squarewaves instead of sinewaves
%change settings above
isicolor=1; %1 if black, 255/2 if gray
ctrsts=[.015625 .03125 .0625 .125 .25 .5 .85];
angsy=[0 1 .866 .5 .5 -.5  -.866 -.5 ];
angsx=[1 0 .5 .866 .5 .5 .5 .866];
spfrq=[.01  .02 .04 .08 .16 .32];


Screen('Preference', 'SkipSyncTests', 1);
AssertOpenGL; % Make sure this is running on OpenGL Psychtoolbox:
screenid = max(Screen('Screens')); % Choose screen with maximum id - the secondary display on a dual-display setup for display
[win, rect] = Screen('OpenWindow',screenid, [255/2 255/2 255/2]); % rect is the coordinates of the screen
ifi = Screen('GetFlipInterval', win);
if record_triggers==1
    session=daq.createSession('ni');
    session.addAnalogOutputChannel('Dev3','ao0','Voltage');
    session.addAnalogOutputChannel('Dev3','ao1','Voltage');
    session.IsContinuous = true;
    %session.Rate = 10000;
    session.outputSingleScan([0,Ooff]);
end


for designstim=1
    for cc=7 %contrast (out of 7)
        contrast=ctrsts(cc);
        white = WhiteIndex(win); % pixel value for white
        black = BlackIndex(win); % pixel value for black
        gray = (white+black)/2;
        inc = white-gray;
        for s=4 %determine spatial frequency
            scrsz = rect;
            [x,y] = meshgrid((-scrsz(3)/2)+1:(scrsz(3)/2)-1, (-scrsz(4)/2)+1:(scrsz(4)/2)-1);
            sp1=(.5799/10.2)*spfrq(s); %10.2 is just some scaling factor that i calibrated. do not change unless you know what youre doing!
            
            for ang=1:8
                m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)));
                tex(ang)=Screen('MakeTexture', win, gray+((contrast*gray)*m1));
            end
        end
    end
end
stdcounts=0;
Screen('FillRect', win, [isicolor isicolor isicolor], rect);
Screen('Flip',win);

% pause
pause_start = GetSecs();
pause_now=GetSecs();
while (pause_now-pause_start) < 2
    pause_now=GetSecs();
end

startop1=GetSecs();
startop2=GetSecs();
for trl=1:trials
    fprintf('Trial %d', trl);
    start1 = GetSecs();
    now=GetSecs();
    for optodo=1
        if DOopto==1
            if rem(trl,2)==0
                start2 = GetSecs();
                now2= GetSecs();
                while (now2-start2)<.25
                    now2=GetSecs();
                end
                opto=Oon;
                if record_triggers==1
                    session.outputSingleScan([0,opto]);
                end
                start2 = GetSecs();
                now2= GetSecs();
                while (now2-start2)<.25
                    now2=GetSecs();
                end
            else
                start2 = GetSecs();
                now2= GetSecs();
                while (now2-start2)<.25
                    now2=GetSecs();
                end
                opto=Ooff;
                if record_triggers==1
                    session.outputSingleScan([0,opto]);
                end
                start2 = GetSecs();
                now2= GetSecs();
                while (now2-start2)<.25
                    now2=GetSecs();
                end
            end
        else
            opto=0;
        end
    end
    ang=floor(rand(1)*8)+1;
    
    if DOopto==1
        pauseTime=.01;
    end
    now=GetSecs();
    while (now-start1)<(pauseTime/2+(rand(1,1))/20)
        now=GetSecs();
    end
    Screen('Flip',win);
    
    start = GetSecs();
    now=GetSecs();
    while (now-start)<displayTime
        now=GetSecs();
        Screen('DrawTexture', win, tex(ang));
        vbl = Screen('Flip',win);
        if record_triggers==1
            session.outputSingleScan([ang/2,opto]);
        end
    end
    if record_triggers==1
        session.outputSingleScan([0,opto]);
    end
    Screen('FillRect', win, [isicolor isicolor isicolor], rect);
    Screen('Flip',win);
    Screen('FillRect', win, [isicolor isicolor isicolor], rect);
    Screen('Flip',win);
    trialrecord(trl,1)=ang;
    trialrecord(trl,2)=GetSecs()-start1;
    fprintf('; Angle %d\n', ang);
end

% pause
pause_start = GetSecs();
pause_now=GetSecs();
while (pause_now-pause_start) < 5
    pause_now=GetSecs();
end

if record_triggers==1
    session.outputSingleScan([0,Ooff]);
end
sca();


for trg=1:6
    disp(sum(trialrecord(:,1)==trg)/trl)
end