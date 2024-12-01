import socket, pyaudio, threading
import kivy
from kivy.uix.boxlayout import BoxLayout
from kivy.lang import Builder

kivy.require('2.3.0')
from kivy.app import App

import os, sys
from kivy.resources import resource_add_path

kv = """
MainWidget:

<MainWidget>:
    canvas.before:
        Color:
            rgba: 1, 1, 1, 1
        Rectangle:
            pos: self.pos
            size: self.size
    orientation: "vertical"
    padding: 10

    Label:
        size_hint: 1, 0.1

    TextInput:
        id: IP_input
        focus: True
        multiline: False
        pos_hint: {"center_x": 0.5}
        text: "192.168.1.13"
        on_text: app.process()
        size_hint: 0.8, None
        size: 0, 30

    BoxLayout:
        size_hint: 1, None
        size: 0, "50dp"
        orientation: "horizontal"
        spacing: 20

        Button:
            text: "Connect"
            on_press: root.connection()
            size_hint: 0.4, None
            size: 0, "30dp"

        Button:
            text: "Disconnect"
            on_press: root.disconnection()
            size_hint: 0.4, None
            size: 0, "30dp"


    Label:
        size_hint: 1, 0.1
    Label:
        id: connection_label
        text: "Disconnected"
        color: 0, 0, 0, 1
        pos_hint: {"top": 1}
        size_hint: 1, 0.2
        # size: 0, "10dp"

    Label:
        text: "Port: " + root.port_val
        color: 0, 0, 0, 1
        pos_hint: {"top": 1}
        size_hint: 1, 0.2

    Label:
        id: error_label
        color: 1, 0, 0, 1
        text_size: self.width, None
        pos_hint: {"center_x": 0.5 }
        size_hint: 0.8, 0.2
        height: self.texture_size[1]

    Label:
"""
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
        return Builder.load_string(kv)
    def process(self):
        global host_ip
        input_ip = self.root.ids.IP_input.text
        host_ip = input_ip
        print(host_ip)

    @staticmethod
    def resource_path(relative_path):
        try:
            base_path = sys._MEIPASS
        except Exception:
            base_path = os.path.abspath('.')
        return os.path.join(base_path, relative_path)

Client_Kivy().run()
