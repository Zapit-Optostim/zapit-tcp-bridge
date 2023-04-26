## Client behaviour

TCP/IP communication occurs between a client and a server.  For Zapit, the host machine (running the Zapit software) is the server, while the experimental machine is the client.  Experimental and host machines may be the same computer.  The role of the client is to open a connection with the server when instructed to by the exerimenter, and to handle the sending of messages and recieving of replies.  The key parameters for the clients are the port the server will be listening on and the ip address of the host machine.

The basic workflow for communication via the TCP client (in any language) is as follows

    0. Create a client instance
    1. Open a connection 
    2. Send a message
    3. Wait for a reply (blocking)
    4. Seperate the reply into its message components
    5. Return reply message

The key syntax of each of these steps varies slightly on the implementation (see examples for Python, Bonsai and Matlab), but all examples implement the following.
    0. a **constructor** to set the parameters
    1. `connect` to open a connection
    2. `send_receive` to send a message and await a reply
    3. `close` to close the connection
    4. a **destructor** to ensure the connection is closed when the object is deleted

The clients are designed to send messages of 4 bytes and receive messages of 11 bytes, following the protocol described above.

## Server behaviour

The server is implemented in the main Zapit repo in the `zapit\zapit\+zapit\+interfaces\@TCPserver` directory and will be launched with zapit if, in the main config file, `tcpServer.enable` is set to `true` - see instructions [here](https://zapit.gitbook.io/user-guide/developer-notes/tcp-ip).  

The server is designed to read messages of 4 bytes.  These are parsed and the respective functions are called to control zapit.  Processing of the message is done by the `processBufferMessageCallback.m` function.

## Bonsai worked example
The syntax for Bonsai is different from either Python or Matlab.  The constructor is called at subscription.  Calling the `connect` method is done by sending a message with the command byte (the first byte) set to `255`.  Calling the `close` method is done by sending a message with the command byte set set to `254`.  Any other values for the command byte will call the `send_receive` method.  Calling `send_receive` whilst a message is still being handled will result in a error reply being generate (i.e., status byte = -1).  The destructor is called when the node is unsubscribed from.

## Matlab worked example
The MATLAB `demo.m` and `TCPclient.m` operate in exactly the same way as for the Python `demo.py` and `TCPclient.py`, with the only difference being that python `tuples` are replaced by MATLAB `cell arrays`.