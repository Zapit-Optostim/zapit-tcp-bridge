import socket
import struct

class TCPclient():
    def __init__(self,tcp_port = 1488, tcp_ip = "127.0.0.1", buffer_size = 11) -> None:
        self.tcp_port    = tcp_port
        self.tcp_ip      = tcp_ip
        self.buffer_size = buffer_size
        self.connected   = False
        self.s           = None

        
    def connect(self) -> tuple:
        if ~self.connected:
            self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.s.connect((self.tcp_ip,self.tcp_port))
            self.connected   = True
            return (1.0,b"\x01",b"\x01",b"\x01") # Message to connect whilst not connected
        else:
            return (-1.0,b"\x00",b"\x01",b"\x00") # Message to connect whilst already connected
    
    def send_recieve(self, message: tuple[bytes]) -> tuple:
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
        timestamp = struct.unpack('d',reply[0:8])[0]
        comm_byte = reply[8]
        resp_byte0 = reply[9]
        resp_byte1 = reply[10]
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
    
def main():
    comm = TCPclient()
    
    

if __name__ == "__main__":
    main()