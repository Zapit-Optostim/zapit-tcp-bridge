function [status, server_response_ints] = parse_server_response(zapit_byte_tuple, datetime_double, message_type_byte, response_byte_tuple)
    % Parse Zapit TCP server response
    %
    % function [status, server_response_ints] = zapit_tcp_bridge.parse_server_response(zapit_byte_tuple, datetime_double, message_type_byte, response_byte_tuple)
    %
    % Purpose
    % Parse Zapit TCP/IP server response and return it as a tuple with a datetime string
    % and a tuple of integers representing the response of Zapit.
    %
    % Inputs
    % zapit_byte_tuple
    % datetime_double
    % message_type_byte
    % response_byte_tuple
    %
    % Outputs
    % status
    % server_response_ints
    %
    % Example
    % [status, server_response_ints] = parse_server_response([uint8([1, 30, 18, 101])], 7.389696634347740e+05, uint8(1), [uint8(1), uint8(2)])
    %
    %
    % Peter Vincent - SWC, 2023

    % convert response_byte_tuple to a tuple of integers
    server_response_ints = double(response_byte_tuple);

    if datetime_double == -1
        status = 'Error';
    elseif datetime_double == 1
        status = 'Connected';
    else
        datetime_str = zapit_tcp_bridge.datetime_float_to_str(datetime_double);
        % Check that Zapit is responding to the right message_type (e.g. sendSamples)
        if message_type_byte ~= zapit_byte_tuple{1}
            status = 'Mismatch';
        else
            status = datetime_str;
        end
    end

end

