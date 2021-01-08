function f_RZ6_CP_play(RP, sig)

% size of the entire serial buffer
npts = RP.GetTagSize('data_play');
% should be same size
% npts = RP.GetTagSize('data_rec');  

% serial buffer will be divided into two buffers A & B
bufpts = npts/2; 

sig_size = length(sig);
if rem(ceil(sig_size / bufpts),2) == 1
    % add another buffer of zeros, to prevent error
    sig = [sig, zeros(1, bufpts)];
    sig_size = length(sig);
end

%%

% load up entire buffer with segments A and B
RP.WriteTagVEX('data_play', 0, 'F32', sig(1:npts));
index_start = npts+1;

%% start playing and recording
RP.SoftTrg(1);
curindex = RP.GetTagVal('index_A_play');
%disp(['Current buffer index: ' num2str(curindex)]);


%% main looping section
while index_start < sig_size

    % wait until done playing and writing A
    while(curindex < bufpts)
        curindex = RP.GetTagVal('index_A_play');
        %pause(.05);
    end
    
    % load the next signal segment
    index_end = min(index_start+bufpts-1, sig_size);
    RP.WriteTagVEX('data_play', 0, 'F32', sig(index_start:index_end));
    index_start = index_end+1;


    % checks to see if the data transfer rate is fast enough
    curindex = RP.GetTagVal('index_A_play');
    if(curindex < bufpts)
        warning('Transfer rate is too slow');
    end

    % wait until start playing A 
    while(curindex > bufpts)
        curindex = RP.GetTagVal('index_A_play');
        %pause(.05);
    end

    % load segment B
    index_end = min(index_start+bufpts-1, sig_size);
    RP.WriteTagVEX('data_play', bufpts, 'F32', sig(index_start:index_end));
    index_start = index_end+1;


    % make sure we're still playing A 
    curindex = RP.GetTagVal('index_A_play');
    if(curindex > bufpts)
        warning('Transfer rate too slow');
    end
end
% stop playing
RP.SoftTrg(2);


end