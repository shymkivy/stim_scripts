clear

DOopto=0; %1=yes; 0=no opto stimulus

displayTime =.5;
pauseTime=1;
trials=400;

flip_angs_pattern = 2; % choose from angsy_patterns below
inter_paradigm_pause_time = 2; % pause time between runs

%dont forget to change the display time! and contrast if you care....
record_triggers=1; %if you want to send voltage triggers from the daq

Ooff=0; %volts
Oon=3; %foltage. if diameter of light circle is 1mm, then use 1.5.
%if .8mm, use 1.23. these give about 4mw/mm2. 1=1.59mw. 1.23=2.00mw 1.5=2.35mw. 2=3.17. 2.5=3.93. 3=4.67. 3.5=5.36 4=6.05

probab=[.01 .01 .02 .01 .01 .01 .1 .1 .3 .5 1];

% stim parameters
squarewave=1; %if you want to do squarewaves instead of sinewaves
%change settings above
isicolor=1; %1 if black, 255/2 if gray
ctrsts=[.015625 .03125 .0625 .125 .25 .5 .85];
angsy_patterns = [0 1; .5 -.5; .5 -.5; .5 -.5;  -.866 .5;   1 0];
angsx_patterns = [1 0; .5  .5; .5  .5; .5 -.866; .5   .866; 0 1];
angsy = angsy_patterns(flip_angs_pattern,:);
angsx = angsx_patterns(flip_angs_pattern,:);
% angsy= [.5 -.5];%[0 1];%[.5 -.5];%[.5 -.5];%[-.866 .5];%[1 0];%
% angsx= [.5 .5];%[1 0];%[.5 .5];%[.5 -.866];%[.5 .866];[0 1];%
spfrq=[.01  .02 .04 .08 .16 .32];


Screen('Preference', 'SkipSyncTests', 0);
AssertOpenGL; % Make sure this is running on OpenGL Psychtoolbox:
screenid = max(Screen('Screens')); % Choose screen with maximum id - the secondary display on a dual-display setup for display
[win, rect] = Screen('OpenWindow',screenid, [255/2 255/2 255/2]); % rect is the coordinates of the screen
ifi = Screen('GetFlipInterval', win);
if record_triggers==1
    session=daq.createSession('ni');
    session.addAnalogOutputChannel('Dev1','ao0','Voltage');
    session.addAnalogOutputChannel('Dev1','ao1','Voltage');
    session.IsContinuous = true;
    %session.Rate = 10000;
    session.outputSingleScan([0, Ooff]);
end

for designstim=1
    for cc=7 %contrast (out of 7)
        contrast=ctrsts(cc);
        white = WhiteIndex(win); % pixel value for white
        black = BlackIndex(win); % pixel value for black
        gray = (white+black)/2;
        inc = white-gray;
        for s=4 %determine spatial frequency (out of 6)
            scrsz = rect;
            [x,y] = meshgrid((-scrsz(3)/2)+1:(scrsz(3)/2)-1, (-scrsz(4)/2)+1:(scrsz(4)/2)-1);
            sp1=(.5799/10.2)*spfrq(s); %10.2 is just some scaling factor that i calibrated. do not change unless you know what youre doing!
            
            ang=1;
            m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)));
            tex(ang)=Screen('MakeTexture', win, gray+((contrast*gray)*m1));
            ang=2;
            m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)));
            tex(ang)=Screen('MakeTexture', win, gray+((contrast*gray)*m1));
        end
    end
end

stdcounts=0;
Screen('FillRect', win, [isicolor isicolor isicolor], rect);
Screen('Flip',win);

% pause between paradigms
pause_start = GetSecs();
pause_now=GetSecs();
while (pause_now-pause_start) < inter_paradigm_pause_time
    pause_now=GetSecs();
end


startop1=GetSecs();
startop2=GetSecs(); 
for trl=1:trials/2
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
    prob=probab(stdcounts+1);
    anga=floor(rand(1)*(1/prob));
    ang=(anga<1)+1;
    if ang==1
        stdcounts=1+stdcounts;
    else
        stdcounts=0;
    end
    
    if trl<31
        ang=1;
    end
    
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
        Screen('Flip',win);
        if record_triggers==1
            session.outputSingleScan([ang,opto]);
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

if record_triggers==1
    session.outputSingleScan([0,Ooff]);
end
disp(sum(trialrecord(:,1)==2)/trl)

% pause between paradigms
pause_start = GetSecs();
pause_now=GetSecs();
while (pause_now-pause_start) < inter_paradigm_pause_time
    pause_now=GetSecs();
end

% start flip paradigm
flptrials=[2 1];
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
            
            ang=1;
            m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)));
            tex(flptrials(ang))=Screen('MakeTexture', win, gray+((contrast*gray)*m1));
            ang=2;
            m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)));
            tex(flptrials(ang))=Screen('MakeTexture', win, gray+((contrast*gray)*m1));
        end
    end
end
stdcounts=0;
% Screen('FillRect', win, [isicolor isicolor isicolor], rect);
% Screen('Flip',win);
startop1=GetSecs();
startop2=GetSecs();
for trl=1:trials/2
    fprintf('Trial %d', trl);
    start1 = GetSecs();
    now=GetSecs();
    for optodo=1
        if DOopto==1
            if rem(trl,2)==0
                start2 = GetSecs();
                now2= GetSecs();
                % wait 250ms
                while (now2-start2)<.25
                    now2=GetSecs();
                end
                opto=Oon;
                if record_triggers==1
                    session.outputSingleScan([0,opto]);
                end
                start2 = GetSecs();
                now2= GetSecs();
                % wait 250ms
                while (now2-start2)<.25
                    now2=GetSecs();
                end
            else
                start2 = GetSecs();
                now2= GetSecs();
                % wait 250ms
                while (now2-start2)<.25
                    now2=GetSecs();
                end
                opto=Ooff;
                if record_triggers==1
                    session.outputSingleScan([0,opto]);
                end
                start2 = GetSecs();
                now2= GetSecs();
                % wait 250 ms
                while (now2-start2)<.25
                    now2=GetSecs();
                end
            end
        else
            opto=0;
        end
    end
    prob=probab(stdcounts+1);
    anga=floor(rand(1)*(1/prob));
    ang=(anga<1)+1;
    if ang==1
        stdcounts=1+stdcounts;
    else
        stdcounts=0;
    end
    if trl<30
        ang=1;
    end
    
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
        Screen('Flip',win);
        if record_triggers==1
            session.outputSingleScan([ang,opto]);
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


% pause between paradigms
pause_start = GetSecs();
pause_now=GetSecs();
while (pause_now-pause_start) < inter_paradigm_pause_time
    pause_now=GetSecs();
end

if record_triggers==1
    session.outputSingleScan([0,Ooff]);
end
sca();

disp(sum(trialrecord(:,1)==2)/trl)

temp_time = clock;
save_note = 'vMMN_wOPTO_newJPH';
file_name = [num2str(temp_time(2)), '_', num2str(temp_time(3)), '_', num2str(temp_time(1)), '_', num2str(temp_time(4)), '_', num2str(temp_time(5))];
save(['C:\Users\rylab-901c\Desktop\Yuriy_scripts\scripts_output\', file_name, '_vMMN_wOPTO_newJPH'], 'save_note', 'DOopto', 'angsx', 'angsy');
