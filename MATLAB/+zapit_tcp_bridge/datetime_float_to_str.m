function datetime_str = datetime_float_to_str(date_float)
    % Convert datenum to string in ISO format
    %
    % function datetime_str = zapit_tcp_bridge.datetime_float_to_str(date_float)
    %
    % Purpose
    % Converts a MATLAB datenum value represented as a double-precision floating-point
    % number to a string representation of the date and time in ISO format (YYYY-MM-DD HH:MM:SS).
    %
    %
    % Inputs
    % date_float - datenum value as a float
    %
    % Outputs
    % datetime_str - String representation of the date and time in ISO format.
    %
    % Example
    % datetime_str = datetime_float_to_str(7.389696634347740e+05)
    %
    %
    % Peter Vincent - SWC, 2023

    % Convert the datenum value to a Unix timestamp
    unix_timestamp = (date_float - 719529) * 86400;

    % Create a datetime object from the Unix timestamp
    dTime = datetime(unix_timestamp, 'ConvertFrom', 'posixtime');
    datetime_str = datestr(dTime, 'yyyy-mm-dd HH:MM:SS');

end

