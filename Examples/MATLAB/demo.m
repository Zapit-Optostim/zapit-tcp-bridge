%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                                   %%
%%%  Matlab TCP Demonstration script  %%
%%%                                   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This demo contains two examples. For these to work, the MATLAB
% folder in this repo must be in your path.


% First we will import the client and associated code from the
% zapit_tcp_bridge package (i.e. the "+" directory) in this repo.
import zapit_tcp_bridge


%% ONE
%% Generate the Zapit_byte_tuple
zapit_byte_tuple = gen_Zapit_byte_tuple(1, ...
                                        containers.Map({'conditionNum_channel', 'laser_channel', 'hardwareTriggered_channel', 'logging_channel', 'verbose_channel'}, {true, true, false, false, false}), ...
                                        containers.Map({'conditionNum', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {4, true, false, false, false}));
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

zapit_byte_tuple = gen_Zapit_byte_tuple(1, ...
                                        containers.Map({'conditionNum_channel', 'laser_channel', 'hardwareTriggered_channel', 'logging_channel', 'verbose_channel'}, {true, true, false, false, false}), ...
                                        containers.Map({'conditionNum', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {4, true, false, false, false}));
client = TCPclient;
client.connect;
response = client.send_receive(zapit_byte_tuple);
client.close()
delete(client)
parsed_response = parse_server_response(zapit_byte_tuple, ...
                                        response{1}, ...
                                        response{2}, ...
                                        [response{3:4}]);
