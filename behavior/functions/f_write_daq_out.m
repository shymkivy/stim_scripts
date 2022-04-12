function f_write_daq_out(session, out_vec, is_old_daq)

if is_old_daq
    session.outputSingleScan(out_vec);
else
    session.write(out_vec);
end

end