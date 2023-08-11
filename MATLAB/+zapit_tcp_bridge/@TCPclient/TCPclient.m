classdef TCPclient < handle

    properties (Hidden)
        listeners
        bytesToRead = 15 % Number of bytes in the message
    end

    properties
        connected
        hSocket % The server or client object will reside here
        port = 1488
        ip = 'localhost'
    end % properties

    properties (SetObservable)
        buffer
    end


    methods

        function obj = TCPclient(varargin)
            % Create a Zapit TCP/IP client connection instance
            %
            % zapit_tcp_bridge.TCPclient
            %
            % Inputs (optional param/val pairs)
            % 'ip' - [string] Is 'localhost' by default (see zapit.interfaces.tcpip)
            % 'port' - [numeric scalar] is 1488 by default
            %
            % Rob Campbell, Peter Vincent - SWC 2023


            params = inputParser;
            params.CaseSensitive = false;

            params.addParameter('ip', obj.ip, @ischar)
            params.addParameter('port', obj.port, @isnumeric)

            params.parse(varargin{:});

            obj.ip = params.Results.ip;
            obj.port = params.Results.port;
            obj.connected = false;


        end % Constructor

        function response = connect(obj)
            % Build the client
            if obj.connected
                % Message to connect whilst already connected
                response = {-1.0,uint8(0),uint8(1),uint8(0)};
                return
            else
                % Message to connect whilst not connected
                obj.hSocket = tcpclient(obj.ip, obj.port);
                % Read all bytes in the message then call then process data with a callback
                configureCallback(obj.hSocket, "byte", obj.bytesToRead, @obj.readDataFcn);
                obj.connected = true;
                response = {1.0,uint8(1),uint8(1),uint8(1)};
                return
            end
        end

        function response = close(obj)
            if obj.connected
                % Message to disconnect whilst connected
                delete(obj.hSocket);
                disp("TCPclient connection closed")
                obj.connected=false;
                response = {-1.0,uint8(1),uint8(0),uint8(0)};
                return
            else
                % Message to disconnect whilst not connected
                response = {-1.0,uint8(0),uint8(1),uint8(0)};
                return
            end
        end % close


        function delete(obj)
            close(obj)
        end % Destructor


        % The following are basically wrappers that send common messages
        % Note: there must be a constant property in zapit_tcp_bridge.messages
        % that has the same name as the function.

        function reply = stopOptoStim(obj)
            % TCP client command to remotely run zapit.pointer.stopOptoStim
            %
            % function zapit_tcp_bridge.TCPclient.stopOptoStim
            %
            % Purpose
            % Runs zapit.pointer.stopOptoStim remotely from the TCP client. This function
            % takes no input arguments and returns just a "1".
            %
            % Inputs
            % none
            %
            % Outputs
            % Returns 1 as a placeholder. Does not signify anything.

            reply = obj.runWrapper;
        end % stopOptoStim


        function reply = stimConfigLoaded(obj)
            % TCP client command to query if a stim config is loaded in Zapit
            %
            % function isLoaded = zapit_tcp_bridge.TCPclient.stimConfigLoaded
            %
            % Purpose
            % Return true if a stimulus configuration file is loaded in the connected
            % instance of Zapit.
            %
            % Inputs
            % none
            %
            % Outputs
            % Returns true if a stim config is loaded. False otherwise.

            reply = obj.runWrapper;
        end % stimConfigLoaded


        function reply = getState(obj)
            % TCP client command to query the state of Zapit
            %
            % function nCond = zapit_tcp_bridge.TCPclient.getState
            %
            % Purpose
            % Returns the state of the Zapit server: 'idle', 'active', or 'rampdown'
            % In the event of an error or an otherwise unknown state, the srting
            % ' UNKNOWN_STATE ' is returned. Note the empty first and last characters.
            %
            % Inputs
            % none
            %
            % Outputs
            % Returns a scalar equal to the number of available stimulus conditions.

            returnVal = obj.runWrapper;

            if returnVal == 255
                reply = ' UNKNOWN_STATE ';
                return
            end

            tDict = containers.Map([0,1,2], {'idle', 'active', 'rampdown'});
            returnVal
            reply = tDict(returnVal);

        end % getState


        function reply = getNumConditions(obj)
            % TCP client command to query the number of available stimulus conditions
            %
            % function nCond = zapit_tcp_bridge.TCPclient.getNumConditions
            %
            % Purpose
            % Returns the number of available stimulus conditions
            %
            % Inputs
            % none
            %
            % Outputs
            % Returns a scalar equal to the number of available stimulus conditions.

            reply = obj.runWrapper;
        end % getNumConditions


        function [conditionNumber,laserOn,reply] = sendSamples(obj,varargin)
            % TCP client command to remotely run zapit.pointer.sendSamples
            %
            % function  [conditionNumber,laserOn,reply] = zapit_tcp_bridge.TCPclient.sendSamples('Param1', value1, ...)
            %
            % Purpose
            % Runs zapit.pointer.sendSamples remotely from the TCP client. This function
            % takes the same input arguments as that in zapit.pointer and returns the same
            % first two outputs. An optional third output returns the full response from
            % the TCP server.
            %
            %
            % Inputs [param/value pairs]
            % 'conditionNum' - Integer but empty by default. This is the index of the
            %               condition number to present. If empty or -1 a random one is
            %               chosen.
            % 'laserOn' - [bool, true by default] If true the laser is on. If false the
            %             galvos move but the laser is off. If empty or -1, a random laser
            %
            % 'hardwareTriggered' [bool, true by default] If true the DAQ waits for a
            %             hardware trigger before presenting the waveforms.
            % 'logging' - [bool, true by default] If true we write log files automatically
            %             if the user has defined a valid directory in zapit.pointer.experimentPath.
            % 'verbose' - [bool, false by default] If true print debug messages to screen.
            %
            %
            % Outputs
            % conditionNumber - the condition that was presented. -1 in event of error
            %                   where nothing was presented.
            % laserOn - bool indicated whether or not the laser was on in this trial. If
            %       error and nothing presented, this returns -1.
            % reply - structure containing the full reply from the TCP/IP comms


            %Parse optional arguments
            params = inputParser;
            params.CaseSensitive = false;
            params.addParameter('conditionNumber', [], @(x) isnumeric(x) && (isscalar(x) || isempty(x) || x == -1));
            params.addParameter('laserOn', [], @(x) isempty(x) || islogical(x) || x == 0 || x == 1 || x == -1);
            params.addParameter('hardwareTriggered', [], @(x) isempty(x) || islogical(x) || x==0 || x==1);
            params.addParameter('logging', [], @(x) isempty(x) || islogical(x) || x==0 || x==1);
            params.addParameter('verbose', [], @(x) isempty(x) || islogical(x) || x==0 || x==1);

            params.parse(varargin{:});

            % Create "blank" template for the values bitmasks
            out = zapit_tcp_bridge.constants.sendSamples_arg_int_dict;
            values_bitmask = containers.Map(out.keys, cell(1,length(out.keys)));


            % Now we go through and modify the above based on what the user has asked for.
            tKeys = out.keys;
            for ii = 1:length(tKeys)
                if isempty(params.Results.(tKeys{ii}))
                    continue
                end
                values_bitmask(tKeys{ii}) = params.Results.(tKeys{ii});
            end

            messageToSend = obj.gen_sendSamples_byte_tuple(values_bitmask);

            reply = obj.send_receive(messageToSend);

            if reply.success==1
                conditionNumber = reply.response_tuple(1);
                laserOn = reply.response_tuple(2);
            else
                conditionNumber = -1;
                laserOn = -1;
            end

        end % sendSamples



        function out = send_receive(obj,bytes_to_send)
            % Sends and receives messages
            %
            % zapit_tcp_bridge.TCPclient.send_receive(bytes_to_send)
            %
            % Purpose
            % Send message to server and read reply.
            % Notes: If first byte is 255 we open the connection.
            %        If first byte is 254 we close the connection
            %
            % Inputs
            % bytes_so_send - vector of length 4 produced by gen_Zapit_byte_tuple, for instance.
            %
            % Outputs
            % out - processed reply from server formatted as a structure:
            %   out.bytes_to_send - a copy of the input argument bytes_to_send
            %   out.datetime - timestamp of the return message
            %   out.message_type - the message type reported by the server
            %   out.response_tuple -
            %   out.success - true/false indicating if the command succeeded
            %   out.statusMessage - string indicating what happened
            %
            % e.g.
            %     bytes_to_send: [1 1 0 2]
            %          datetime: 7.3911e+05
            %      message_type: 1
            %    response_tuple: [2 1 255 255 255 255]
            %           success: 1
            %     statusMessage: 'MessageMatches'


            if length(bytes_to_send) ~= 4
                fprintf('Command message must be 4 bytes long\n')
                return
            end

            % TODO -- what is the idea behind the connection and disconnection codes?
            if bytes_to_send(1) == 255
                reply = obj.connect(obj);
            elseif bytes_to_send(1) == 254
                reply = obj.close(obj);
            elseif (bytes_to_send(1) < 254) && ~obj.connected
                reply = {-1.0,uint8(0),uint8(0),uint8(1)};
                return
            end

            % Sends a command and waits for a response
            obj.sendMessage(bytes_to_send);

            waitfor(obj, 'buffer');

            % Once the reply has been obtained, it is automatically processed by the
            % callback function readDataFcn
            out = obj.buffer;

        end % sendCommand


    end % methods

    methods (Hidden=true)

        function sendMessage(obj, bytes_to_send)
            % Send a message to the server. Adds a new line.
            %
            % zapit_tcp_bridge.TCPclient.sendMessage(bytes_to_send)
            %
            % Purpose
            % Sends a byte string to the server.
            % This should be treated as a lower-level function
            %
            % Inputs
            % bytes_to_send - vector of bytes to send. (uint8)

            % Wipe the buffer
            obj.buffer =  struct('bytes_to_send', bytes_to_send, ...
                                'datetime', -1.0, ...
                                'message_type', uint8(0), ...
                                'response_tuple', repmat(uint8(255), 1,6), ...
                                'success', false, ...
                                'statusMessage', -1);

            write(obj.hSocket, uint8(bytes_to_send));
        end % sendMessage


        function readDataFcn(obj, src, ~)
            % Read all bytes in the message from the buffer
            %
            % The first 8 bytes are a time stamp and are converted to a double
            % Byte 9 is the message type
            % Bytes 10 and 11 are the response itself
            % The remaining four bytes are unused and reserved for future use.

            msg = read(src, obj.bytesToRead, "uint8");

            obj.buffer.datetime = typecast(msg(1:8),'double');
            obj.buffer.message_type = msg(9);
            obj.buffer.response_tuple = msg(10:15);


            if obj.buffer.datetime == -1
                statusMessage = 'Error';
                success = false;
            elseif obj.buffer.datetime == 1
                statusMessage = 'Connected';
                success = true;
            else
                datetime_str = zapit_tcp_bridge.datetime_float_to_str(obj.buffer.datetime);
                % Check that Zapit is responding to the right message_type (e.g. sendSamples)
                if obj.buffer.message_type ~= obj.buffer.bytes_to_send(1)
                    statusMessage = 'Mismatch';
                    success = false;
                else
                    statusMessage = 'MessageMatches';
                    success = true;
                end
            end

            obj.buffer.success = success;
            obj.buffer.statusMessage = statusMessage;
        end % readDataFcn


        function [response,fullReply] = runWrapper(obj)
            % Called by wrapper functions to run a common command
            if ~obj.connected
                reply = [];
                fprintf('Not connected to Server!\n')
                return
            end
            st = dbstack;
            callerMethodName = regexprep(st(end).name,'.*\.','');
            messageToSend = zapit_tcp_bridge.constants.(callerMethodName);
            fullReply = obj.send_receive(messageToSend);
            response = single(fullReply.response_tuple(1));
        end


        function zapit_com_bytes = gen_sendSamples_byte_tuple(obj,arg_values_dict)
            % Generate a byte tuple to communicate with Zapit device.
            %
            % function zapit_com_bytes = gen_sendSamples_byte_tuple(arg_values_dict)
            %
            % Purpose
            % Generate message to send to Zapit for senSamples:
            %
            % Inputs
            % arg_keys_dict
            %
            % Outputs
            % zapit_com_bytes - 4 byte message to send to Zapit (see above)
            %
            %

            % Get constant maps
            keys_to_int_dict =  zapit_tcp_bridge.constants.sendSamples_arg_int_dict;


            % Sum arg_value_dict (input argument) ints and convert to byte
            arg_values_int = 0; % values bitmask
            arg_keys_int = 0;   % keys bitmask

            for arg = keys(keys_to_int_dict)
                arg = arg{1}; % Extract string value from cell array

                % If the key does not exist we skip
                if ~isKey(arg_values_dict,arg)
                    continue
                end

                tValue = arg_values_dict(arg);

                % If the value is empty we don't try to add it to the argument list. Therefore
                % zapit.pointer.sendSamples will just do whatever was the default behavior for
                % for this parameter.
                if isempty(tValue)
                    continue
                end

                if strcmp(arg,'conditionNumber')
                    arg_values_int = arg_values_int + keys_to_int_dict(arg);
                else
                    arg_values_int = arg_values_int + tValue * keys_to_int_dict(arg);
                end

                arg_keys_int = arg_keys_int + keys_to_int_dict(arg);
            end

            % If true, extract condition number and convert to byte
            if isKey(arg_values_dict, 'conditionNumber') && ...
                ~isempty(arg_values_dict('conditionNumber'))
                conditionNum_int = arg_values_dict('conditionNumber');
            else
                conditionNum_int = 255;
            end

            % First byte is 1 because we are doing sendSamples
            zapit_com_bytes = uint8([1, arg_keys_int, arg_values_int, conditionNum_int]);

        end

    end

end % TCPclient
