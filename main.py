import socket
import pyaudio
from threading import Thread
from kivy.app import App
from kivy.uix.button import Button
from kivy.uix.boxlayout import BoxLayout
from kivy.app import App


class OpenMic(App):
    def build(self):
        layout = BoxLayout(orientation='vertical')
        self.stop_button = Button(text="Stop Streaming")
        self.stop_button.bind(on_press=self.stop_thread_func)
        layout.add_widget(self.stop_button)
        
        self.stop_thread = False
        self.audio_thread = Thread(target=self.threaded_function)
        self.audio_thread.start()
        
        return layout

    def threaded_function(self):
        try:
            FORMAT = pyaudio.paInt16
            CHANNELS = 1
            RATE = 44100
            CHUNK = 512

            p = pyaudio.PyAudio()
            stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            host_ip = '26.211.54.29'
            port = 4982
            server_socket.bind((host_ip, port))
            server_socket.listen(5)
            print(f"Server is listening on {host_ip}:{port}")

            client_socket, addr = server_socket.accept()
            print("Connected by", addr)

            while not self.stop_thread:
                data = stream.read(CHUNK, exception_on_overflow=False)
                client_socket.sendall(data)

        except Exception as e:
            print("Error:", e)

        finally:
            client_socket.close()
            stream.stop_stream()
            stream.close()
            p.terminate()
            server_socket.close()
            print("Server connection closed.")

    def stop_thread_func(self, instance):
        self.stop_thread = True
        self.audio_thread.join()
        self.stop_button.text = "Streaming Stopped"
        print("Thread stopped.")

if __name__ == '__main__':
    AudioStreamingApp().run()
