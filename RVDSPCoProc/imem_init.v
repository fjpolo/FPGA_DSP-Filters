// --- Generated from program.hex ---
integer i;
initial begin
    iMEM[0] = 32'h44000005;
    iMEM[1] = 32'h4500000A;
    iMEM[2] = 32'h46000002;
    iMEM[3] = 32'h47000003;
    iMEM[4] = 32'h90000000;
    iMEM[5] = 32'hF0460000;

    // Initialize the rest of the memory to NOP (0x00000000)
    for (i = 6; i < 256; i++) begin 
        iMEM[i] = 32'h00000000;
    end        
end
// ----------------------------------
