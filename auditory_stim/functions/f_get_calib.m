function ops = f_get_calib(freqs_in, ops)

ops.using_calib_data = 0;
if ops.use_calib
    if exist([ops.calib_path, ops.calib_fname, '.mat'], 'file')
        calib_data = load([ops.calib_path, ops.calib_fname]);
        ops.using_calib_data = 1;
    end
end
if ops.using_calib_data
    ops.modulation_amp_calib = zeros(numel(freqs_in),1);
    ops.calib_pred_volt = zeros(numel(freqs_in),1);
    amp_in = (0:0.01:10);
    [freq_X, amp_Y] = meshgrid(freqs_in/1000, amp_in);
    XY = [reshape(freq_X,[],1), reshape(amp_Y,[],1)];

    mod_amp_all = calib_data.calib.fit_frq_amp(XY);

    for n_freq = 1:numel(freqs_in)
        idx1 = XY(:,1) == freqs_in(n_freq)/1000;
        mod_amp2 = mod_amp_all(idx1);
        [~, min_idx] = min(abs(mod_amp2 - ops.target_db));
        XY2 = XY(idx1,:);
        ops.modulation_amp_calib(n_freq) = XY2(min_idx,2);
        
        ops.calib_pred_volt(n_freq) = mod_amp2(min_idx);
        
    end
else
    ops.modulation_amp_calib = ones(numel(freqs_in),1)*ops.modulation_amp;
end


end