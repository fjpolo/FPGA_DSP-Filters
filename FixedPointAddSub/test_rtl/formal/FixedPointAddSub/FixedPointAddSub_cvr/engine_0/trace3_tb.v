`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [0:0] PI_i_sub;
  reg [0:0] PI_i_clk;
  reg [0:0] PI_i_start;
  reg [0:0] PI_i_rst;
  reg [7:0] PI_i_operandA;
  reg [7:0] PI_i_operandB;
  FixedPointAddSub UUT (
    .i_sub(PI_i_sub),
    .i_clk(PI_i_clk),
    .i_start(PI_i_start),
    .i_rst(PI_i_rst),
    .i_operandA(PI_i_operandA),
    .i_operandB(PI_i_operandB)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$auto$async2sync.\cc:107:execute$272  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$278  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$284  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$290  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$296  = 1'b0;
    // UUT.$auto$async2sync.\cc:107:execute$302  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$276  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$282  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$288  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$294  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$300  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$306  = 1'b1;
    UUT._witness_.anyinit_procdff_202 = 1'b0;
    UUT._witness_.anyinit_procdff_203 = 8'b00000000;
    UUT._witness_.anyinit_procdff_204 = 8'b00000000;
    UUT._witness_.anyinit_procdff_205 = 1'b0;
    UUT._witness_.anyinit_procdff_206 = 8'b00000000;
    UUT._witness_.anyinit_procdff_207 = 8'b00000000;
    UUT._witness_.anyinit_procdff_208 = 1'b0;
    UUT._witness_.anyinit_procdff_209 = 8'b00000000;
    UUT._witness_.anyinit_procdff_210 = 8'b00000000;
    UUT._witness_.anyinit_procdff_211 = 1'b0;
    UUT._witness_.anyinit_procdff_212 = 1'b0;
    UUT._witness_.anyinit_procdff_213 = 1'b0;
    UUT.f_past_valid = 1'b0;
    UUT.o_busy = 1'b0;
    UUT.o_data = 8'b00000000;
    UUT.o_done = 1'b0;
    UUT.o_overflow = 1'b0;
    UUT.o_valid = 1'b0;

    // state 0
    PI_i_sub = 1'b0;
    PI_i_clk = 1'b0;
    PI_i_start = 1'b1;
    PI_i_rst = 1'b0;
    PI_i_operandA = 8'b10000000;
    PI_i_operandB = 8'b10000000;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 2
    if (cycle == 1) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 3
    if (cycle == 2) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 4
    if (cycle == 3) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 5
    if (cycle == 4) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 6
    if (cycle == 5) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 7
    if (cycle == 6) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 8
    if (cycle == 7) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 9
    if (cycle == 8) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 10
    if (cycle == 9) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 11
    if (cycle == 10) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 12
    if (cycle == 11) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 13
    if (cycle == 12) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 14
    if (cycle == 13) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 15
    if (cycle == 14) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 16
    if (cycle == 15) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 17
    if (cycle == 16) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 18
    if (cycle == 17) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 19
    if (cycle == 18) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 20
    if (cycle == 19) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 21
    if (cycle == 20) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    // state 22
    if (cycle == 21) begin
      PI_i_sub <= 1'b0;
      PI_i_clk <= 1'b0;
      PI_i_start <= 1'b0;
      PI_i_rst <= 1'b0;
      PI_i_operandA <= 8'b00000000;
      PI_i_operandB <= 8'b00000000;
    end

    genclock <= cycle < 22;
    cycle <= cycle + 1;
  end
endmodule
