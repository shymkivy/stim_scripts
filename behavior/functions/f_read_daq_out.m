function data = f_read_daq_out(session, is_old_daq)

if is_old_daq
    data = inputSingleScan(session);
else
    data = read(session, "OutputFormat","Matrix");
end

end