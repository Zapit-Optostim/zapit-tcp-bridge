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
        end


        function delete(obj)
            close(obj)
        end % Destructor


        % The following are basically wrappers that send common messages
        % Note: there must be a constant property in zapit_tcp_bridge.messages
        % that has the same name as the function.

        function reply = stopOptoStim(obj)
            reply = obj.runWrapper;
        end


        function reply = stimConfigLoaded(obj)
            reply = obj.runWrapper;
        end


        function reply = getState(obj)
            % TODO -- this returns a single right now...
            reply = obj.runWrapper;
        end


        function reply = getNumConditions(obj)
            reply = obj.runWrapper;
        end


        % The wrapper for sendSamples is more complicated because it needs to handle
        % multiple optional input arguments. These need to match what is in the
        % sendSamples method in zapit.pointer.

        function [conditionNumber,laserOn,reply] = sendSamples(obj,varargin)
            % Inputs [param/value pairs]
            % 'conditionNum' - Integer but empty by default. This is the index of the
            %               condition number to present. If empty or -1 a random one is
            %               chosen.
            % 'laserOn' - [bool, true by default] If true the laser is on. If false the
            %             galvos move but the laser is off. If empty or -1, a random laser
            %             state is chosen.
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

            % Create "blank" templates for the keys and the values bitmasks
            out = zapit_tcp_bridge.constants.sendSamples_arg_int_dict;
            arg_bitmask = containers.Map(out.keys, repmat({false},1,length(out.keys)));

            out = zapit_tcp_bridge.constants.sendSamples_val_int_dict;
            values_bitmask = containers.Map(out.keys, repmat(0,1,length(out.keys)));


            % Now we go through and modify the above based on what the user has asked for.
            tKeys = out.keys;
            for ii = 1:length(tKeys)
                if isempty(params.Results.(tKeys{ii}))
                    continue
                end
                arg_bitmask(tKeys{ii}) = true;
                values_bitmask(tKeys{ii}) = params.Results.(tKeys{ii});
            end

            messageToSend = zapit_tcp_bridge.gen_Zapit_byte_tuple(1, arg_bitmask, values_bitmask);

            reply = obj.send_receive(messageToSend);

            if reply.success==1
                conditionNumber = reply.response_tuple(1);
                laserOn = reply.response_tuple(2);
            else
                conditionNumber = -1;
                laserOn = -1;
            end

        end



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

    end

end % TCPclient
