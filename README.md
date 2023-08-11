# zapit-tcp-bridge
Bridge for controlling Zapit via a local or remote TCP connection.
This repo provides clients for MATLAB, Python, and Bonsai.
The MATLAB TCP server exists in the main Zapit repo in `zapit\+zapit\+interfaces`.

## Getting Started
### Basics
* You will need at least Zapit version 0.12.0.
* For the client to connect to Zapit, you must start Zapit with the `tcpServer` `enable` setting in the `yml` file set to `true`.
* Ensure the code in this repo is installed on the PC that will be the client. 

### Connecting from a remote PC
If you wish to connect to the server from a client on a different PC, you will in addition need to:
* Find the IP address of the Zapit (server) PC with `zapit.interfaces.getIPaddress`
* Enter this into the TCP server `IP` variable in the `yml` settings file.
* Supply this IP address to the client using the optional `ip` parameter input argument. (`help zapit_tcp_bridge.TCPclient`)





## What is this for?
[Zapit](https://github.com/Zapit-Optostim/zapit) is software for running a scanning opto-stim system for head-fixed mouse behaviour, written in MATLAB.
There is additionally a [Python bridge](https://github.com/Zapit-Optostim/zapit-Python-Bridge) that allows the software to be called via Python by wrapping the key MATLAB function calls in Python.

This package provides multi-language support via a TCP/IP messaging protocol for Zapit.
A TCP server can be initialised when Zapit is launched.
This can be interfaced with from any language and from different machines on the same network implementing the same protocol.


In the [Message Protocol document](Message_Protocol.md) we define the protocol, to allow users to implement their own clients in whatever language or context they wish. We provide example clients in [MATLAB](MATLAB), [Python](Python) ([Examples](Examples/Python)), and [Bonsai](Bonsai)  ([Examples](Examples/Bonsai)).

