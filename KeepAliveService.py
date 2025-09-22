import win32serviceutil
import win32service
import win32event
import servicemanager
import sounddevice as sd
import numpy as np
import time

class KeepAliveService(win32serviceutil.ServiceFramework):
    _svc_name_ = "KeepAliveAudioService"
    _svc_display_name_ = "KeepAlive Audio Service"
    _svc_description_ = "Service to prevent automatic headphone shutdown by playing a short audio signal."

    def __init__(self, args):
        super().__init__(args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        self.running = True

    def SvcStop(self):
        # Set service stop status
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.hWaitStop)
        self.running = False

    def SvcDoRun(self):
        # Log that the service has started
        servicemanager.LogMsg(
            servicemanager.EVENTLOG_INFORMATION_TYPE,
            servicemanager.PYS_SERVICE_STARTED,
            (self._svc_name_, "")
        )
        self.main()

    def main(self):
        samplerate = 16000       # Audio sample rate (Hz)
        duration = 1             # Short signal duration (1 second)
        volume = 0.0005          # Very low volume
        t = np.linspace(0, duration, int(samplerate * duration), endpoint=False)
        frequency = 440.0        # Standard note A
        signal = (np.sin(2 * np.pi * frequency * t) * volume).astype(np.float32)

        while self.running:
            sd.play(signal, samplerate)  # Play the short tone
            sd.wait()                     # Wait until playback is finished
            time.sleep(120)               # Pause 2 minutes before next signal

if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(KeepAliveService)
