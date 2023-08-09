function [zapit_com_bytes, zapit_com_ints] = gen_Zapit_byte_tuple(trial_state_command, arg_keys_dict, arg_values_dict)
    % Generate a byte tuple to communicate with Zapit device.
    %
    % function [zapit_com_bytes, zapit_com_ints] = zapit_tcp_bridge.gen_Zapit_byte_tuple(trial_state_command, arg_keys_dict, arg_values_dict)
    %
    % Purpose
    %
    %
    % Inputs
    % trial_state_command
    % arg_keys_dict
    % arg_values_dict
    %
    % Outputs
    % zapit_com_bytes
    % zapit_com_ints
    %
    %
    % Example
    % Zapit_byte_tuple = gen_Zapit_byte_tuple(1, containers.Map({'conditionNum_channel', 'laser_channel', 'hardwareTriggered_channel', 'logging_channel', 'verbose_channel'}, {false, false, true, true, true}), containers.Map({'conditionNum', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {101, true, false, false, true}))
    %
    % Peter Vincent - SWC, 2023


    % Anon function to generate series: 1, 2, 4, 8, 16, 32 ...
    % based on the length of a vector.
    p_series = @(x)  2.^(0:length(x)-1);


    %% Build Maps

    % Map arg_keys_dict to ints
    t_arg_keys = {'conditionNum_channel', ...       % 1
                  'laser_channel', ...              % 2
                  'hardwareTriggered_channel', ...  % 4
                  'logging_channel', ...            % 8
                  'verbose_channel'};               % 16

    keys_to_int_dict = containers.Map(t_arg_keys,  p_series(t_arg_keys));


    % Map arg_values_dict to ints
    t_arg_values_keys = {'conditionNum', ...          % 1
                         'laser_ON', ...              % 2
                         'hardwareTriggered_ON', ...  % 4
                         'logging_ON', ...            % 8
                         'verbose_ON'}                % 16

    bool_values_to_int_dict = containers.Map(t_arg_values_keys, p_series(t_arg_values_keys));



    % Map True/False boolean values to 1/0
    bool_to_int_dict = containers.Map({true, false}, [1, 0]);


    % Sum arg_keys_dict (input argument) ints and convert to byte
    arg_keys_int = 0;
    for arg = keys(arg_keys_dict)
        key = arg_keys_dict(arg{1});
        arg_keys_int = arg_keys_int + bool_to_int_dict(key) * keys_to_int_dict(arg{1});
        arg_keys_byte = uint8(arg_keys_int);
    end


    % Sum arg_value_dict (input argument) ints and convert to byte
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


    % Define trial states where Python will query Zapit
    trial_state_ints = [2, 3, 4, 1, 0];
    trial_state_strings =  {'stimConfLoaded', 'return_state', 'numCondition', 'sendsamples', 'stopoptostim'};
    trial_state_commands_dict = containers.Map(trial_state_ints, trial_state_strings);


    % Convert state_command to byte
    state_command_byte = uint8(trial_state_command);


    % If true, extract condition number and convert to byte
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
        %zapit_com_ints = {trial_state_command, arg_keys_int, arg_values_int, conditionNum_int}; % TODO
    else
        zapit_com_bytes = {state_command_byte, uint8(0), uint8(0), uint8(0)};
        %zapit_com_ints = {trial_state_command, 0, 0, 0}; %TODO
    end

end
