import numpy as np
import matplotlib.pyplot as plt

class LinearCompressor:
    """
    Models the fixed-point linear compressor logic.
    Uses linear magnitude, threshold, and ratio for gain calculation.
    """
    def __init__(self, sample_rate, threshold_lin, ratio, attack_ms, release_ms):
        self.sample_rate = sample_rate
        self.threshold = threshold_lin
        self.ratio = ratio

        # Pre-calculate (1 - 1/Ratio), which is R_DIFF in the Verilog
        self.r_diff = 1.0 - (1.0 / self.ratio)

        # Calculate Attack and Release coefficients (1-alpha)
        # These are equivalent to ATTACK_COEFF_FP and RELEASE_COEFF_FP in the Verilog
        # alpha = exp(-2.2 / (T * Fs)) for 10% to 90% rise/fall time T
        # Or, simpler fixed-point-friendly model: alpha = exp(-1 / (tau * Fs))
        def calculate_coeff(time_ms):
            time_s = time_ms / 1000.0
            # (1-alpha) term for the IIR filter: y[n] = y[n-1] + (x[n] - y[n-1]) * (1-alpha)
            # We use the (1-alpha) calculation directly, but model the difference
            # See: CCRMA DSP Toolkit or similar for exact fixed-point conversion
            # For prototyping, we model the time constants:
            return 1.0 - np.exp(-1.0 / (time_s * sample_rate))

        # We're interested in the (1-alpha) term, which is the feed-forward coefficient.
        self.alpha_attack_ff = calculate_coeff(attack_ms)
        self.alpha_release_ff = calculate_coeff(release_ms)

        # Internal state (Q1.15 in Verilog)
        self.linear_env = 0.0 # Envelope magnitude (linear)

        print(f"(1-alpha) Attack: {self.alpha_attack_ff:.4f}, (1-alpha) Release: {self.alpha_release_ff:.4f}")

    def process(self, input_signal):
        """Processes a block of audio samples using the linear algorithm."""
        output_signal = np.zeros_like(input_signal)
        
        for n, x in enumerate(input_signal):
            # Stage 1: Absolute Value (Magnitude)
            linear_mag = np.abs(x)

            # Stage 2: Envelope Detection (Linear IIR)
            # y[n] = y[n-1] + (x[n] - y[n-1]) * (1-alpha)

            # Determine coefficient based on rising (Attack) or falling (Release)
            if linear_mag > self.linear_env:
                alpha_ff = self.alpha_attack_ff
            else:
                alpha_ff = self.alpha_release_ff
            
            # Apply IIR filter:
            self.linear_env = self.linear_env + (linear_mag - self.linear_env) * alpha_ff

            # Stage 3: Static Gain Calculation (Linear)
            if self.linear_env > self.threshold:
                # Overshoot = Env - Threshold
                overshoot = self.linear_env - self.threshold
                
                # Compression_Depth = Overshoot * (1 - 1/Ratio)
                # Compression_Depth = Overshoot * R_DIFF
                compression_depth = overshoot * self.r_diff
                
                # Target Gain = 1.0 - Compression_Depth
                target_gain = 1.0 - compression_depth
                
                # Ensure gain is not negative (or > 1.0, though it shouldn't be)
                target_gain = np.clip(target_gain, 0.0, 1.0)
            else:
                # Below threshold, target gain is 1.0 (no compression)
                target_gain = 1.0
            
            # Stage 4 & 5: Apply Gain
            # We skip the gain smoothing stage for simplicity, similar to the Verilog bypass
            output_signal[n] = x * target_gain
            
        return output_signal

# ----------------- Test Bench -----------------
SAMPLE_RATE = 48000
DURATION = 0.5  # seconds

# Create a test signal: a soft sine wave followed by a loud burst
t = np.linspace(0, DURATION, int(SAMPLE_RATE * DURATION), endpoint=False)
signal_freq = 440
soft_level = 0.3
loud_level = 0.9

# Create a signal that is soft, then bursts loud
signal_start = np.sin(2 * np.pi * signal_freq * t[:int(SAMPLE_RATE*0.1)]) * soft_level
signal_burst = np.sin(2 * np.pi * signal_freq * t[int(SAMPLE_RATE*0.1):]) * loud_level
input_signal = np.concatenate((signal_start, signal_burst))

# Instantiate the Linear Compressor
# Parameters matching common fixed-point choices:
THRESHOLD_DB = -6.0
comp = LinearCompressor(
    sample_rate=SAMPLE_RATE,
    threshold_lin=10**(THRESHOLD_DB / 20), # Linear threshold (0.501 for -6dB)
    ratio=4.0,                             # 4:1 compression ratio
    attack_ms=5.0,                         # Fast attack (5 ms)
    release_ms=100.0                       # Medium release (100 ms)
)

# Process the signal
output_signal = comp.process(input_signal)

# ----------------- Plotting Results -----------------
fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True, figsize=(10, 6))

# Plot Input and Output
ax1.plot(t, input_signal, label='Input Signal (Soft then Loud)', alpha=0.7)
ax1.plot(t, output_signal, label='Output Signal (Compressed)', alpha=0.9)
ax1.axhline(comp.threshold, color='r', linestyle='--', label=f'Threshold ({THRESHOLD_DB:.1f} dB)')
ax1.set_ylabel('Amplitude (Linear)')
ax1.set_title(f'Linear Dynamic Compressor Test (Ratio {comp.ratio}:1, Thresh {THRESHOLD_DB:.1f} dB)')
ax1.legend(loc='upper right')
ax1.grid(True, which='both', linestyle=':', linewidth=0.5)

# Plot Gain Reduction
# Calculate instantaneous gain (Output/Input) and convert to dB
# Use a small epsilon (1e-6) to avoid log(0)
gain_applied_db = 20 * np.log10(np.abs(output_signal) / (np.abs(input_signal) + 1e-6))
gain_reduction_db = np.clip(gain_applied_db, -20, 0) # Only show negative gain (reduction)

ax2.plot(t, gain_reduction_db, label='Applied Gain Reduction (dB)')
ax2.set_xlabel('Time (s)')
ax2.set_ylabel('Gain (dB)')
ax2.axhline(0, color='k', linestyle='-')
ax2.set_ylim(-15, 1) # Focus on the reduction
ax2.legend(loc='lower right')
ax2.grid(True, which='both', linestyle=':', linewidth=0.5)

plt.tight_layout()
plt.show()