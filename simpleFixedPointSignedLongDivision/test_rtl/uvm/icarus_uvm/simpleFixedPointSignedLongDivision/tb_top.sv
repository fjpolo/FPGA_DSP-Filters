`timescale 1ps/1ps
// Remove the uvm_macros.svh include

module tb_top;
    bit i_clk;
    logic reset_n;
    logic [7:0] data_in;
    logic [7:0] data_out;
    
    // Clock generation
    initial begin
        i_clk = 0;
        forever #500 i_clk = ~i_clk; // 1GHz clock
    end
    
    // DUT instantiation
    simpleFixedPointSignedLongDivision dut (
        .i_clk(i_clk),
        .i_reset_n(reset_n),
        .i_data(data_in),
        .o_data(data_out)
    );
    
    // Simple test
    initial begin
        reset_n = 0;
        data_in = 0;
        #1000 reset_n = 1;
        
        // Simple stimulus
        for (int i = 0; i < 10; i++) begin
            data_in = $random;
            @(posedge i_clk);
        end
        
        $display("Test completed");
        $finish;
    end
endmodule