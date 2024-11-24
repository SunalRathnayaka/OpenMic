import socket, pyaudio, threading
import kivy
from kivy.uix.boxlayout import BoxLayout

kivy.require('2.3.0')
from kivy.app import App


# Audio configuration (must match server's configuration)
FORMAT = pyaudio.paInt16   # Audio format - audio quality - the quality of each samples
CHANNELS = 1               # Mono audio -
RATE = 44100               # Sample rate - number of samples each second
CHUNK = 512               # Number of frames per buffer - lower chunk = lower latency but higher processing power

# Initialize PyAudio for audio playback -
# creates a connection between program and audio device

# Client socket setup
# AF_INET specifies that the socket will use IPv4
# SOCK_STREAM defines TCP connection which has reliable data connection due to error checking
# alternatively, SOCK_DGRAM can be used for connectionless protocol (UDP)
host_ip = '192.168.1.13'  # Replace with the server's IP address
port = 9998
thread_run = True

class MainWidget(BoxLayout):
    port_val = str(port)

    def main_thread_func(self):
        global client_socket
        try:
            p = pyaudio.PyAudio()
            stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, output=True, frames_per_buffer=CHUNK)
            client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client_socket.connect((host_ip, port))
            self.ids.connection_label.text = "Connected"
            self.ids.connection_label.color = 0, 1, 0, 1
            self.ids.error_label.text = ""
            print(f"Connected to server at {host_ip}:{port}")

            while thread_run:
                data = client_socket.recv(CHUNK * 2)
                stream.write(data)

        except Exception as e:
            print("Error:", e)
            self.ids.error_label.text = str(e)

        finally:
            client_socket.close()
            self.ids.connection_label.text = "Disconnected"
            self.ids.connection_label.color = 1, 0, 0, 1
            print("Disconnected")

    def connection(self):
        global thread_run
        thread = threading.Thread(target=self.main_thread_func)
        thread.start()
        thread_run = True


    def disconnection(self):

        global thread_run
        thread_run = False



class Client_Kivy(App):

    def build(self):
        return MainWidget()
    def process(self):
        global host_ip
        input_ip = self.root.ids.IP_input.text
        host_ip = input_ip
        print(host_ip)


Client_Kivy().run()
