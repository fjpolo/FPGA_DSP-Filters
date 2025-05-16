import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import argparse

def design_fir_filter(fs, fc, stopband, numtaps, M):
    """Design and quantize FIR filter coefficients"""
    # Design filter using Parks-McClellan algorithm
    taps = signal.remez(numtaps, [0, fc, stopband, fs/2], [1, 0], fs=fs)
    
    # Quantize coefficients
    max_coeff = np.max(np.abs(taps))
    scale_factor = (2**(M-1) - 1) / max_coeff
    quantized_taps = np.round(taps * scale_factor)
    
    # Check for overflow
    assert np.max(np.abs(quantized_taps)) <= 2**(M-1) - 1, "Coefficient overflow!"
    
    return taps, quantized_taps, scale_factor

def plot_response(taps, quantized_taps, scale_factor, fs, fc, stopband):
    """Plot frequency responses of original and quantized filters"""
    plt.figure(figsize=(12, 8))
    
    # Original response
    w, h = signal.freqz(taps, fs=fs)
    plt.plot(w, 20 * np.log10(abs(h)), label='Original')
    
    # Quantized response
    w_q, h_q = signal.freqz(quantized_taps/scale_factor, fs=fs)
    plt.plot(w_q, 20 * np.log10(abs(h_q)), label='Quantized')
    
    # Design markers
    plt.axvline(fc, color='red', linestyle='--', alpha=0.5, label='Cutoff')
    plt.axvline(stopband, color='green', linestyle='--', alpha=0.5, label='Stopband')
    plt.axhline(-60, color='orange', linestyle='--', alpha=0.5, label='-60 dB')
    plt.axhline(-0.1, color='blue', linestyle='--', alpha=0.5, label='-0.1 dB')
    
    plt.title('FIR Filter Frequency Response')
    plt.xlabel('Frequency [Hz]')
    plt.ylabel('Amplitude [dB]')
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()

def save_coefficients(filename, coefficients, bit_width, format='hex'):
    """Save coefficients in specified format"""
    if format.lower() == 'hex':
        with open(filename, 'w') as f:
            for coeff in coefficients:
                # Convert to two's complement if negative
                if coeff < 0:
                    coeff = (1 << bit_width) + coeff
                f.write("{:0{}X}\n".format(int(coeff), bit_width // 4))
    elif format.lower() == 'coe':
        with open(filename, 'w') as f:
            f.write("memory_initialization_radix = 16;\n")
            f.write("memory_initialization_vector =\n")
            for i, coeff in enumerate(coefficients):
                if coeff < 0:
                    coeff = (1 << bit_width) + coeff
                f.write("{:04X}{}\n".format(int(coeff), "," if i < len(coefficients)-1 else ";"))
    elif format.lower() == 'mif':
        with open(filename, 'w') as f:
            f.write("DEPTH = {};\n".format(len(coefficients)))
            f.write("WIDTH = {};\n".format(bit_width))
            f.write("ADDRESS_RADIX = DEC;\n")
            f.write("DATA_RADIX = HEX;\n")
            f.write("CONTENT BEGIN\n")
            for addr, coeff in enumerate(coefficients):
                if coeff < 0:
                    coeff = (1 << bit_width) + coeff
                f.write("  {} : {:04X};\n".format(addr, int(coeff)))
            f.write("END;\n")
    else:
        raise ValueError("Unsupported format. Use 'hex', 'coe', or 'mif'")

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='FIR Filter Designer for FPGA')
    parser.add_argument('--fs', type=float, default=48000, help='Sampling frequency (Hz)')
    parser.add_argument('--fc', type=float, default=3000, help='Cutoff frequency (Hz)')
    parser.add_argument('--stopband', type=float, default=4000, help='Stopband frequency (Hz)')
    parser.add_argument('--numtaps', type=int, default=144, help='Number of filter taps')
    parser.add_argument('--bits', type=int, default=16, help='Coefficient bit width')
    parser.add_argument('--output', type=str, default='fir_coefficients.hex', help='Output filename')
    parser.add_argument('--format', type=str, default='hex', choices=['hex', 'coe', 'mif'], help='Output file format')
    parser.add_argument('--plot', action='store_true', help='Show frequency response plot')
    args = parser.parse_args()

    # Design filter
    taps, quantized_taps, scale_factor = design_fir_filter(
        fs=args.fs,
        fc=args.fc,
        stopband=args.stopband,
        numtaps=args.numtaps,
        M=args.bits
    )

    # Save coefficients
    save_coefficients(args.output, quantized_taps, args.bits, args.format)
    print(f"Saved {len(quantized_taps)} coefficients to {args.output} in {args.format} format")

    # Show plot if requested
    if args.plot:
        plot_response(taps, quantized_taps, scale_factor, args.fs, args.fc, args.stopband)

if __name__ == "__main__":
    main()