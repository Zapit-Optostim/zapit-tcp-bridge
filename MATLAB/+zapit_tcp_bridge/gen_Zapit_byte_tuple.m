function [zapit_com_bytes, zapit_com_ints] = gen_Zapit_byte_tuple(trial_state_command, arg_keys_dict, arg_values_dict)
% Generate a byte tuple to communicate with Zapit device.

% map arg_keys_dict to ints
keys_to_int_dict = containers.Map({'conditionNum_channel', 'laser_channel', 'hardwareTriggered_channel', 'logging_channel', 'verbose_channel'}, [1, 2, 4, 8, 16]);

% map arg_values_dict to ints
bool_values_to_int_dict = containers.Map({'conditionNum', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, [1, 2, 4, 8, 16]);

% map True/False boolean values to 1/0
bool_to_int_dict = containers.Map({true, false}, [1, 0]);

% sum arg_keys ints and convert to byte
arg_keys_int = 0;
for arg = keys(arg_keys_dict)
    key = arg_keys_dict(arg{1});
    arg_keys_int = arg_keys_int + bool_to_int_dict(key) * keys_to_int_dict(arg{1});
    arg_keys_byte = uint8(arg_keys_int);
end

% sum arg_value ints and convert to byte
arg_values_int = 0;
for arg = keys(arg_values_dict)
    value = arg_values_dict(arg{1});
    try
        arg_values_int = arg_values_int + bool_to_int_dict(value) * bool_values_to_int_dict(arg{1});
        arg_values_byte = uint8(arg_values_int);
    catch
        % do nothing
    end
end

% define trial states where python will query zapit
trial_state_commands_dict = containers.Map([2, 3, 4, 1, 0], {'stimConfLoaded', 'return_state', 'numCondition', 'sendsamples', 'stopoptostim'});

% convert state_command to byte
state_command_byte = uint8(trial_state_command);

% if True, extract condition nb and convert to byte
if arg_keys_dict('conditionNum_channel') == true
    conditionNum_int = arg_values_dict('conditionNum');
    conditionNum_byte = uint8(conditionNum_int);
else
    conditionNum_int = 255;
    conditionNum_byte = uint8(conditionNum_int);
end

if strcmpi(trial_state_commands_dict(trial_state_command), 'sendsamples')
    % if trial_state_command = "sendsamples"
    zapit_com_bytes = {state_command_byte, arg_keys_byte, arg_values_byte, conditionNum_byte};
    %zapit_com_ints = {trial_state_command, arg_keys_int, arg_values_int, conditionNum_int};
else
    zapit_com_bytes = {state_command_byte, uint8(0), uint8(0), uint8(0)};
    %zapit_com_ints = {trial_state_command, 0, 0, 0};
end

end

% e.g. call with Zapit_byte_tuple = gen_Zapit_byte_tuple(1, containers.Map({'conditionNum_channel', 'laser_channel', 'hardwareTriggered_channel', 'logging_channel', 'verbose_channel'}, {false, false, true, true, true}), containers.Map({'conditionNum', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {101, true, false, false, true}))

