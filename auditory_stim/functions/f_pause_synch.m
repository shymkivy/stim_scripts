function f_pause_synch(pause_time, session, synch, volt_cmd)
    
LED_on = 3; %foltage. if diameter of light circle is 1mm, then use 1.5.
%if .8mm, use 1.23. these give about 4mw/mm2. 1=1.59mw. 1.23=2.00mw 1.5=2.35mw. 2=3.17. 2.5=3.93. 3=4.67. 3.5=5.36 4=6.05

% synch artifact
if synch
    pause((pause_time - 1)/2);
    volt_cmd(2) = LED_on;
    session.outputSingleScan(volt_cmd);
    pause(1);
    volt_cmd(2) = 0;
    session.outputSingleScan(volt_cmd);
    pause((pause_time - 1)/2);
else
    pause(pause_time);
end

end
