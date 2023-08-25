classdef constants
    % Abstract class that defines standard messages, dictionaries, and constants
    % See the TCPclient class for use
    properties (Constant=true)

        numBytesToRead = 15 % Number of bytes in the message sent by client
        numBytesToSend = 16 % Number of bytes in the message sent back by the server


        % The following are standard messages to Zapit that are used by wrappers
        % in the TCPclient class. The first byte only is specified below.
        % The rest are zeros (length defined by numBytesToSend)
        stopOptoStim = 0;
        stimConfigLoaded = 2;
        getState = 3;
        getNumConditions = 4;

        % Anonymous function for generating the power series needed for the bitmask
        % of sendSamples arguments and values (see sendSamples_arg_int_dict, below).
        pSeries = @(x) 2.^(0:length(x)-1);
    end % properties

    methods (Static)

        function out = sendSamples_arg_int_dict
            % Convert sendSamples input arguments to integers that to be used
            % for making a bitmask. i.e.
            % 1)  00000001
            % 2)  00000010
            % 4)  00000100
            % etc
            %
            %Note these must match the parameter names in zapit.pointer.sendSamples

            argNames = {'conditionNumber', ...     % 1
                        'laserOn', ...             % 2
                        'hardwareTriggered', ...   % 4
                        'logging', ...             % ...
                        'verbose', ...
                        'stimDurationSeconds', ...
                        'laserPower_mw', ...
                        'startDelaySeconds'};

            % NOTE! We have 8 parameters above and can't add more without adding an extra
            % byte to the sent message.

            out = containers.Map(argNames, zapit_tcp_bridge.constants.pSeries(argNames));
        end % sendSamples_arg_int_dict


    end % methods
end % constants
