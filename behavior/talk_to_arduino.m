function message = talk_to_arduino(session, send_key)
% this sends a message to arduino and waits for something back
message = 0;

% send a string message
fprintf(session,'%s',char(send_key));

while message == 0
    if session.BytesAvailable
        message = fscanf(session, '%s');
    end
end

end