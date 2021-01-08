function audio_play(trials, carrier_freq, deviance_prob)

for tr=1:trials
    freq_type = single(rand<deviance_prob) + 1;
    start1 = GetSecs();
    nows=GetSecs();
    % Run audio circuit
    RP.SetTagVal('CarrierFreq', carrier_freq(freq_type));
    while nows<start1+duration;        
        nows=GetSecs();
    end
    % stop audio circuit
    
    disp(tr);
    RP.SetTagVal('CarrierFreq', base_freq);
    % inter stimulus interval
    start2=GetSecs();
    nows=GetSecs();
    while nows<start2+isi;  
        nows=GetSecs();
    end
end

end