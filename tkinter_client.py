import struct, pyaudio, threading, socket
from tkinter import *

root = Tk()
root.title("OpenMic")
root.geometry("255x300")

# Audio configuration (must match server's configuration)
FORMAT = pyaudio.paInt16   # Audio format - audio quality - the quality of each samples
CHANNELS = 1               # Mono audio -
RATE = 44100               # Sample rate - number of samples each second
CHUNK = 2048               # Number of frames per buffer - lower chunk = lower latency but higher processing power

# Initialize PyAudio for audio playback -
# creates a connection between program and audio device

# Client socket setup
# AF_INET specifies that the socket will use IPv4
# SOCK_STREAM defines TCP connection which has reliable data connection due to error checking
# alternatively, SOCK_DGRAM can be used for connectionless protocol (UDP)
host_ip = '192.168.1.19'  # Replace with the server's IP address
port = 8125
thread_run = True

VIRTUAL_MICROPHONE_NAME = "CABLE Input"  # For VB-Cable


def find_output_device(p: pyaudio.PyAudio, device_name: str):
    """
    Find the index of a virtual audio output device by its name.
    """
    for i in range(p.get_device_count()):
        device_info = p.get_device_info_by_index(i)
        if device_name in device_info['name']:
            print(f"Virtual device '{device_name}' found: Index {i}")
            return i
    raise Exception(f"Virtual device '{device_name}' not found.")

def main_thread_func():
    global client_socket
    try:
        p = pyaudio.PyAudio()
        # Find the virtual microphone device
        virtual_device_index = find_output_device(p, VIRTUAL_MICROPHONE_NAME)
        stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, output=True, frames_per_buffer=CHUNK, output_device_index=virtual_device_index)
        # , output_device_index=virtual_device_index
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect((host_ip, port))
        print(f"Connected to server at {host_ip}:{port}")
        status_label.config(text="Connected", fg="green")
        disconnect_button["state"] = "normal"
        network_lag = 0
        while thread_run:
            #Play the received audio chunk
            chunk_size_data = client_socket.recv(8)
            while len(chunk_size_data) < 8:
                chunk_size_buffer = client_socket.recv(8 - len(chunk_size_data))
                chunk_size_data += chunk_size_buffer
            chunk_size = struct.unpack('>Q', chunk_size_data)[0]  # Big-endian unsigned long long
            print(f"Receiving chunk of size: {chunk_size} bytes")

            # Receive the actual audio chunk
            audiodata = b''
            while len(audiodata) < chunk_size:
                packet = client_socket.recv(chunk_size - len(audiodata))
                print(len(packet))
                if not packet:
                    print("no data received")
                    return
                audiodata += packet
                network_lag += 1
            if network_lag > 100:
                client_socket.close()
                client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                client_socket.connect((host_ip, port))
                print("connection restarted")
                network_lag = 0
            stream.write(audiodata)

    except Exception as e:
        print("Error:", e)
        error_label.config(text=e, fg="red")

    finally:
        client_socket.close()
        print("Disconnected")
        status_label.config(text="Disconnected", fg="red")
        connect_button["state"] = "normal"
        disconnect_button["state"] = "normal"

def connection():
    global host_ip
    host_ip = ip_entry.get()
    global thread_run
    thread = threading.Thread(target=main_thread_func)
    thread.start()
    thread_run = True
    status_label.config(text="Connecting", fg="Green")
    connect_button["state"] = "disabled"
    disconnect_button["state"] = "disabled"
    error_label.config(text="", fg="red")

def disconnection():
    global thread_run
    thread_run = False
    status_label.config(text="Disconnected", fg="red")

def exit():
    client_socket.close()
    root.destroy()


ip_entry = Entry(root, width=40, justify='center')
connect_button = Button(root, width=15, text="Connect", command=connection)
disconnect_button = Button(root, width=15, text="Disconnect", command=disconnection)
port_label = Label(root, width=20, text="PORT: " + str(port))
status_label = Label(root, width = 20, text="Not Connected")
error_label = Label(root, width = 30, text="", wraplength=200)


ip_entry.grid(column=0, row=0, pady=20, padx=5, columnspan=2, sticky=EW)
connect_button.grid(column=0, row=1, pady=2, padx=5, sticky=EW)
disconnect_button.grid(column=1,row=1, pady=2, padx=5, sticky=EW)
port_label.grid(column=0, row=2, pady=20, padx=5, columnspan=2, sticky=EW)
status_label.grid(column=0, row=3, pady=10, padx=5, columnspan=2, sticky=EW)
error_label.grid(column=0, row=4, pady=10, padx=5, columnspan=2, sticky=EW)


root.protocol("WM_DELETE_WINDOW", exit)
root.mainloop()