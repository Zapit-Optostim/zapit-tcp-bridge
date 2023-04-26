function [status, server_response_ints] = parse_server_response(zapit_byte_tuple, datetime_double, message_type_byte, response_byte_tuple)
    % Parse server response and return a tuple with a datetime string and a tuple of integers representing the response of Zapit.

    % convert response_byte_tuple to a tuple of integers
    server_response_ints = double(response_byte_tuple);

    if datetime_double == -1
        status = 'Error';
    elseif datetime_double == 1
        status = 'Connected';
    else
        datetime_str = datetime_float_to_str(datetime_double);
        if message_type_byte ~= zapit_byte_tuple{1} % check that Zapit is responding to the right message_type (e.g. sendSamples) else throw an error   
            status = 'Mismatch';
        else
            status = datetime_str;
        end
    end
end
% e.g. call with [status, server_response_ints] = parse_server_response([uint8([1, 30, 18, 101])], 7.389696634347740e+05, uint8(1), [uint8(1), uint8(2)])
