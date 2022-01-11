function stim_stim_seq = f_get_stim_trials(stim_tag_type, stim_ang, stim_ctx_stdcount)

stim_stim_seq = zeros(size(stim_ang));

if strcmpi(stim_tag_type{1}, 'dev')
    stim_stim_seq = stim_ctx_stdcount(:,1) == 2;
elseif strcmpi(stim_tag_type{1}, 'cont')
    stim_stim_seq = stim_ang == stim_tag_type{2};
elseif strcmpi(stim_tag_type{1}, 'red')
else
    stim_stim_seq = [];
end

end