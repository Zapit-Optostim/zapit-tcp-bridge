function datetime_str = datetime_float_to_str(date_float)
    % Converts a MATLAB datenum value represented as a double-precision floating-point number
    % to a string representation of the date and time in ISO format (YYYY-MM-DD HH:MM:SS).

    % Convert the datenum value to a Unix timestamp
    unix_timestamp = (date_float - 719529) * 86400;

    % Create a datetime object from the Unix timestamp
    datetime_str = datestr(datetime(unix_timestamp, 'ConvertFrom', 'posixtime'), 'yyyy-mm-dd HH:MM:SS');
end

% e.g. call with datetime_str = datetime_float_to_str(7.389696634347740e+05)