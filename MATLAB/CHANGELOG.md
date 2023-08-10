
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
