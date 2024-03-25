# Zapit TCP/IP comms Bonsai demo 

## Before you start
1. The `Extensions` folder should be in the same directory as the `Bonsai_Demo` file.
2. You should have started Zapit with the "tcpServer" "enable" setting being "true" in the YML settings file.

## Available commands 
The Bonsai TCP client makes available the following commands that interface with the Zapit server. 

* `Stop_Optostim`
* `Stim_Conf_Loaded`
* `Get_State`
* `Get_Num_Conditions`
* `Send_Samples`

Only `sendSamples` accepts input arguments. 
The remaining commands are run without input arguments.


### Connection between a Zapit server and MATLAB client on the same machine
By default the IP address on the Zapit server and client is `localhost`, meaning that communications happen on the local machine and not over the network. 
Here we communicate between Zapit and a Bonsai client running on the local machine. 

We will start Zapit in simulated mode and "calibrate" in MATLAB.

```matlab
>> start_zapit('simulated',true)

% "calibrate" stereotaxic coords
>> hZP.applyUnityStereotaxicCalib

% Show that no client is currently connected
>> hZP.tcpServer.isClientConnected
No client is connected to the TCP server
```


You will now start the TCP/IP client on the local machine. 
To do this, open the `Bonsai` workflow. For this example, we will reuire:
- the `Demo_Variables` workflow
- the `Zapit_Client_IO` workflow
- the `Extensions` folder (in this same repository) 

Start by importing all of these modules into your workflow. These can be accessed thorugh the search bar on the top left, then pressing `Enter` (or double clicking on them).

To establish a connection, you will have to send a message to the server via the `Connect` workflow. One really simple way of achieving this is by importing the `Connect` node,  placing it inside a SelectMany and triggerring it with a KeyDown such a `C` (see example below).
To check that everything is working properly, import and visualise the `Server_Reply` Subscribe_Subject (think of this simply as a variable). Upon trigerring the `Connect` node succesfully, the server should reply: `(Connected, (1, 1))`

Since Zapit has just started, there is no loaded stimulus configuration. So, if you import and trigger the `Stim_Conf_Loaded?` node (wth method of your choice), the `Server_Reply` should print: `(2023-09-29 16:04:04.458000, (0, 255))`. Similarly, the number of conditions is zero. So trigerring the `Get_Num_Conditions?` should yield: `(2023-09-29 16:04:04.458000, (0, 255))`

Now we will load an example stimulus set through MATLAB (or you can use the GUI to load one of your choosing).
```matlab
pathToExample = fullfile(zapit.updater.getInstallPath,'examples','example_stimulus_config_files');
exampleFiles = dir(fullfile(pathToExample,'*.yml'));
hZP.loadStimConfig(fullfile(pathToExample,exampleFiles(1).name))
```
Let's verify that it loaded in MATLAB.
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



Now triggering the `Stim_Conf_Loaded?` and `Get_Num_Conditions?` should yield `(2023-09-29 16:04:04.458000, (1, 255))` and `(2023-09-29 16:04:04.458000, (1, 255))` respectively.

We can then initiate stimulus delivery using `Send_Samples` on the client. By clicking on the node, we can set the parameters:

```matlab
hardwareTriggered_channel = False
hardwareTriggered_ON = False
condition_Num_channel = True
conditionNum = 2
```

In which case the server should return `(2023-09-29 16:04:04.458000, (2, 1))`. We can stop stimulation by triggering the `Stop_Optostim` node, which should return `(2023-09-29 16:04:04.458000, (1, 255))`.

When finished you disconnect the client using the `Disconnect` node. Triggering this should yield `(Disconnected, (0, 0))`.