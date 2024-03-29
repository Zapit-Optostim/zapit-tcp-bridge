# The messaging protocol
The messaging protocol with Zapit is composed of 5 commands:

  0. Stop stimulating (`stopOptoStim`)
  1. Start stimulating (`sendSamples`)
  2. Is a stimulus config loaded? (`stimConfig`)
  3. What is the state of Zapit? (`state`)
  4. How many conditions? (`stimConfig`)

Only command **1** has input arguments: it takes a variable number of inputs and returns two values. 
The remaining commands have no input arguments and return a single value. 

### Messages to the server
Messages to the server always consist of **4 bytes** (*stored as little-endian*).
The first byte consists of the **command number** (given above).
The remaining bytes are by default set to **0**, and are only used if the command number is **1** (i.e., if we are calling the `sendSamples` method).
In this case, the message structure is as follows:

  0. Value of **1** *indicating the message is to start stimulating by calling the **`sendSamples`** function*
  1. Bitmask indicating which **keys to pass as arguments** to `sendSamples`
  2. Bitmask indicating the **boolean values of the key-value pairs** given to `sendSamples`
  3. Byte indicating the **condition number** to pass to `sendSamples`

Possible arguments to `sendSamples` are **{`conditionNum`, `laserOn`, `hardwareTriggered`, `logging`, `verbose`}**.
Each of the 5 lowest significant bits of **byte 1** in the message corresponds to these arguments, with the bit set to 1 if the key-value pair is to passed of 0 if it is not to be passed.
For example, if we are sending arguments for `conditionNum`, `laserOn` and `logging`, byte 1 will have memory layout `0 0 0 0 1 0 1 1`, for a value of 11 (read the list of keys from right to left to get the position in the byte).


**Byte 2** in the message carries the values for the key-value pairs that have **boolean values** ({`laserOn`, `hardwareTriggered`, `logging`, `verbose`}), in the same positions as for byte 1.
`conditionNum` has an integer value so is not communicated in this byte.
For example, if we are sending the following key-value pairs 
**{`laserOn`:`true`, `hardwareTriggered`:`true`, `verbose`:`false`}** then **byte 1** would have layout **`0 0 0 1 0 1 1 0`** and **byte 2** would have layout **`0 0 0 0 0 1 1 0`**.

Byte 3 is the uint8 value for `conditionNum` (note this limits the protocol to 256 conditions, but this can easily be extended by the user by adding another byte).

### Replies from the server
Messages from the server always consist of **15 bytes (0 - 14)**

*1.* Bytes `0-7` represent the status of the message. If a `1` or `-1` it represents either a successful connection or an error, respectively.
Otherwise these 8 bytes represents a double that is a `datetime` number
*2.* Byte `8` is a copy of the message byte. This guarantees that the reply corresponds to the command we sent.

If the command was `1` then byte `9` is the presented condition number and byte `10` indicates whether or not the laser was on. The remaining four bytes are unused (default value of 255).

Otherwise, byte `9` carries the return value yielded by Zapit and remaining five bytes are unused (default value of 255).

For example, a return message of `{-1, 1, 255, 255, 255, 255, 255, 255}` indicates that `sendSamples` was called but returned an error.



## Client behaviour

TCP/IP communication occurs between a client and a server.
For Zapit, the host machine (running the Zapit software) is the server, while the experimental machine is the client.
Experimental and host machines may be the same computer.
The role of the client is to open a connection with the server when instructed to by the experimenter, and to handle the sending of messages and receiving of replies.
The key parameters for the clients are the port the server will be listening on and the ip address of the host machine.

The basic workflow for communication via the TCP client (in any language) is as follows

    0. Create a client instance
    1. Open a connection 
    2. Send a message
    3. Wait for a reply (blocking)
    4. Separate the reply into its message components
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


The server is designed to read messages of 4 bytes.
These are parsed and the respective functions are called to control zapit.
Processing of the message is done by Zapit using the `processBufferMessageCallback` method in the `zapit.interfaces.tcpServer` class. 
This is the located in the Zapit package, not this one.





## Python worked example



### **Generating a communication tuple**

As described above, messages to the server must always consist of 4 bytes: the command (indicated by a number), the argument keys, the argument values, and the condition number. Now let's say we want to send the command number 1 (sendSamples), we wish to communicate along the `conditionNum`, `laserOn` and `verbose` channels, and we wish to set the `conditionNum` to `4`, `laserOn` to `True` and `verbose` to `False` (n.b. remember that if the command number is anything else than 1, all other bytes will be set to 0).
In order to send this command to the server, we must first generate a byte tuple containing this information. We can do this by calling the `gen_Zapit_byte_tuple` function from the `Python_TCP_Utils` module. First we import the module:

```python
import Python_TCP_Utils as ptu
```

Then, we call `gen_Zapit_byte_tuple`. This function takes 3 arguments: the trial command, a dictionary of argument keys, and a dictionary of argument values. The output is a byte tuple containing the byte representation of trial command, and - if the trial command is 1 - the byte representation of the argument keys, argument values, and the condition number. If the trial command is not 1, these last 3 bytes are zero.
 Therefore, to send the message specified above, we must call:

```python
zapit_byte_tuple = ptu.gen_Zapit_byte_tuple(trial_state_command = 1,
                                            arg_keys_dict = {'conditionNum_channel': True, 'laser_channel': True, 
                                                              'hardwareTriggered_channel': False, 'logging_channel': False, 
                                                              'verbose_channel': True},
                                            arg_values_dict = {'conditionNum': 4, 'laser_ON': True, 
                                                               'hardwareTriggered_ON': False, 'logging_ON': False, 
                                                               'verbose_ON': False})
```

Printing `zapit_byte_tuple` should yield:
```python
[b'\x01', b'\x13', b'\x02', b'\x04']
```

Unless you are used to working with binary data or low-level programming languages, this result is probably quite cryptic. Let's dig a little bit to understand what it means. 

We can convert this byte tuple into a integer tuple using list comprehension:

```python
zapit_int_tuple = tuple([int(b[0]) for b in zapit_byte_tuple])
print(zapit_int_tuple)
(1, 19, 2, 4)
```

What do these integers represent? What the gen_Zapit_byte_tuple() function is actually doing is using **[bitmasks](https://en.wikipedia.org/wiki/Mask_(computing))** to represent the set of boolean and integer values that are being communicated with the server. It is mapping boolean keys and values to integer values and then combining them together to produce integers with specific patterns. This is done using 3 dictionaries, mapping argument keys to integers, argument values to integers, and booleans to integers, respectively. We can view these three dictionaries below:

```python
keys_to_int_dict = {"conditionNum_channel": 1, "laser_channel": 2, "hardwareTriggered_channel": 4,
                    "logging_channel": 8, "verbose_channel": 16}

values_to_int_dict = {"conditionNum": 1, "laser_ON": 2, "hardwareTriggered_ON": 4,
                      "logging_ON": 8, "verbose_ON": 16}

bools_to_int_dict = {True: 1, False: 0}
```

Let's consider our example above. First, our trial command is 1, so the first element of our `zapit_int_tuple` is `1`. Second, our `conditionNum`, `laserOn` and `verbose` keys are `True`, while all the others are `False`. Applying our `keys_to_int_dict` mapping, we get &nbsp; `1x1 + 2x1 + 4x0 + 8x0 + 16x1 = 19` &nbsp;  as the second element of out `zapit_int_tuple`. Third, we set `laserOn` to `True` and  `verbose` to `False`, obtaining &nbsp;  `2x1 + 16x0 = 2` &nbsp;  as the third element. Finally, with a conditionNum of 4, we get &nbsp;  `4x1 = 4` &nbsp;  as the fourth element of our tuple. We therefore end up with `(1,19,2,4)`. It is noteworthy that, although useful for demonstration purposes, this zapit_int_tuple never comes into play during the communication with the server as the output of `gen_Zapit_byte_tuple()` is a byte tuple, and not an integer tuple.



### **Sending to the server**

Now that we have our byte tuple `[b'\x01', b'\x13', b'\x02', b'\x04']`, we want to send it to the server. We can do this using a TCP (Transmission Control Protocol) client. To do this, we import the `TCPclient` class from the `TCPclient` module:


```python
from TCPclient import TCPclient
```
Then, we need to crate an instance of the TCPclient class:

```python
client = TCPclient()
```
When called with no arguments the client initialises with the default arguments of `tcp_port = 1488, tcp_ip = "127.0.0.1"`, which allows for connections on the `localHost`.
These are the same default settings for the Bonsai and MATLAB clients and the server.
If you wanted to connect to a different port or IP-address, these parameters would need to be specified when the client is initialised (again, this is the same for the clients in the other languages).
For example, to connect to a machine with an IP-address of `127.135.35.1` on port `1672` you would create a client with the following command `client = TCPclient(tcp_port = 1672, tcp_ip = "127.135.35.1")`

We can now call the `connect()` method of the `TCPclient` class to establish a connection with the server:
```python
client.connect()
```

A successful connection should return `(1.0, b'\x00', b'\x01', b'\x00')`. If the connection is already established, the method should return `(-1.0, b'\x00', b'\x01', b'\x00')`. If a connection is already established with a different client, this should yield a `ConnectionRefusedError`. 
Once the connection is established, we can call the `send_receive()` method to send the byte_tuple to the server and receive a response:

```python
response = client.send_receive(zapit_byte_tuple)
```
The `response` will be a tuple of 4 elements. If the connection is established, the first element of the tuple will be the current datetime as a `double`. The other three elements are bytes. The second element will be the trial command. The third and fourth elements will be depend on the trial command. If the trial command is 1 (`sendSamples`), the third element will be `conditionNum` and the fourth with be the `laserOn`. If the trial command is 0 (`stopOptoStim`), the third element will be the response will be `1` and the fourth element will be `255`. If the trial command is `2-4`, the third element will be the response to the query and the fourth element will be `255`. If the connection with the TCPclient is not established, the method should return `(-1.0, b"\x00", b"\x00", b"\x01")`. Therefore, in our case, the response will be `(739002.8009685668, b'\x01', b'\x04', b'\x01')`.



### **Parsing the server response**

As is probably evident from the section above, breaking down the server response into its various components can be a little cumbersome and confusing. Moreover, the response from the server also contains bytes, but what we want are integers. For this reason, the final stage is to call the `parse_server_response` function (again from the `Python_TCP_Utils` module). This function takes as arguments the `zapit_byte_tuple`, the `datetime_double`, the `trial_command_byte` and the `response_byte_tuple`. Following from the previous section, you should now realise that the `datetime_double` is the first element of our response, while the `trial_command_byte` is the second element, and the `response_byte_tuple` are the third and fourth. As such, we can call `parse_server_response`:

```python
parsed_response = ptu.parse_server_response(zapit_byte_tuple = zapit_byte_tuple,
                                            datetime_double = response[0],
                                            message_type_byte = response[1],
                                            response_byte_tuple =  response[2:4])
```
This function returns a tuple containing a status string and a tuple of integers. The status string can be one of the following: 
- 'Error': The datetime was -1, indicating an absence of connection (as specified above)
- 'Connected': The datetime was 1, indicating a successful connection (occurs upon initialisation of the connection)
- 'Mismatch': The trial command of the server response did not match the trial command of zapit_byte_tuple (its first element).
- datetime_str: The datetime as a string, formatted using the `datetime_float_to_str()` function.  
  
The tuple of integers will contain `response_byte_tuple` as integers. Therefore, in our case, the function will return: `('2023-04-26 20:08:24.183945', (4, 1))` (current datetime, `conditionNum` as `4` and `LaserOn` as `1`).



## Bonsai worked example



The syntax for Bonsai is different from either Python or Matlab.
The constructor is called at subscription.
Calling the `connect` method is done by sending a message with the command byte (the first byte) set to `255`.
Calling the `close` method is done by sending a message with the command byte set set to `254`.
Any other values for the command byte will call the `send_receive` method.
Calling `send_receive` whilst a message is still being handled will result in a error reply being generate (i.e., status = `-1`).
The destructor is called when the node is unsubscribed from.

For a quick demonstration of how the TCP communication works in Bonsai, open the file located at `'zapit-tcp-bridge\Bonsai\Bonsai_Demo'`. There should be 4 grouped workflows at the top: `trial_command`, `arg_keys`, `arg_values` and `Variables` (you can ignore this last one). Clicking on either of these first three nodes will allow you to select the `trial_command`, `arg_keys`,  and `arg_values`. Let's consider a similar example to the one above, with:

```
-  trial__command = 1
-  arg_keys:
   - conditionNum_channel =  True
   - laser_channel = True
   - hardwareTriggered_channel = False
   - logging_channel = False
   - verbose_channel = True
 - arg_values:
   - conditionNum = 4
   - laser_ON = True
   - hardwareTriggered_ON = False
   - logging_ON = False
   - verbose_ON = False
```

Once you have set these parameters, launch the program by clicking the green `Start` button at the top left. The workflow is built to respond to key-presses (hence the `KeyDown` node) that emulate the Start/Connection (key S), Trial (key T), and End/Disconnection (key E) of an experimental session (this is the work of the `Set_Session_Epoch` node). The `Gen_Zapit_Byte_Tuple`, `Gen_Zapit_Byte_Tuple` and `Parse_Server_Response` nodes behave in the same way as the functions in the Python demonstration with the same names. Importantly, all of the nodes following the `KeyDown` execute in sequence once a key pressed. Right clicking on the nodes will allow you to select `Show Visualizer > Bonsai.Design.ObjectTextVisualizer` and print the outputs of the `Gen_Zapit_Byte_Tuple` and `Parse_Server_Response` nodes on the screen. Using the example above, pressing `S` should yield:
-  `(255, 19, 2, 4)` in the `Gen_Zapit_Byte_Tuple` window 
-  `(Connected, (1, 1))` in the `Parse_Server_Response` window

Pressing T should yield:
-  `(1, 19, 2, 4)` in the `Gen_Zapit_Byte_Tuple` window 
-  `(2023-04-26 20:08:24.183945, (4, 1))` in the `Parse_Server_Response` window

Finally, pressing E should yield:
-  `(254, 19, 2, 4)` in the `Gen_Zapit_Byte_Tuple` window 
-  `(Disconnected, (0, 0))` in the `Parse_Server_Response` window

Note that if you do not respect this `S --> T*n --> E` order, `Parse_Server_Response` will output `Error` along with a integer tuple depending on how the required key-press order has been violated.


