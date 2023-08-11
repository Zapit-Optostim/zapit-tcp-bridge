classdef constants
    % Abstract class that defines standard messages, dictionaries, and constants
    % See the TCPclient class for use
    properties (Constant=true)

        % The following are standard messages to Zapit that are used by wrappers
        % in the TCPclient class
        stopOptoStim = [0,0,0,0]
        stimConfigLoaded = [2,0,0,0]
        getState = [3,0,0,0]
        getNumConditions = [4,0,0,0]

        % Anonymous function for generating the power series needed for the
        % bitmask of sendSamples arguments and values
        pSeries = @(x) 2.^(0:length(x)-1);
    end

    methods (Static)

        function out = sendSamples_arg_int_dict
            % Convert sendSamples input arguments to integers that to be used
            % for making a bitmask.
            argNames = {'conditionNumber', ...    % 1
                        'laserOn', ...            % 2
                        'hardwareTriggered', ...  % 4
                        'logging', ...            % 8
                        'verbose'};               % 16

            out = containers.Map(argNames, zapit_tcp_bridge.constants.pSeries(argNames));
        end


    end
end
