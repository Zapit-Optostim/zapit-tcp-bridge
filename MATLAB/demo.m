%%%%% MATLAB TCP Demonstration Code
addpath('C:\Users\Psychophysics\Desktop\Zapit_Proj\zapit\zapit\')
start_zapit('simulated', true)
hZP.refPointsSample = hZP.refPointsStereotaxic;
hZP.loadStimConfig('C:\Users\Psychophysics\Desktop\Zapit_Proj\zapit\examples\example_stimulus_config_files\uniAndBilateral_5_conditions.yml')

%% Generate the Zapit_byte_tuple
Zapit_byte_tuple = gen_Zapit_byte_tuple(1, ...
                                        containers.Map({'conditionNum_channel', 'laser_channel', 'hardwareTriggered_channel', 'logging_channel', 'verbose_channel'}, {true, true, false, false, false}), ...
                                        containers.Map({'conditionNum', 'laser_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {4, true, false, false, false}));





%% Create an instance of the TCPClient class using the constructor, which takes optional parameter-value pairs

% Add relevant path here
addpath('C:\Users\Psychophysics\Desktop\Zapit_Proj\zapit\zapit\')

import zapit.interfaces.TCPclient;

%

% This creates a TCPclient object named client with the IP address set to 'localhost' and the port number set to 1488.

%% Call the connect method on this object by simply typing:
import zapit.interfaces.TCPclient;
client = TCPclient;
client.connect();