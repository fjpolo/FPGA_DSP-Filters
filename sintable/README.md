# sintable Module

This Verilog module implements...

## Features

* Feature1
* Feature2
* Feature3

## Usage

1. **Instantiate the module:**

```verilog
module	sintable #(
	parameter	                PW =17, // Number of bits in the input phase
			                    OW =13  // Number of output bits
	) (
	input	wire			    i_clk,
	input	wire			    i_reset,
	input	wire			    i_ce,
	input	wire	[(PW-1):0]	i_phase,
	output	reg	    [(OW-1):0]	o_val
    );
```

## References

[The simplest sine wave generator within an FPGA](https://zipcpu.com/dsp/2017/07/11/simplest-sinewave-generator.html)