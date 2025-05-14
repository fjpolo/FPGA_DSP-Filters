# hsFIR Module

This Verilog module implements...

## Features

* Easily reconfigurable
* Runs at the system clock rate, one input sample per system clock

⚠️ The sad consequence of these choices is that this is also likely to be one of the more expensive digital filters you will ever build. However, we shall build it anyway and later discuss methods which may be used to reduce this cost: [A Cheaper Fast FIR Filter](https://zipcpu.com/dsp/2017/09/29/cheaper-fast-fir.html)

This design will be applied to an audio application, a FIR LPF with a fc=3kHz, fp=4kHz and fs=48kHz.

## Usage

1. **Instantiate the module:**

   ```verilog
   hsFIR #(
       // Optional parameters here 
   ) hsFIR (
       .clk(clk),           // Input
       .reset_n(reset_n),   // Input - active low
       .data_in(data_in),   // Input
       .data_out(data_out)  // Output
   );

## References

[Building a high speed Finite Impulse Response (FIR) Digital Filter](https://zipcpu.com/dsp/2017/09/15/fastfir.html)