import numpy as np
import matplotlib.pyplot as plt

def boxcar_average_filter(data, num_samples):
    """
    Applies a boxcar average filter to the input data.

    Args:
        data: A list or numpy array of numerical data.
        num_samples: The number of samples to average.

    Returns:
        A numpy array of the filtered data.
    """

    if num_samples <= 0:
        raise ValueError("Number of samples must be positive.")

    if len(data) < num_samples:
        raise ValueError("Data length must be greater than or equal to num_samples.")

    filtered_data = np.convolve(data, np.ones(num_samples), 'valid') / num_samples
    return filtered_data

def generate_test_data(data_width, noise_level=0.5):
    """
    Generates test data with added noise.

    Args:
        data_width: The number of data points to generate.
        noise_level: The standard deviation of the added noise.

    Returns:
        A numpy array of test data.
    """
    signal = np.sin(np.linspace(0, 4 * np.pi, data_width))
    noise = np.random.normal(0, noise_level, data_width)
    return signal + noise

def main():
    try:
        data_width = int(input("Enter the DATA_WIDTH (number of data points): "))
        num_samples = int(input("Enter the NUM_SAMPLES (number of samples to average): "))
    except ValueError:
        print("Invalid input. Please enter integers.")
        return

    test_data = generate_test_data(data_width)

    try:
        filtered_data = boxcar_average_filter(test_data, num_samples)
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