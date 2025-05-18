`timescale 1ps/1ps
`include "uvm_macros.svh"

module tb_top;
    import uvm_pkg::*;
    
    bit clk;
    sintable_if vif(clk);
    
    // Instantiate DUT
    dut_wrapper dut (
        .i_clk(clk),
        .i_reset_n(vif.reset_n),
        .i_data(vif.data_in),
        .o_data(vif.data_out)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #500 clk = ~clk; // 1GHz clock
    end
    
    initial begin
        // Store interface in config DB
        uvm_config_db#(virtual sintable_if)::set(null, "*", "vif", vif);
        
        // Start test
        run_test("sintable_test");
    end
    
    // Initial reset
    initial begin
        vif.reset_n = 0;
        #1000 vif.reset_n = 1;
    end
endmodule