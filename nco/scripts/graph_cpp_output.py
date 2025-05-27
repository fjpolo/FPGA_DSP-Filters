import matplotlib.pyplot as plt
import re

# The raw string data containing the NCO samples
nco_output_data = """
Generating NCO samples with frequency: 0.01
----------------------------------------------------
Sample 0: 0.0613207
Sample 1: 0.122411
Sample 2: 0.18304
Sample 3: 0.24298
Sample 4: 0.30785
Sample 5: 0.365613
Sample 6: 0.422
Sample 7: 0.476799
Sample 8: 0.534998
Sample 9: 0.585798
Sample 10: 0.634393
Sample 11: 0.680601
Sample 12: 0.728464
Sample 13: 0.769103
Sample 14: 0.806848
Sample 15: 0.841555
Sample 16: 0.87607
Sample 17: 0.903989
Sample 18: 0.928506
Sample 19: 0.949528
Sample 20: 0.968522
Sample 21: 0.981964
Sample 22: 0.99171
Sample 23: 0.997723
Sample 24: 0.999981
Sample 25: 0.998118
Sample 26: 0.99248
Sample 27: 0.983105
Sample 28: 0.970031
Sample 29: 0.951435
Sample 30: 0.930767
Sample 31: 0.906596
Sample 32: 0.879012
Sample 33: 0.844854
Sample 34: 0.810457
Sample 35: 0.77301
Sample 36: 0.732654
Sample 37: 0.685084
Sample 38: 0.639124
Sample 39: 0.59076
Sample 40: 0.540171
Sample 41: 0.482184
Sample 42: 0.427555
Sample 43: 0.371317
Sample 44: 0.313682
Sample 45: 0.248928
Sample 46: 0.189069
Sample 47: 0.128498
Sample 48: 0.0674439
Sample 49: 0.00613588
Sample 50: -0.0613207
Sample 51: -0.122411
Sample 52: -0.18304
Sample 53: -0.24298
Sample 54: -0.30785
Sample 55: -0.365613
Sample 56: -0.422
Sample 57: -0.476799
Sample 58: -0.534998
Sample 59: -0.585798
Sample 60: -0.634393
Sample 61: -0.680601
Sample 62: -0.728464
Sample 63: -0.769103
Sample 64: -0.806848
Sample 65: -0.841555
Sample 66: -0.87607
Sample 67: -0.903989
Sample 68: -0.928506
Sample 69: -0.949528
Sample 70: -0.968522
Sample 71: -0.981964
Sample 72: -0.99171
Sample 73: -0.997723
Sample 74: -0.999981
Sample 75: -0.998118
Sample 76: -0.99248
Sample 77: -0.983105
Sample 78: -0.970031
Sample 79: -0.951435
Sample 80: -0.930767
Sample 81: -0.906596
Sample 82: -0.879012
Sample 83: -0.844854
Sample 84: -0.810457
Sample 85: -0.77301
Sample 86: -0.732654
Sample 87: -0.685084
Sample 88: -0.639124
Sample 89: -0.59076
Sample 90: -0.540171
Sample 91: -0.482184
Sample 92: -0.427555
Sample 93: -0.371317
Sample 94: -0.313682
Sample 95: -0.248928
Sample 96: -0.189069
Sample 97: -0.128498
Sample 98: -0.0674439
Sample 99: -0.00613588
Sample 100: 0.0613207
Sample 101: 0.122411
Sample 102: 0.18304
Sample 103: 0.24298
Sample 104: 0.30785
Sample 105: 0.365613
Sample 106: 0.422
Sample 107: 0.476799
Sample 108: 0.534998
Sample 109: 0.585798
Sample 110: 0.634393
Sample 111: 0.680601
Sample 112: 0.728464
Sample 113: 0.769103
Sample 114: 0.806848
Sample 115: 0.841555
Sample 116: 0.87607
Sample 117: 0.903989
Sample 118: 0.928506
Sample 119: 0.949528
Sample 120: 0.968522
Sample 121: 0.981964
Sample 122: 0.99171
Sample 123: 0.997723
Sample 124: 0.999981
Sample 125: 0.998118
Sample 126: 0.99248
Sample 127: 0.983105
Sample 128: 0.970031
Sample 129: 0.951435
Sample 130: 0.930767
Sample 131: 0.906596
Sample 132: 0.879012
Sample 133: 0.844854
Sample 134: 0.810457
Sample 135: 0.77301
Sample 136: 0.732654
Sample 137: 0.685084
Sample 138: 0.639124
Sample 139: 0.59076
Sample 140: 0.540171
Sample 141: 0.482184
Sample 142: 0.427555
Sample 143: 0.371317
Sample 144: 0.313682
Sample 145: 0.248928
Sample 146: 0.189069
Sample 147: 0.128498
Sample 148: 0.0674439
Sample 149: 0.00613588
Sample 150: -0.0613207
Sample 151: -0.122411
Sample 152: -0.18304
Sample 153: -0.24298
Sample 154: -0.30785
Sample 155: -0.365613
Sample 156: -0.422
Sample 157: -0.476799
Sample 158: -0.534998
Sample 159: -0.585798
Sample 160: -0.634393
Sample 161: -0.680601
Sample 162: -0.728464
Sample 163: -0.769103
Sample 164: -0.806848
Sample 165: -0.841555
Sample 166: -0.87607
Sample 167: -0.903989
Sample 168: -0.928506
Sample 169: -0.949528
Sample 170: -0.968522
Sample 171: -0.981964
Sample 172: -0.99171
Sample 173: -0.997723
Sample 174: -0.999981
Sample 175: -0.998118
Sample 176: -0.99248
Sample 177: -0.983105
Sample 178: -0.970031
Sample 179: -0.951435
Sample 180: -0.930767
Sample 181: -0.906596
Sample 182: -0.879012
Sample 183: -0.844854
Sample 184: -0.810457
Sample 185: -0.77301
Sample 186: -0.732654
Sample 187: -0.685084
Sample 188: -0.639124
Sample 189: -0.59076
Sample 190: -0.540171
Sample 191: -0.482184
Sample 192: -0.427555
Sample 193: -0.371317
Sample 194: -0.313682
Sample 195: -0.248928
Sample 196: -0.189069
Sample 197: -0.128498
Sample 198: -0.0674439
Sample 199: -0.00613588
"""

# Lists to store the parsed data
sample_numbers = []
sample_values = []

# Use regular expressions to extract sample number and value
# The regex looks for "Sample X: Y" where X is the sample number and Y is the float value.
for line in nco_output_data.splitlines():
    match = re.match(r"Sample (\d+): ([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)", line)
    if match:
        sample_num = int(match.group(1))
        sample_val = float(match.group(2))
        sample_numbers.append(sample_num)
        sample_values.append(sample_val)

# Create the plot
plt.figure(figsize=(12, 6)) # Set the figure size for better readability
plt.plot(sample_numbers, sample_values, marker='o', linestyle='-', markersize=4, color='skyblue')

# Add titles and labels
plt.title('NCO Output Samples (Sine Wave)', fontsize=16)
plt.xlabel('Sample Number', fontsize=12)
plt.ylabel('Amplitude', fontsize=12)

# Add a grid for easier reading of values
plt.grid(True, linestyle='--', alpha=0.7)

# Set y-axis limits to clearly show the sine wave range
plt.ylim(-1.1, 1.1)

# Display the plot
plt.show()
