# boxcar_filter Module

This Verilog module implements...

## Features

* Feature1
* Feature2
* Feature3

## Requirements

Linux or macOS with [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build/releases) installed in `home/<username>/oss-cad-suite/`

## Usage

1. **Instantiate the module:**

   ```verilog
   boxcar_filter #(
       // Optional parameters here 
   ) boxcar_filter (
       .clk(clk),           // Input
       .reset_n(reset_n),   // Input - active low
       .data_in(data_in),   // Input
       .data_out(data_out)  // Output
   );

## Validation

This module uses [`icarus verilog`](https://github.com/steveicarus/iverilog), [`symbiyosys`](https://github.com/YosysHQ/sby), [`equivalence checking wiht yosys`](https://github.com/YosysHQ/eqy) and [`mutation cover with yosys`](https://github.com/YosysHQ/mcy) to get a `xxx% mutation test coverage`!

With a mixture of simulation and formal verification, it's ensured that every and each mutation possible (xxx) are detected either by the testbench, equivalence checking or formal properties. A whitebox testing approach has been used testbench simulation but not for formal verification in order to catch internal module's mutations.

`mcy` spits out a report:

```

```

Results: 

![Results](./images/mcy_results.png)

The mutations the testbench can't catch (test_sim PASS), are either catched by equivalence checking or formal verification! And a `xxx%` coverage is achieved!

![Graphs](./images/mcy_graphs.png)

### Usage

Linux/macOS
```bash
/$ cd test_rtl && ./test_all_log.sh
```

This will generate a `test_log.txt` in `test_rtl/`, and more logs in `<test_rtl/<dir>/boxcar_filter/boxcar_filter.txt`

## Synthesis

There's a little yosys synth script in `boxcar_filter/test_rtl/synth/boxcar_filter/boxcar_filter.ys`for Tang Nano 20k, but it's untested.

```

```

Also, there's a Tang Nano 9k Gowin IDE project in `boxcar_filter/gowin/nano9k/boxcar_filter.gprj`, to check STA, but also, sofar unused.
