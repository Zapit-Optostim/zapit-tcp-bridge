import socket
import struct
from Python_TCP_Utils import gen_Zapit_byte_tuple, parse_server_response
class TCPclient():
    def __init__(self,tcp_port = 1488, tcp_ip = "127.0.0.1", buffer_size = 16) -> None:
        self.tcp_port    = tcp_port
        self.tcp_ip      = tcp_ip
        self.buffer_size = buffer_size
        self.connected   = False
        self.s           = None

        
    def connect(self) -> tuple:
        if self.connected is False:
            self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.s.connect((self.tcp_ip,self.tcp_port))
            self.connected   = True
            return (1.0,b"\x01",b"\x01",b"\x01") # Message to connect whilst not connected
        else:
            return (-1.0,b"\x00",b"\x01",b"\x00") # Message to connect whilst already connected
    
    def send_receive(self, message: tuple[bytes]) -> tuple:
        if message[0] == (255).to_bytes(1, 'big'):
            return self.connect()
        elif message[0] == (254).to_bytes(1, 'big'):
            return self.close()
        elif (message[0] <  (254).to_bytes(1, 'big')) and (not self.connected):
            return (-1.0, b"\x00", b"\x00", b"\x01")
        message_int_list = [int.from_bytes(b, byteorder='big') for b in message]
        message_byte_obj = bytes(message_int_list)
        self.s.send(message_byte_obj)
        reply = self.s.recv(self.buffer_size)
        timestamp  = struct.unpack('d',reply[0:8])[0]
        comm_byte  = reply[8:9]
        resp_byte0 = reply[9:10]
        resp_byte1 = reply[10:]
        return (timestamp, comm_byte, resp_byte0, resp_byte1)

    
    def close(self) -> tuple:
        if self.connected:
            self.s.close()
            print(f"Connection to port {self.tcp_port}  at address {self.tcp_ip} closed")
            self.connected = False
            return (-1.0,b"\x01",b"\x00",b"\x00") # Message to disconnect whilst connected
        else:
            return (-1.0,b"\x00",b"\x01",b"\x00") # Message to disconnect whilst not connected

    def __del__(self) -> None:
        if self.connected:
            self.s.close()
            print(f"Connection to port {self.tcp_port}  at address {self.tcp_ip} closed")
            return (-1.0,b"\x01",b"\x00",b"\x00") # Message to disconnect whilst connected
    
    def stop_optostim(self):
        """
        TCP client command to stop stimulation by remotely running zapit.pointer.stopOptoStim()
        """
        zapit_com_bytes,zapit_com_ints = gen_Zapit_byte_tuple(0,{},{})
        return self._send_receive(zapit_com_bytes)

    def stim_config_loaded(self):
        """
        TCP client command to check if the stimulation configuration is loaded by remotely running zapit.pointer.stimConfigLoaded()
        """
        zapit_com_bytes,zapit_com_ints = gen_Zapit_byte_tuple(2,{},{})
        return self._send_receive(zapit_com_bytes)

    def get_state(self):
        """
        TCP client command to get the current state by remotely running zapit.pointer.getState()
        """
        zapit_com_bytes,zapit_com_ints = gen_Zapit_byte_tuple(3,{},{})
        return self._send_receive(zapit_com_bytes)

    def get_num_conditions(self):
        """
        TCP client command to get the number of conditions by remotely running zapit.pointer.getNumConditions()
        """
        zapit_com_bytes,zapit_com_ints = gen_Zapit_byte_tuple(4,{},{})
        return self._send_receive(zapit_com_bytes)

    def send_samples(self,**kwargs):
        """
        TCP client command to send samples by remotely running zapit.pointer.sendSamples()

        Inputs [param=pair values]
            conditionNum: int between 0,255 (inclusive), indicating the condition number.  If not provided, a random one is chosen
            laser_On: bool indicating whether the laser is on
            hardwareTriggered_On: bool indicating whether the hardware trigger is on
            logging_On: bool indicating whether the logging is on
            verbose_On: bool indicating whether the verbose is on
            stimDuration: float indicating the duration of the stimulation in seconds.  0 by default
            laserPower: float indicating the power of the laser in mW.  If not provided, the laser power in the config file is used instead
            startDelaySeconds: float indicating the delay in seconds before the stimulation starts.  0 by default

        Returns:
            timestamp: float indicating the timestamp of the response - if -1, the command was not executed
            comm_byte: bytes indicating the command byte of the response
            condition_num: int indicating the condition number of the response - if 255, no config file was loaded
            _resp: bytes indicating the response byte of the response. 
        """
        # Construct the arg_keys_dict and arg_values_dict
        arg_keys_dict = {"conditionNum": False, "laser_On": False, "hardwareTriggered_On": False,
                         "logging_On": False, "verbose_On": False, "stimDuration": False, "laserPower": False,
                         "startDelaySeconds": False}
        arg_values_dict = {"conditionNum":0,"laser_On":True,"hardwareTriggered_On":False,"logging_On":False,"verbose_On":False,
                           "stimDuration":0.0,"laserPower":0.0,"startDelaySeconds":0.0}
        for key,value in kwargs.items():
            arg_keys_dict[key] = True
            arg_values_dict[key] = value
        zapit_com_bytes,_ = gen_Zapit_byte_tuple(1,arg_keys_dict,arg_values_dict)     
        return self._send_receive(zapit_com_bytes)  
    
    def _send_receive(self,zapit_byte_tuple):
        reply = self.send_receive(zapit_byte_tuple)
        return self.parse_response(zapit_byte_tuple,reply)  

    def parse_response(self,zapit_byte_tuple,reply):
        datetime = reply[0]
        message = reply[1]
        response_tuple = reply[2:]
        return parse_server_response(zapit_byte_tuple,datetime,message,response_tuple)

        
def main():
    pass
    

if __name__ == "__main__":
    main()