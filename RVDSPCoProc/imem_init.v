// --- Generated from program.hex ---
integer i;
initial begin
    i_mem[0] = 32'h41000000;
    i_mem[1] = 32'h42000000;
    i_mem[2] = 32'h43000002;
    i_mem[3] = 32'h90000000;
    i_mem[4] = 32'hA1230000;
    i_mem[5] = 32'h64000000;
    i_mem[6] = 32'h75000000;
    i_mem[7] = 32'h86000000;
    i_mem[8] = 32'h41000002;
    i_mem[9] = 32'h42000002;
    i_mem[10] = 32'h10120000;
    i_mem[11] = 32'h48000003;
    i_mem[12] = 32'h49000003;
    i_mem[13] = 32'hBA890000;
    i_mem[14] = 32'h4C00000A;
    i_mem[15] = 32'h4D000003;
    i_mem[16] = 32'hCECD0000;
    i_mem[17] = 32'h50000005;

    // Initialize the rest of the memory to NOP (0x00000000)
    for (i = 18; i < 256; i++) begin 
        i_mem[i] = 32'h00000000;
    end        
    start_flag = 1'b1;
end
// ----------------------------------
