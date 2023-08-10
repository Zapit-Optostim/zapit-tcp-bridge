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



% start Zapit (must start with TCPserver enabled in YAML)
start_zapit('simulated',true)

% "calibrate" stereotaxic coords
hZP.applyUnityStereotaxicCalib


% Connect to the server
client = zapit_tcp_bridge.TCPclient;
client.connect;


% <<-- IN GUI LOAD A STIM CONFIG -->
% [TODO -- DO IN CODE HERE]

client.getNumConditions

% Note: it auto-completes the parameter names
[C,L,R]=client.sendSamples('laserOn',false,'hardware',true,'cond',3);


delete(client)
