
# 2023/08/10 

## General changes
* Move example code to a dedicated EXAMPLES directory in project root.
* Expand response message to 15 bytes. The four new ones are reserved for future use. Update README.

## Extensive changes to the MATLAB code:
* Placed everything in a package called `zapit_tcp_bridge`
* Create wrapper methods for common tasks in `zapit_tcp_bridge.TCPclient`. The user is expected to call these in general use, rather than `zapit_tcp_bridge.TCPclient.send_receive`, as was originally the case.
  * `stopOptoStim`
  * `stimConfigLoaded`
  * `getState`
  * `getNumConditions`
  * `sendSamples` (which takes the same input arguments as `zapit.pointer.sendSamples` and 
    also returns the same outputs)
* The outward message produced by `gen_Zapit_byte_tuple` is now a vector of bytes rather than a cell array.
* The output of `TCPclient.send_receive` is now a human-readable structure. See `help` of that method.
* Improved modularisation by placing a lot of constants in a class with static properties and methods.
* Moved more code into TCPclient.
* Improved documentation. 
* Updated the MATLAB `demo.m` example, as the code has totally changed. 
* Remove `containers.Map({true, false}, [1, 0]);` from `gen_Zapit_byte_tuple` since MATLAB anyway treats `true` as equal to `1`. So `true*2` equals `2`. 


### Change substantially how the bitmask is generated. 
When started, the process looks like:

```
keys_bitmask = containers.Map({'conditionNumber', 'laserOn', 'hardwareTriggered', 'logging', 'verbose'}, {true, true, false, false, false});
values_bitmask = containers.Map({'conditionNumber_INT', 'laserOn_ON', 'hardwareTriggered_ON', 'logging_ON', 'verbose_ON'}, {4, true, false, false, false});
zapit_byte_tuple = gen_Zapit_byte_tuple(1, keys_bitmask, values_bitmask)
```

There are two issues here:
1. The `keys_bitmask` is defining each input argument according to whether or not it will be supplied. 
It would be easier to simply indicate which are needed and just not mention which are not needed.
2. If we do (1) then we only need one map: the second which links values and arguments. 

To achieve the above it would be easiest to have the keys match the parameter names in `zapit.pointer.sendSamples`.
Once done, we no longer need to type all the above. 
Instead we can:

```
values_bitmask = containers.Map({'conditionNumber', 'laserOn'}, {4, true});
zapit_byte_tuple = gen_Zapit_byte_tuple(1, values_bitmask)
```

This is now done and implemented as `zapit_tcp_bridge.TCPserver.gen_sendSamples_byte_tuple`.
We have removed `gen_Zapit_byte_tuple` as the commands for everything apart from `sendSamples` are now defined by the class `zapit_tcp_bridge.constants`.


# 2023/08/11
Finish polishing the MATLAB code. Add a more complete demo as a markdown file. 
Overhaul docs.

# 2023/08/24
Outward message is now 12 bytes long to allow for stimulus duration and laser power to be sent.
This is done as a pair of signed singles, so each is 4 bytes.
