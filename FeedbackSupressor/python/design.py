import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

# --- 1. Basic IIR Biquad Filter Implementation ---
# This function applies a biquad filter. In Verilog, this would be a direct form II transposed structure.
def apply_biquad(x, b, a, zi):
    """
    Applies a single IIR biquad filter to an input signal.
    Args:
        x (np.ndarray): Input signal.
        b (list): Numerator coefficients [b0, b1, b2].
        a (list): Denominator coefficients [a0, a1, a2].
        zi (np.ndarray): Initial conditions for the filter states [z1, z2].
    Returns:
        tuple: (filtered_signal, final_states)
    """
    y = np.zeros_like(x, dtype=np.float64)
    # Filter states (w[n-1], w[n-2] for direct form II transposed)
    w1 = zi[0]
    w2 = zi[1]

    # Normalize coefficients by a[0] if it's not 1 (common for biquads where a0 is 1)
    # For standard biquad, a0 is usually 1, so this normalization might not be strictly needed
    # but good practice for generic IIR.
    b0, b1, b2 = b[0], b[1], b[2]
    a0, a1, a2 = a[0], a[1], a[2]

    for n in range(len(x)):
        # Direct Form II Transposed
        # y[n] = b0*x[n] + w1
        # w1 = b1*x[n] - a1*y[n] + w2
        # w2 = b2*x[n] - a2*y[n]

        # Calculate output
        y[n] = b0 * x[n] + w1

        # Update states for next iteration
        w1_next = b1 * x[n] - a1 * y[n] + w2
        w2_next = b2 * x[n] - a2 * y[n]

        w1 = w1_next
        w2 = w2_next

    return y, np.array([w1, w2])

# --- 2. Feedback Suppressor Class ---
class FeedbackSuppressor:
    def __init__(self, sample_rate, num_bands=10, freq_range=(200, 4000), filter_q=50, max_gain_reduction_db=-15):
        """
        Initializes the feedback suppressor.
        Args:
            sample_rate (int): Audio sample rate in Hz.
            num_bands (int): Number of frequency bands to monitor for feedback.
            freq_range (tuple): (min_freq, max_freq) for feedback detection.
            filter_q (float): Q factor for the notch filters. Higher Q means narrower notch.
            max_gain_reduction_db (float): Maximum gain reduction for the notch filter in dB.
        """
        self.sample_rate = sample_rate
        self.num_bands = num_bands
        self.freq_range = freq_range
        self.filter_q = filter_q
        self.max_gain_reduction_db = max_gain_reduction_db

        # Define fixed frequencies to monitor (simplified for this example)
        self.monitor_frequencies = np.linspace(freq_range[0], freq_range[1], num_bands)
        self.filter_states = {f: np.zeros(2) for f in self.monitor_frequencies} # Store states per filter

        # Thresholds for feedback detection (simplified)
        self.energy_threshold = 0.01 # Adjust based on signal levels
        self.feedback_detected = {f: False for f in self.monitor_frequencies}
        self.current_gain_reduction = {f: 0.0 for f in self.monitor_frequencies} # Linear gain factor

        print(f"Monitoring frequencies: {self.monitor_frequencies} Hz")

    def _detect_feedback(self, audio_chunk):
        """
        Simplified feedback detection: Check energy in specific frequency bins using FFT.
        In a real Verilog implementation, this would be a more robust peak detection
        or Goertzel filter bank.
        """
        N = len(audio_chunk)
        if N == 0:
            return

        # Perform FFT on the chunk
        fft_output = np.fft.fft(audio_chunk * np.hanning(N)) # Apply window
        freqs = np.fft.fftfreq(N, d=1/self.sample_rate)

        for i, f_monitor in enumerate(self.monitor_frequencies):
            # Find the closest FFT bin to the monitor frequency
            idx = np.argmin(np.abs(freqs - f_monitor))
            energy = np.abs(fft_output[idx])**2 / N # Normalized energy

            # Simple thresholding for detection
            if energy > self.energy_threshold and not self.feedback_detected[f_monitor]:
                self.feedback_detected[f_monitor] = True
                print(f"Feedback detected at {f_monitor:.1f} Hz with energy {energy:.4f}")
            elif energy < self.energy_threshold * 0.5 and self.feedback_detected[f_monitor]:
                # Simple decay for suppression
                self.feedback_detected[f_monitor] = False
                print(f"Feedback subsided at {f_monitor:.1f} Hz")

    def _update_notch_filters(self, f_monitor):
        """
        Calculates biquad coefficients for a notch filter.
        The gain reduction is applied dynamically.
        """
        if self.feedback_detected[f_monitor]:
            # Gradually increase gain reduction when feedback is detected
            target_gain_reduction_linear = 10**(self.max_gain_reduction_db / 20)
            self.current_gain_reduction[f_monitor] = max(target_gain_reduction_linear, self.current_gain_reduction[f_monitor] * 0.95) # Faster decay
            self.current_gain_reduction[f_monitor] = min(self.current_gain_reduction[f_monitor] / 0.9, target_gain_reduction_linear) # Slower attack
        else:
            # Gradually release gain reduction when feedback subsides
            self.current_gain_reduction[f_monitor] = min(1.0, self.current_gain_reduction[f_monitor] * 1.05) # Slower release

        # Design a peaking/notch filter (gain is negative for attenuation)
        # Use a very high Q for a narrow notch
        gain_db = 20 * np.log10(self.current_gain_reduction[f_monitor]) if self.current_gain_reduction[f_monitor] > 0 else self.max_gain_reduction_db
        
        # Ensure gain_db is not positive
        gain_db = min(0, gain_db)

        # Using scipy's iirfilter for a generic biquad, then converting to peaking/notch
        # For a notch, we typically use a band-stop filter or a peaking filter with negative gain.
        # Here we'll use a peaking EQ formula which can create a notch with negative gain.
        
        # Biquad coefficients for a peaking filter (from RBJ Audio EQ Cookbook)
        A = 10**(gain_db / 40) # Convert dB gain to linear amplitude gain
        omega = 2 * np.pi * f_monitor / self.sample_rate
        sn = np.sin(omega)
        cs = np.cos(omega)
        alpha = sn / (2 * self.filter_q)

        b0 = 1 + alpha * A
        b1 = -2 * cs
        b2 = 1 - alpha * A
        a0 = 1 + alpha / A
        a1 = -2 * cs
        a2 = 1 - alpha / A

        # Normalize by a0
        b = [b0/a0, b1/a0, b2/a0]
        a = [1, a1/a0, a2/a0] # a0 becomes 1 after normalization

        return b, a

    def process_audio(self, audio_chunk):
        """
        Processes an audio chunk to suppress feedback.
        """
        self._detect_feedback(audio_chunk)
        processed_chunk = np.copy(audio_chunk)

        for f_monitor in self.monitor_frequencies:
            b, a = self._update_notch_filters(f_monitor)
            # Apply the filter to the chunk, updating the filter states
            processed_chunk, self.filter_states[f_monitor] = apply_biquad(
                processed_chunk, b, a, self.filter_states[f_monitor]
            )
        return processed_chunk

# --- 3. Simulation Example ---
if __name__ == "__main__":
    sample_rate = 44100  # Hz
    duration = 5       # seconds
    num_samples = int(sample_rate * duration)
    time = np.linspace(0, duration, num_samples, endpoint=False)

    # Generate a "clean" audio signal (e.g., a mix of sines)
    clean_audio = (
        0.5 * np.sin(2 * np.pi * 500 * time) +
        0.3 * np.sin(2 * np.pi * 1200 * time) +
        0.2 * np.random.randn(num_samples) * 0.1 # Some noise
    )

    # Simulate feedback: a sine wave that gradually increases in amplitude
    feedback_freq = 1500 # Hz
    feedback_start_time = 2.0 # seconds
    feedback_end_time = 4.0 # seconds
    feedback_amplitude = np.zeros_like(time)

    start_idx = int(feedback_start_time * sample_rate)
    end_idx = int(feedback_end_time * sample_rate)
    
    # Ramp up feedback amplitude
    feedback_amplitude[start_idx:end_idx] = np.linspace(0, 0.8, end_idx - start_idx)
    
    # Hold max amplitude after ramp
    feedback_amplitude[end_idx:] = 0.8

    feedback_signal = feedback_amplitude * np.sin(2 * np.pi * feedback_freq * time)

    # Combine clean audio and feedback
    input_audio = clean_audio + feedback_signal
    input_audio /= np.max(np.abs(input_audio)) * 1.1 # Normalize to avoid clipping

    # Initialize feedback suppressor
    fs_suppressor = FeedbackSuppressor(
        sample_rate=sample_rate,
        num_bands=20, # More bands for finer detection
        freq_range=(500, 2000), # Focus on a specific range
        filter_q=80, # Very narrow notch
        max_gain_reduction_db=-20 # Deeper cut
    )

    # Process audio in chunks (simulating real-time processing)
    chunk_size = 512 # Number of samples per chunk
    processed_audio = np.zeros_like(input_audio)

    for i in range(0, num_samples, chunk_size):
        chunk = input_audio[i : i + chunk_size]
        if len(chunk) > 0:
            processed_chunk = fs_suppressor.process_audio(chunk)
            processed_audio[i : i + len(processed_chunk)] = processed_chunk

    # --- Plotting Results ---
    plt.figure(figsize=(15, 10))

    # Time Domain Plot
    plt.subplot(3, 1, 1)
    plt.plot(time, input_audio, label='Input Audio (with feedback)')
    plt.plot(time, processed_audio, label='Processed Audio (feedback suppressed)')
    plt.axvline(feedback_start_time, color='r', linestyle='--', label='Feedback Starts')
    plt.axvline(feedback_end_time, color='g', linestyle='--', label='Feedback Max')
    plt.title('Time Domain Audio Signal')
    plt.xlabel('Time (s)')
    plt.ylabel('Amplitude')
    plt.legend()
    plt.grid(True)
    plt.xlim(feedback_start_time - 0.5, feedback_end_time + 0.5) # Zoom in on feedback region

    # Frequency Domain (FFT) Plot - Input
    plt.subplot(3, 1, 2)
    N_fft = 4096 # FFT size for spectrum analysis
    input_fft = np.fft.fft(input_audio[:N_fft] * np.hanning(N_fft))
    freqs_fft = np.fft.fftfreq(N_fft, d=1/sample_rate)
    plt.plot(freqs_fft[:N_fft//2], 20 * np.log10(np.abs(input_fft[:N_fft//2]) + 1e-10), label='Input Spectrum')
    plt.axvline(feedback_freq, color='r', linestyle='--', label=f'Feedback Freq: {feedback_freq} Hz')
    plt.title('Frequency Spectrum (Input)')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Magnitude (dB)')
    plt.xlim(0, 3000)
    plt.ylim(-80, 0)
    plt.legend()
    plt.grid(True)

    # Frequency Domain (FFT) Plot - Processed
    plt.subplot(3, 1, 3)
    processed_fft = np.fft.fft(processed_audio[:N_fft] * np.hanning(N_fft))
    plt.plot(freqs_fft[:N_fft//2], 20 * np.log10(np.abs(processed_fft[:N_fft//2]) + 1e-10), label='Processed Spectrum')
    plt.axvline(feedback_freq, color='r', linestyle='--', label=f'Feedback Freq: {feedback_freq} Hz')
    plt.title('Frequency Spectrum (Processed)')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Magnitude (dB)')
    plt.xlim(0, 3000)
    plt.ylim(-80, 0)
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    plt.show()
