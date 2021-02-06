function vmmn_present(angsx, angsy, params, session)



%% stim design
for designstim=1
    for cc=7 %contrast (out of 7)
        contrast=params.ctrsts(cc);
        white = WhiteIndex(params.win); % pixel value for white
        black = BlackIndex(params.win); % pixel value for black
        gray = (white+black)/2;
        inc = white-gray;
        for s=4 %determine spatial frequency (out of 6)
            scrsz = params.rect;
            [x,y] = meshgrid((-scrsz(3)/2)+1:(scrsz(3)/2)-1, (-scrsz(4)/2)+1:(scrsz(4)/2)-1);
            sp1=(.5799/10.2)*params.spfrq(s); %10.2 is just some scaling factor that i calibrated. do not change unless you know what youre doing!
            
            ang=1;
            m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)));
            tex(ang)=Screen('MakeTexture', params.win, gray+((contrast*gray)*m1));
            ang=2;
            m1 = sign(sin(angsy(ang)*(sp1*2*pi*y)+angsx(ang)*(sp1*2*pi*x)));
            tex(ang)=Screen('MakeTexture', params.win, gray+((contrast*gray)*m1));
        end
    end
end


%% Stim paradigm

% stdcounts=0;
Screen('FillRect', params.win, [params.isicolor params.isicolor params.isicolor], params.rect);
Screen('Flip',params.win);

% pause between paradigms
pause_start = now*86400;
pause_now=now*86400;
while (pause_now-pause_start) <2
    pause_now=now*86400;
end


for trl=1:params.trials
    fprintf('Trial %d', trl);
    
    start1 = now*86400;
    
    % change the probability rule, make it random and adjustable
    ang = (rand(1) < params.dev_probability) + 1;
    
%     prob=probab(stdcounts+1);
%     anga=floor(rand(1)*(1/prob));
%     ang=(anga<1)+1;
%     if ang==1
%         stdcounts=1+stdcounts;
%     else
%         stdcounts=0;
%     end
    
    if trl< params.initial_red_num
        ang=1;
    end
    
    % inter stim interval
    if params.DOopto==1

        start2 = now*86400;
        now2= now*86400;
        while (now2-start2)<.25
            now2=now*86400;
        end

        if rem(trl,2)==0
            opto=params.Oon;
        else
            opto=params.Ooff;
        end

        session.outputSingleScan([0,opto]);

        start2 = now*86400;
        now2= now*86400;
        while (now2-start2)<.25
            now2=now*86400;
        end
    else
        opto=0;
    end

    now=now*86400;
    while (now-start1)<(params.pauseTime+(rand(1,1))/20)
        now=now*86400;
    end
    
    % talk to arduino here
    params.arduino.message_back = talk_to_arduino(params.arduino.com_port, params.arduino.serial_trial(ang));
    if params.arduino.message_back ~= params.arduino.serial_arduino_ready
        error('Did not connect to arduino correctly, in script');
    end
    
    Screen('Flip',params.win);
    start = now*86400;
    now=now*86400;
    
    while (now-start)< params.displayTime
        now=now*86400;
        Screen('DrawTexture', params.win, tex(ang));
        Screen('Flip',params.win);
        session.outputSingleScan([ang,opto]);
    end
    session.outputSingleScan([0,opto]);

    Screen('FillRect', params.win, [params.isicolor params.isicolor params.isicolor], params.rect);
    Screen('Flip',params.win);
    Screen('FillRect', params.win, [params.isicolor params.isicolor params.isicolor], params.rect);
    Screen('Flip',params.win);
    
    trialrecord(trl,1)=ang;
    trialrecord(trl,2)=now*86400-start1;
    fprintf('; Angle %d\n', ang);
end

fprintf('deviants fraction: %d\n', sum(trialrecord(:,1)==2)/trl);

% pause between paradigms
pause_start = now*86400;
pause_now=now*86400;
while (pause_now-pause_start) < 2
    pause_now=now*86400;
end




end