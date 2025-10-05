import numpy as np
import matplotlib.pyplot as plt

class Compressor:
    """
    A basic feedback dynamic range compressor.
    
    Uses simple one-pole filters for attack and release envelopes 
    to calculate the gain smoothing.
    """
    def __init__(self, sample_rate, threshold_db, ratio, attack_ms, release_ms):
        self.sample_rate = sample_rate
        self.threshold = 10**(threshold_db / 20)  # Convert dB to linear amplitude
        self.ratio = ratio
        
        # Calculate Attack and Release coefficients (one-pole filter)
        # alpha = exp(-1 / (tau * Fs)) where tau = T / ln(e)
        attack_time_s = attack_ms / 1000.0
        release_time_s = release_ms / 1000.0
        
        self.attack_coeff = np.exp(-1.0 / (attack_time_s * sample_rate))
        self.release_coeff = np.exp(-1.0 / (release_time_s * sample_rate))
        
        # Internal states
        self.env_in_mag = 0.0  # Input envelope magnitude (linear)
        self.gain_smooth = 1.0 # Smoothed gain (linear)
        
        print(f"Attack Coeff: {self.attack_coeff:.4f}, Release Coeff: {self.release_coeff:.4f}")

    def process(self, input_signal):
        """Processes a block of audio samples."""
        output_signal = np.zeros_like(input_signal)
        
        for n, x in enumerate(input_signal):
            # 1. Magnitude Detection (Peak/Absolute value)
            abs_x = np.abs(x)

            # 2. Envelope Smoothing (The core of Attack/Release)
            # Use a slightly different formula for attack and release to model dynamics
            if abs_x > self.env_in_mag:
                # Attack: Input is rising, use the faster attack coefficient
                self.env_in_mag = (self.attack_coeff * self.env_in_mag) + ((1.0 - self.attack_coeff) * abs_x)
            else:
                # Release: Input is falling, use the slower release coefficient
                self.env_in_mag = (self.release_coeff * self.env_in_mag) + ((1.0 - self.release_coeff) * abs_x)

            # 3. Static Gain Calculation (Linear)
            if self.env_in_mag > self.threshold:
                # Calculate the desired linear gain for the current envelope level
                # Gain_dB = (Threshold_dB - Input_dB) * (1 - 1/Ratio)
                # Gain_linear = 10^(Gain_dB / 20)
                
                # Formula for linear gain based on input/threshold/ratio:
                # G = (E_in / T)^(1/R - 1) * T^(1/R - 1) * 1  <-- this is complex.
                
                # Simpler: Calculate gain reduction in dB, then convert to linear
                env_in_db = 20 * np.log10(self.env_in_mag) if self.env_in_mag > 1e-6 else -120.0
                threshold_db = 20 * np.log10(self.threshold)
                
                # Gain Reduction (GR) in dB
                gain_reduction_db = (threshold_db - env_in_db) * (1.0 - (1.0 / self.ratio))
                
                # Convert to Linear Target Gain
                target_gain = 10**(gain_reduction_db / 20.0)
            else:
                # Below threshold, target gain is 1.0 (no compression)
                target_gain = 1.0
            
            # 4. Final Gain Smoothing (prevents gain jumps and 'thumps')
            # This is often set to the release time for simplicity or ignored if step 2 is smooth enough
            # We'll stick to a simple release model for the final stage as well
            self.gain_smooth = (self.release_coeff * self.gain_smooth) + ((1.0 - self.release_coeff) * target_gain)

            # 5. Apply Gain
            output_signal[n] = x * self.gain_smooth
            
        return output_signal

# --- Test Bench ---
SAMPLE_RATE = 48000
DURATION = 0.5  # seconds

# Create a test signal: a soft sine wave followed by a loud burst
t = np.linspace(0, DURATION, int(SAMPLE_RATE * DURATION), endpoint=False)
signal_start = np.sin(2 * np.pi * 440 * t[:int(SAMPLE_RATE*0.1)]) * 0.2
signal_burst = np.sin(2 * np.pi * 440 * t[int(SAMPLE_RATE*0.1):]) * 0.9

input_signal = np.concatenate((signal_start, signal_burst))

# Instantiate the Compressor
comp = Compressor(
    sample_rate=SAMPLE_RATE,
    threshold_db=-10.0, # Start compressing above -10 dB
    ratio=4.0,           # 4:1 compression ratio
    attack_ms=5.0,       # Fast attack (5 ms)
    release_ms=100.0     # Medium release (100 ms)
)

# Process the signal
output_signal = comp.process(input_signal)

# --- Plotting ---
fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True, figsize=(10, 6))

# Plot Input and Output
ax1.plot(t, input_signal, label='Input Signal (Soft then Loud)', alpha=0.7)
ax1.plot(t, output_signal, label='Output Signal (Compressed)', alpha=0.9)
ax1.axhline(comp.threshold, color='r', linestyle='--', label='Threshold (Linear)')
ax1.set_ylabel('Amplitude')
ax1.set_title(f'Dynamic Compressor Test (Ratio {comp.ratio}:1, Thresh {20*np.log10(comp.threshold):.1f} dB)')
ax1.legend(loc='upper right')
ax1.grid(True, which='both', linestyle=':', linewidth=0.5)

# Plot Gain Reduction
# The gain applied is self.gain_smooth, which we can approximate for the plot
gain_applied_db = 20 * np.log10(output_signal / (input_signal + 1e-9))
ax2.plot(t, gain_applied_db, label='Applied Gain (dB)')
ax2.set_xlabel('Time (s)')
ax2.set_ylabel('Gain (dB)')
ax2.axhline(0, color='k', linestyle='-')
ax2.set_ylim(-15, 1) # Show only the negative gain reduction
ax2.legend(loc='lower right')
ax2.grid(True, which='both', linestyle=':', linewidth=0.5)

plt.tight_layout()
plt.show()