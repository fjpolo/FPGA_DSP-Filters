import numpy as np
import matplotlib.pyplot as plt

def boxcar_average_filter(data, num_samples, data_width):
    """
    Applies a boxcar average filter to the input data.

    Args:
        data: A list or numpy array of numerical data.
        num_samples: The number of samples to average.
        data_width: The bit width of the data (e.g., 8, 16, 32).

    Returns:
        A numpy array of the filtered data.
    """

    if num_samples <= 0:
        raise ValueError("Number of samples must be positive.")

    if len(data) < num_samples:
        raise ValueError("Data length must be greater than or equal to num_samples.")

    filtered_data = np.convolve(data, np.ones(num_samples), 'valid') / num_samples

    # In a hardware implementation, you'd likely need to consider
    # overflow/underflow based on the data_width here.
    # For a software implementation, we can just print the data width.
    print(f"Data Width: {data_width} bits")

    return filtered_data

def generate_test_data(num_data_points, noise_level=0.5):
    """
    Generates test data with added noise.

    Args:
        num_data_points: The number of data points to generate.
        noise_level: The standard deviation of the added noise.

    Returns:
        A numpy array of test data.
    """
    signal = np.sin(np.linspace(0, 4 * np.pi, num_data_points))
    noise = np.random.normal(0, noise_level, num_data_points)
    return signal + noise

def main():
    try:
        num_data_points = int(input("Enter the number of data points: "))
        num_samples = int(input("Enter the NUM_SAMPLES (number of samples to average): "))
        data_width = int(input("Enter the DATA_WIDTH (bit width, e.g., 8, 16, 32): "))
    except ValueError:
        print("Invalid input. Please enter integers.")
        return

    test_data = generate_test_data(num_data_points)

    try:
        filtered_data = boxcar_average_filter(test_data, num_samples, data_width)
    except ValueError as e:
        print(f"Error: {e}")
        return

    # Plotting
    plt.figure(figsize=(12, 6))

    plt.subplot(2, 1, 1)
    plt.plot(test_data, label='Original Data', alpha=0.7)
    plt.title('Original Data')
    plt.legend()

    plt.subplot(2, 1, 2)
    plt.plot(filtered_data, label=f'Filtered Data (Boxcar, {num_samples} samples)', color='red')
    plt.title('Filtered Data')
    plt.legend()

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()