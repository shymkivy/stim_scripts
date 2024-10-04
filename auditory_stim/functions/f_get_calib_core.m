function [mod_volt, pred_db] = f_get_calib_core(freqs_in, fitm, target_db)

num_freqs = numel(freqs_in);

mod_volt = zeros(num_freqs,1);
pred_db = zeros(num_freqs,1);
amp_in = (0:0.01:10);
[freq_X, amp_Y] = meshgrid(freqs_in/1000, amp_in);
XY = [reshape(freq_X,[],1), reshape(amp_Y,[],1)];

mod_amp_all = fitm(XY);

for n_freq = 1:num_freqs
    idx1 = XY(:,1) == freqs_in(n_freq)/1000;
    mod_amp2 = mod_amp_all(idx1);
    [~, min_idx] = min(abs(mod_amp2 - target_db));
    XY2 = XY(idx1,:);
    mod_volt(n_freq) = XY2(min_idx,2);
    pred_db(n_freq) = mod_amp2(min_idx);
end

end