// --- Generated from program.hex ---
integer i;
initial begin
    iMEM[0] = 32'h41000000;
    iMEM[1] = 32'h42000000;
    iMEM[2] = 32'h43000002;
    iMEM[3] = 32'h90000000;
    iMEM[4] = 32'hA1230000;
    iMEM[5] = 32'h64000000;
    iMEM[6] = 32'h75000000;
    iMEM[7] = 32'h86000000;
    iMEM[8] = 32'h41000002;
    iMEM[9] = 32'h42000002;
    iMEM[10] = 32'h10120000;
    iMEM[11] = 32'h48000003;
    iMEM[12] = 32'h49000003;
    iMEM[13] = 32'hBA890000;
    iMEM[14] = 32'h4C00000A;
    iMEM[15] = 32'h4D000003;
    iMEM[16] = 32'hCECD0000;
    iMEM[17] = 32'h30D00000;
    iMEM[18] = 32'h30D00001;
    iMEM[19] = 32'h30D00002;
    iMEM[20] = 32'h30D00003;
    iMEM[21] = 32'h30D00004;
    iMEM[22] = 32'h30D00005;
    iMEM[23] = 32'h30D00006;
    iMEM[24] = 32'h30D00007;
    iMEM[25] = 32'h50000005;

    // Initialize the rest of the memory to NOP (0x00000000)
    for (i = 26; i < 256; i++) begin 
        iMEM[i] = 32'h00000000;
    end        
end
// ----------------------------------
