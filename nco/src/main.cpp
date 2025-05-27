#include <iostream> // Required for input/output operations (e.g., std::cout)
#include "../include/nco.h"

int main() {
    // Define the logarithm of the table size for the NCO.
    // A value of 10 means the table will have 2^10 = 1024 entries.
    const int LG_TABLE_SIZE = 10;

    // Create an instance of the NCO.
    // The constructor takes the logarithm of the table size.
    NCO myNCO(LG_TABLE_SIZE);

    // Set the desired output frequency for the NCO.
    // This value is relative to the NCO's internal SAMPLE_RATE.
    // For example, if SAMPLE_RATE is 1.0, a frequency of 0.1 means 0.1 cycles per sample.
    float desiredFrequency = 0.01f; // A small frequency to see multiple cycles over many samples
    myNCO.frequency(desiredFrequency);

    std::cout << "Generating NCO samples with frequency: " << desiredFrequency << std::endl;
    std::cout << "----------------------------------------------------" << std::endl;

    // Generate and print a few samples from the NCO.
    // The NCO's operator() generates the next sample.
    const int NUM_SAMPLES = 200; // Number of samples to generate

    for (int i = 0; i < NUM_SAMPLES; ++i) {
        // Call the NCO object as a function to get the next sample value.
        float sample = myNCO();

        // Print the sample number and its value.
        std::cout << "Sample " << i << ": " << sample << std::endl;
    }

    std::cout << "----------------------------------------------------" << std::endl;
    std::cout << "NCO sample generation complete." << std::endl;

    return 0; // Indicate successful execution
}