function date_float = datetime_to_float()
% Get the current date and time as a datetime object
current_date = datetime('now');

% Convert the datetime object to a floating-point number representing the number
% of days since January 0, 0000 (a.k.a. the "datenum" format) and store it as a
% single precision floating-point number.
date_float = datenum(current_date);
end

