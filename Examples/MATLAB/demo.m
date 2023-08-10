%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                   %%
%%%  Matlab TCP Demonstration script  %%
%%%                                   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This demo contains two examples. For these to work:
% 1. The MATLAB folder from this repo must be in your path.
% 2. You should have started Zapit with the "tcpServer" "enable" setting being "true" in
%    the YML settings file.
%
% Code by Quentin Pajot-Moric and Rob Campbell, SWC 2023


% First we will import the client and associated code from the
% zapit_tcp_bridge package (i.e. the "+" directory) in this repo.
import zapit_tcp_bridge.*


%% ONE
%% Generate the Zapit_byte_tuple: a vector of length 4 that is the message
keys_bitmask = containers.Map({'conditionNumber', 'laserOn', 'hardwareTriggered', 'logging', 'verbose'}, {true, true, false, false, false});
values_bitmask = containers.Map({'conditionNumber_INT', 'laserOn_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {4, true, false, false, false});
zapit_byte_tuple = gen_Zapit_byte_tuple(1, keys_bitmask, values_bitmask)


%% Communicate with Zapit

% Create an instance of the TCPclient class
client = TCPclient;

% Call the connect method to establish a connection with the server
client.connect

% Call the send_receive method to send the zapit_byte_tuple to the server
% and receive a response
response = client.send_receive(zapit_byte_tuple);
disp(response)
% Call the close method to close the connection
client.close()

% Call the instance of the class to trigger the del method for extra
% security
delete(client)

%% Parse the response
parsed_response = parse_server_response(zapit_byte_tuple, ...
                                        response{1}, ...
                                        response{2}, ...
                                        [response{3:4}]);
disp(parsed_response);



%% TWO: In a single step
keys_bitmask = containers.Map({'conditionNum', 'laser', 'hardwareTriggered', 'logging', 'verbose'}, {true, true, false, false, false});
values_bitmask = containers.Map({'conditionNumber_INT', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {4, true, false, false, false});
zapit_byte_tuple = gen_Zapit_byte_tuple(1, keys_bitmask, values_bitmask);

client = TCPclient;
client.connect;
response = client.send_receive(zapit_byte_tuple);
client.close()
delete(client)
parsed_response = parse_server_response(zapit_byte_tuple, ...
                                        response{1}, ...
                                        response{2}, ...
                                        [response{3:4}]);
