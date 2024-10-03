function data = f_RZ6_acquire_sound(RP, fs, duration)

npts = RP.GetTagSize('dataout');

bufpts = npts/2; 

% record approximately the given duration
data = zeros(ceil(round(duration*fs)/bufpts)*bufpts,1);
sig_size = numel(data);
if rem(ceil(sig_size / bufpts),2) == 1
    % add another buffer of zeros, to prevent error
    data = [data; zeros(bufpts,1)];
    sig_size = length(data);
end

% waitA_all = [];
% waitB_all = [];
% catchIdxA = [];
% catchIdxB = [];

% resest index
RP.SoftTrg(3);

index_start = 1;
index_end = min(index_start+bufpts-1, sig_size);

RP.SoftTrg(1);
%curindex = RP.GetTagVal('index');

%% main looping section
while index_start < sig_size
    curindex = RP.GetTagVal('index');
    %catchIdxA = [catchIdxA, curindex];
    % wait until done playing and writing A
    %waitA = 0;
    while(curindex < bufpts)
        curindex = RP.GetTagVal('index');
        %waitA = waitA + 1;
    end
    %waitA_all = [waitA_all, waitA];
    % read segment A and save
    noise = RP.ReadTagVEX('dataout', 0, bufpts, 'F32', 'F32', 1);
    data(index_start:index_end) = noise;
    %fwrite(fnoise,noise,'float32');
    
    index_start = index_end+1;
    index_end = min(index_start+bufpts-1, sig_size);
    
    curindex = RP.GetTagVal('index');
    %catchIdxB = [catchIdxB, curindex];
    % wait until start playing A 
    %waitB = 0;
    while(curindex > bufpts)
        curindex = RP.GetTagVal('index');
        %waitB = waitB + 1;
    end
    %waitB_all = [waitB_all, waitB];

    % read segment B
    noise2 = RP.ReadTagVEX('dataout', bufpts, bufpts, 'F32', 'F32', 1);
    data(index_start:index_end) = noise2;
    %fwrite(fnoise,noise,'float32');
    
    index_start = index_end+1;
    index_end = min(index_start+bufpts-1, sig_size);
end

% stop playing
RP.SoftTrg(2);

% figure();
% plot(data)

end