import socket
import pyaudio
from threading import Thread

# Audio configuration
FORMAT = pyaudio.paInt16  # Audio format
CHANNELS = 1  # Mono audio
RATE = 44100  # Sample rate (in Hz)
CHUNK = 512  # Number of frames per buffer

host_ip = '192.168.1.9'  # Bind to all network interfaces
port = 9998
print(f"Server is listening on {host_ip}:{port}")
p = pyaudio.PyAudio()
stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)


def threaded_function():
    try:
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.bind((host_ip, port))
        server_socket.listen(5)
        client_socket, addr = server_socket.accept()
        print("Connected by", addr)
        while not stop_thread:
            # Capture live audio chunk
            data = stream.read(CHUNK, exception_on_overflow=False)
            client_socket.sendall(data)

    except Exception as e:
        print("Error:", e)

# Thread control
stop_thread = False

while True:
    thread = Thread(target=threaded_function)
    thread.start()
    thread.join()