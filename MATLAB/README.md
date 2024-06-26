# Zapit TCP/IP Comms Demo 

## Before you start
1. The MATLAB folder from this repo must be in the MATLAB path on the client PC. **DO NOT "ADD WITH SUB-FOLDERS"!!**
2. You should have started Zapit with the `tcpServer` `enable` setting being `true` in the YML settings file.

## Available commands 
The TCP client makes available the following commands that interface with the Zapit server. 

* `client.stopOptoStim`
* `client.stimConfigLoaded`
* `client.getState`
* `client.getNumConditions`
* `client.sendSamples`

Where `client` is an instance of `zapit_tcp_bridge.TCPclient` (see examples below).
Only `sendSamples` accepts input arguments. 
The remaining commands are run without input arguments.
For help see, for example, `help zapit_tcp_bridge.TCPclient.sendSamples`.


### Connection between a Zapit server and MATLAB client on the same machine
By default the IP address on the Zapit server and client is `localhost`, meaning that communications happen on the local machine and not over the network. 
Here we communicate between Zapit and a MATLAB client running on the local machine. 

We will start Zapit in simulated mode and "calibrate".

```matlab
>> start_zapit('simulated',true)

% "calibrate" stereotaxic coords
>> hZP.applyUnityStereotaxicCalib

% Show that no client is currently connected
>> hZP.tcpServer.isClientConnected
No client is connected to the TCP server
```


You will now start the TCP/IP client on the local machine. 
This can be done in the same instance of MATLAB or in a new one

```matlab
>> client = zapit_tcp_bridge.TCPclient;
>> client.connect;
```

And the server reports that a client is connected
```matlab
>> hZP.tcpServer.isClientConnected
Client is connected to the TCP server
```

Since Zapit has just started, there is no loaded stimulus configuration. 

```matlab

>> client.stimConfigLoaded

ans =

  single

     0
```

and so the number of conditions is zero:
```matlab
>> client.getNumConditions

ans =

  single

     0
```


Now we will load an example stimulus set (or you can use the GUI to load on of your choosing).
```matlab
pathToExample = fullfile(zapit.updater.getInstallPath,'examples','example_stimulus_config_files');
exampleFiles = dir(fullfile(pathToExample,'*.yml'));
hZP.loadStimConfig(fullfile(pathToExample,exampleFiles(1).name))
```

Verify it loaded a stimulus config
```matlab
>> hZP.stimConfig

ans = 

  stimConfig with properties:

            configFileName: 'C:\zapit\examples\example_stimulus_config_files\uniAndBilateral_5_conditions.yml'
            laserPowerInMW: 5
      stimModulationFreqHz: 40
             stimLocations: [1×5 struct]
    offRampDownDuration_ms: 250
               chanSamples: [25000×4×5 double]
```

Running the two client commands again, shows us that a stimulus config file is loaded and that it has 5 conditions.

```matlab
>> client.stimConfigLoaded

ans =
  single
     1

>> client.getNumConditions

ans =
  single
     5
```


We can then initiate stimulus delivery using `sendSamples` on the client in the same way
as we would normally:
```matlab
% A random stimulus is chosen. The first two outputs report back which stimulus was presented
% an whether or not the laser was on
>> [C,L]=client.sendSamples('hardwareTriggered',false)

C =
  uint8
   4

L =
  uint8
   1

>> [C,L]=client.sendSamples('hardwareTriggered',false)

C =
  uint8
   3

L =
  uint8
   1

```

NOTE: In the above example we switch from on randomly chosen condition to another immediately without ramping down.
The stimuli run continuously until instructed otherwise. 
Of course you can specify particular stimulus conditions and stop stimulation on demand:
```
% Note the command accepts truncated parameter names. Here "cond" instead of "conditionNum".
>> [C,L]=client.sendSamples('hardwareTriggered',false,'cond',2)

C =
  uint8
   2

L =
  uint8
   1

>> client.stopOptoStim

ans =
  single
     1
```

Finally, you can specify conditions of a particular duration and optional start delay defined in seconds. 
```
% Note the command accepts truncated parameter names. Here "cond" instead of "conditionNum".
>> [C,L]=client.sendSamples('hardwareTrig',true,'cond',2,'startDelay',0.25,'stimDuration',1);
```

In the above scenario the rampdown happens at the end of the stimulus. 
There is no need to call `stopOptoStim`.


When finished you disconnect the client as follows:
```matlab
>> delete(client)
```


### Connection between a Zapit server and MATLAB client on a different machine
The client can run on any PC on the same network. 
Although the Zapit server must be running on a Windows to PC in order for the stimulation to work, the client could be on a Linux or Mac OS system. 
To connect to the Windows PC you will need its IP address, which you can obtain as follows:

```matlab
>> zapit.interfaces.getIPaddress
1. Ethernet adapter Ethernet: 172.24.243.155
2. Ethernet adapter vEthernet (WSL): 172.18.128.1
```

You must now enter the IP address into the Zapit YAML file. e.g.

```yaml
tcpServer: {IP: 172.24.243.155, port: 1488.0, enable: true}
```

Now start Zapit (in this case in simulated mode as above) and "calibrate".
A Windows firewall message may appear. 
You should allow the connection.

```matlab
start_zapit('simulated',true)

% "calibrate" stereotaxic coords
hZP.applyUnityStereotaxicCalib
```

Now start the client on the remote PC, entering the IP address:

```matlab
client = zapit_tcp_bridge.TCPclient('ip','172.24.243.155');
client.connect;
```

Load a stimulus config in Zapit and confirm you can access the information correctly on the remote PC:
```
>> client.getNumConditions

ans =
  single
     5
```


When finished you disconnect the client as folllows.
```matlab
>> delete(client)
```

