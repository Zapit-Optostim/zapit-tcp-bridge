import datetime
import struct
import numpy as np

def gen_Zapit_byte_tuple(trial_state_command, arg_keys_dict, arg_values_dict):
    """
    Generate a byte tuple to communicate with Zapit device.

    Parameters:
    trial_state_command (int): Integer value representing the trial state command.
    arg_keys_dict (dict): A dictionary specifying the channels through Zapit is being communicated with.
    arg_values_dict (dict): A dictionary specifying the actual boolean or integer values being communicated to Zapit.

    Returns:
    Tuple: A byte tuple containing the state command byte, the argument keys byte,
    the argument values byte, and the condition number byte (if applicable).
    """
    # map arg_keys_dict to ints
    keys_to_int_dict = {"conditionNum": 1, "laser_On": 2, "hardwareTriggered_On": 4,
                        "logging_On": 8, "verbose_On": 16, "stimDuration": 32, "laserPower": 64,
                        "startDelaySeconds": 128}

    # map True/False boolean values to 1/0
    bool_to_int_dict = {True: 1, False: 0}

    # sum arg_keys ints and convert to byte
    arg_keys_int = 0
    for arg, key in arg_keys_dict.items():
        arg_keys_int += bool_to_int_dict[key] * keys_to_int_dict[arg]
    arg_keys_byte = arg_keys_int.to_bytes(1, 'big')

    # sum arg_value ints and convert to byte
    arg_values_int = 0
    for arg, value in arg_values_dict.items():
        if arg == "conditionNum":
            continue
        try:
            arg_values_int += bool_to_int_dict[value] * keys_to_int_dict[arg]
        except:
            pass
    arg_values_byte = arg_values_int.to_bytes(1, 'big')
    # define trial states where python will query zapit
    trial_state_commands_dict = {"stimConfLoaded": 2, "return_state": 3,
                                 "numCondition": 4, "sendsamples": 1, "stopoptostim": 0}
    # convert state_command to byte
    state_command_byte = trial_state_command.to_bytes(1, 'big')
    # extract the float parameters
    if arg_keys_dict["stimDuration"] == True:
        stimDuration = arg_values_dict["stimDuration"]
    else:
        stimDuration = np.float32(0.0) # Default stimDuration
    if arg_keys_dict["laserPower"] == True:
        laserPower_mW = arg_values_dict["laserPower"]
    else:
        laserPower_mW = np.float32(0.0) # Place holder
    if arg_keys_dict["startDelaySeconds"] == True:
        startDelaySeconds = arg_values_dict["startDelaySeconds"]
    else:
        startDelaySeconds = np.float32(0.0)
    # if True, extract condition nb and convert to byte
    if trial_state_command == 1:
        if arg_keys_dict['conditionNum'] == True:
            conditionNum_int = arg_values_dict["conditionNum"]
            conditionNum_byte = conditionNum_int.to_bytes(1, 'big')
        else: 
            conditionNum_int = 255
            conditionNum_byte = conditionNum_int.to_bytes(1, 'big')
    if [k for k, v in trial_state_commands_dict.items() if v == trial_state_command][0] == "sendsamples": # if trial_state_command = "sendsamples"
        zapit_com_bytes = state_command_byte + arg_keys_byte + arg_values_byte + conditionNum_byte + \
                      float_to_byte_list(stimDuration) + float_to_byte_list(laserPower_mW) + float_to_byte_list(startDelaySeconds)        
        zapit_com_ints = [trial_state_command, arg_keys_int, arg_values_int, conditionNum_int,stimDuration,laserPower_mW,startDelaySeconds]
    else:
        zapit_com_bytes = state_command_byte + (0).to_bytes(1, 'big') + (0).to_bytes(1, 'big') + (0).to_bytes(1, 'big') + float_to_byte_list(stimDuration) + float_to_byte_list(laserPower_mW) + float_to_byte_list(startDelaySeconds)
        zapit_com_ints = [trial_state_command, 0, 0, 0, 0, 0, 0]
    return [cur_val.to_bytes(1, 'big') for cur_val in list(zapit_com_bytes)], zapit_com_ints

def float_to_byte_list(float_32):
    bytes_list = struct.pack('f', float_32)
    return bytes_list

def datetime_float_to_str(date_float):
    """
    Converts a MATLAB datenum value represented as a double-precision floating-point number
    to a string representation of the date and time in ISO format (YYYY-MM-DD HH:MM:SS).

    Parameters:
    date_float (float): A double-precision floating-point number representing the date and time
                        as a MATLAB datenum value.

    Returns:
    str: A string representation of the date and time in ISO format (YYYY-MM-DD HH:MM:SS).
    """
    # Convert the datenum value to a Unix timestamp
    unix_timestamp = (date_float - 719529) * 86400

    # Create a datetime object from the Unix timestamp
    datetime_str = str(datetime.datetime.fromtimestamp(unix_timestamp))

    return datetime_str

def parse_server_response(zapit_byte_tuple, datetime_double, message_type_byte, response_byte_tuple):
    """
    Parse server response and return a tuple with a datetime string and a tuple of integers representing the response of Zapit.

    Parameters:
    zapit_byte_tuple (tuple): The output of gen_Zapit_byte_tuple containing the expected message_type_byte as the first element.
    datetime_double (float): A double-precision floating-point number representing the date and time of the response,
                             or -1 if there was an error, or 1 if the server connected successfully.
    message_type_byte (bytes): A byte representing the message type of the response (e.g. sendSamples, stimConfLoaded etc.)
    response_byte_tuple (tuple): A tuple of bytes representing the server response  (e.g. response_byte_tuple[0] as conditionNumber & response_byte_tuple[1] as laserOn
    if message_type = 1)

    Returns:
    tuple: A tuple containing a status string and a tuple of integers representing the server response.
           The status string can be one of the following:
           - 'Error': The datetime was -1, indicating an error.
           - 'Connected': The datetime was 1, indicating a successful connection.
           - 'Mismatch': The message type byte did not match the expected value in zapit_byte_tuple[0].
           - datetime_str: The datetime as a string, formatted using the datetime_float_to_str() function.
           The tuple of integers represents the status codes returned by the server.
    """
    server_response_ints = tuple(int(b[0]) for b in response_byte_tuple) # convert response_byte_tuple to a tuple of integers
    if datetime_double == -1:
        return('Error', server_response_ints)
    elif datetime_double == 1:
        return('Connected', server_response_ints)
    else:
        datetime_float64 = np.float64(datetime_double)
        datetime_str = datetime_float_to_str(datetime_float64)
        if message_type_byte != zapit_byte_tuple[0]: # check that Zapit is responding to the right message_type (e.g. sendSamples) else throw an error   
            return('Mismatch', server_response_ints)
        else: 
            pass
    return(datetime_str, server_response_ints)