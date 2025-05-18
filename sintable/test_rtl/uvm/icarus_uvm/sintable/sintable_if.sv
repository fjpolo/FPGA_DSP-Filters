`timescale 1ps/1ps

interface sintable_if(input bit clk);
    logic reset_n;
    logic [7:0] data_in;
    logic [7:0] data_out;
    
    clocking drv_cb @(posedge clk);
        default input #1 output #1;
        output reset_n;
        output data_in;
        input data_out;
    endclocking
    
    modport driver(clocking drv_cb);
endinterface