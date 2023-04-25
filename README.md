# zapit-tcp-bridge
Bridge for controlling zapit via a TCP connection

## What is this for?
[Zapit](https://github.com/Zapit-Optostim/zapit) is software for running a scanning opto-stim system for head-fixed mouse behaviour, written in MATLAB.  There is additionally a [Python bridge](https://github.com/Zapit-Optostim/zapit-Python-Bridge) that allows the software to be called via Python by wrapping the key MATLAB function calls in Python.

This multi-language support is extended by creating a TCP-IP messaging protocol for Zapit.  A TCP server can be initialised when Zapit is launched.  This can be interfaced with from any language and from different machines on the same network implementing the same protocol.  In this `README.md` we define the protocol, to allow users to implement their own clients in whatever language or context they wish, and additionally provide example clients in Python and in [Bonsai](https://bonsai-rx.org/).  The MATLAB TCP server and an example MATLAB client exists in the main zapit repo in `zapit\+zapit\+interfaces`.  We provide extensive documentation and demonstration scripts for all three languages in this repository.

## The messaging protocol

*memory layout is little-endian*

Experiments interact with Zapit via 5 commands.
Orders
  0. Stop stimulating (`stopOptoStim`)
  1. Start stimulating (`sendSamples`)
Queries
  2. Is a stimulus config loaded? (`stimConfig`)
  3. What is the state of Zapit? (`state`)
  4. How many conditions? (`stimConfig`)
Commands **0**, **2-4** have no arguments and a single return value, whereas command **1** has a variable number of arguments and 2 return values.

### Messages to the server
Messages to the server always consist of **4 bytes**.  The first byte consists of the **command number** (given above).  The remaining bytes are by default set to **0**, and are only used if the command number is **1** (i.e., if we are calling the `sendSamples` method).  In this case, the message structure is as follows:

  0. Value of **1** *indicating the message is to start stimulating by calling the **`sendSamples`** function*
  1. Bitmask indicating which **keys to pass as arguments** to `sendSamples`
  2. Bitmask indicating the **boolean values of the key-value pairs** given to `sendSamples`
  3. Byte indicating the **condition number** to pass to `sendSamples`

Possible arguments to `sendSamples` are **{`conditionNum`, `laserOn`, `hardwareTriggered`, `logging`, `verbose`}**.  Each of the 5 lowest significant bits of **byte 1** in the message corresponds to these arguments, with the bit set to 1 if the key-value pair is to passed of 0 if it is not to be passed.  For example, if we are sending arguments for `conditionNum`, `laserOn` and `logging`, byte 1 will have memory layout `0 0 0 0 1 0 1 1`, for a value of 11 (read the list of keys from right to left to get the position in the byte).  

**Byte 2** in the message carries the values for the key-value pairs that have **boolean values** ({`laserOn`, `hardwareTriggered`, `logging`, `verbose`}), in the same positions as for byte 1.  `conditionNum` has an integer value so is not communicated in this byte.  For example, if we are sending the following key-value pairs 
**{`laserOn`:`true`, `hardwareTriggered`:`true`, `verbose`:`false`}** then **byte 1** would have layout **`0 0 0 1 0 1 1 0`** and **byte 2** would have layout **`0 0 0 0 0 1 1 0`**.

Byte 3 is the uint8 value for `conditionNum` (note this limits the protocol to 256 conditions, but this can easily be extended by the user by adding another byte).

### Replies from the server
Messages from the server always consist of **11 bytes (0 - 10)**.  **Bytes 0-7** represent the status of the message.  If a **1 or -1** it represents either a **successful connection or an error**, respectively.  Otherwise this double represents a **datetime**.  Byte 8 replies with the message byte.  This guarantees that the reply corresponds to the command we sent.

If the command was **0,2-4** then **byte 9** carries the **return value** yielded by Zapit and **byte 10** is left at the **default value of 255**.  If the command was 1, then byte
  10. Returns the **condition number**
  11. Returns whether the **laser was on or off**

A return message of `{-1, 1, 255, 255}` indicates that `sendSample` was called but returned an error.

### Examples

If the desired function call is `sendSamples('conditionNum',5,'laserOn',true,'verbose',true,'logging',false)` then the message (as a tuple of bytes) to the server would be `{1  27  10  5}`



## Client behaviour

## Server behaviour

## Python worked example

## Bonsai worked example

## MATLAB worked example
