function zapit_com_bytes = gen_Zapit_byte_tuple(trial_state_command, arg_keys_dict, arg_values_dict)
    % Generate a byte tuple to communicate with Zapit device.
    %
    % function [zapit_com_bytes, zapit_com_ints] = zapit_tcp_bridge.gen_Zapit_byte_tuple(trial_state_command, arg_keys_dict, arg_values_dict)
    %
    % Purpose
    % Generate message to send to Zapit:
    % 0. Value of 1 indicating the message is to start stimulating by calling the sendSamples function
    % 1. Bitmask indicating which keys to pass as arguments to sendSamples
    % 2. Bitmask indicating the boolean values of the key-value pairs given to sendSamples
    % 3. Byte indicating the condition number to pass to sendSamples
    %
    % Inputs
    % trial_state_command
    % arg_keys_dict
    % arg_values_dict
    %
    % Outputs
    % zapit_com_bytes - 4 byte message to send to Zapit (see above)
    %
    %
    % Example
    % Zapit_byte_tuple = gen_Zapit_byte_tuple(1, containers.Map({'conditionNum', 'laser', 'hardwareTriggered', 'logging', 'verbose'}, {false, false, true, true, true}), containers.Map({'conditionNum', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {101, true, false, false, true}))
    %
    % Peter Vincent - SWC, 2023

    %% Get dictionary maps from class

    % Get constant maps
    keys_to_int_dict =  zapit_tcp_bridge.constants.sendSamples_arg_int_dict;
    t_arg_values_keys =  zapit_tcp_bridge.constants.sendSamples_val_int_dict;



    % Sum arg_keys_dict (input argument) ints and convert to byte
    arg_keys_int = 0;
    NEW = 0; % TODO: delete
    %arg_keys_dict.values
    %arg_keys_dict.keys
    for arg = keys(arg_keys_dict)
        arg = arg{1}; % Extract string from cell
        tValue = arg_keys_dict(arg);
        arg_keys_int = arg_keys_int + tValue * keys_to_int_dict(arg);
    end

    % Sum arg_value_dict (input argument) ints and convert to byte
    arg_values_int = 0;
    arg_values_dict.values;
    arg_values_dict.keys;
    for arg = keys(arg_values_dict)
        arg = arg{1}; % Extract string from cell
        tValue = arg_values_dict(arg);
        try
            arg_values_int = arg_values_int + tValue * t_arg_values_keys(arg);
        catch ME
            ME
            % do nothing
        end
    end
    %arg_values_int=nan;

    % Define trial states where we will query Zapit
    trial_state_ints = [2, 3, 4, 1, 0];
    trial_state_strings =  {'stimConfLoaded', 'return_state', 'numCondition', 'sendsamples', 'stopoptostim'};
    trial_state_commands_dict = containers.Map(trial_state_ints, trial_state_strings);


    % If true, extract condition number and convert to byte
    if arg_keys_dict('conditionNumber') == true
        conditionNum_int = arg_values_dict('conditionNumber');
    else
        conditionNum_int = 255;
    end



    if strcmpi(trial_state_commands_dict(trial_state_command), 'sendsamples')
        % Send arguments along with message ID if we are doing "sendsamples"
        zapit_com_bytes = uint8([trial_state_command, arg_keys_int, arg_values_int, conditionNum_int]);
    else
        zapit_com_bytes = uint8([state_command_byte, 0,0 , 0]);
    end

end
