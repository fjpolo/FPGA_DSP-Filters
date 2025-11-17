// `define ORIGINAL
`ifdef ORIGINAL
module CircularBufferMulti(
  input         clock,
                reset,
  input  [2:0]  io_enqValid,
  input  [31:0] io_enqData_0_addr,
                io_enqData_0_inst,
  input         io_enqData_0_brchFwd,
  input  [31:0] io_enqData_1_addr,
                io_enqData_1_inst,
  input         io_enqData_1_brchFwd,
  input  [31:0] io_enqData_2_addr,
                io_enqData_2_inst,
  input         io_enqData_2_brchFwd,
  input  [31:0] io_enqData_3_addr,
                io_enqData_3_inst,
  input         io_enqData_3_brchFwd,
  output [3:0]  io_nEnqueued,
                io_nSpace,
  output [31:0] io_dataOut_0_addr,
                io_dataOut_0_inst,
  output        io_dataOut_0_brchFwd,
  output [31:0] io_dataOut_1_addr,
                io_dataOut_1_inst,
  output        io_dataOut_1_brchFwd,
  output [31:0] io_dataOut_2_addr,
                io_dataOut_2_inst,
  output        io_dataOut_2_brchFwd,
  output [31:0] io_dataOut_3_addr,
                io_dataOut_3_inst,
  output        io_dataOut_3_brchFwd,
  input  [2:0]  io_deqReady,
  input         io_flush
) /*synthesis syn_ramstyle="block_ram"*/;

  reg  [31:0]  buffer_0_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_0_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_0_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_1_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_1_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_1_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_2_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_2_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_2_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_3_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_3_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_3_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_4_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_4_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_4_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_5_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_5_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_5_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_6_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_6_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_6_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_7_addr    /*synthesis syn_ramstyle="block_ram"*/;
  reg  [31:0]  buffer_7_inst    /*synthesis syn_ramstyle="block_ram"*/;
  reg          buffer_7_brchFwd /*synthesis syn_ramstyle="block_ram"*/;
  reg  [2:0]   enqPtr           /*synthesis syn_ramstyle="block_ram"*/;
  reg  [2:0]   deqPtr           /*synthesis syn_ramstyle="block_ram"*/;
  reg  [3:0]   nEnqueued        /*synthesis syn_ramstyle="block_ram"*/;
  wire [9:0]   _outputBufferView_rotated_T_9 = {7'h0, deqPtr} * 10'h41;
  wire [519:0] _outputBufferView_rotated_T_23 =
    _outputBufferView_rotated_T_9[0]
      ? {buffer_0_brchFwd,
         buffer_7_addr,
         buffer_7_inst,
         buffer_7_brchFwd,
         buffer_6_addr,
         buffer_6_inst,
         buffer_6_brchFwd,
         buffer_5_addr,
         buffer_5_inst,
         buffer_5_brchFwd,
         buffer_4_addr,
         buffer_4_inst,
         buffer_4_brchFwd,
         buffer_3_addr,
         buffer_3_inst,
         buffer_3_brchFwd,
         buffer_2_addr,
         buffer_2_inst,
         buffer_2_brchFwd,
         buffer_1_addr,
         buffer_1_inst,
         buffer_1_brchFwd,
         buffer_0_addr,
         buffer_0_inst}
      : {buffer_7_addr,
         buffer_7_inst,
         buffer_7_brchFwd,
         buffer_6_addr,
         buffer_6_inst,
         buffer_6_brchFwd,
         buffer_5_addr,
         buffer_5_inst,
         buffer_5_brchFwd,
         buffer_4_addr,
         buffer_4_inst,
         buffer_4_brchFwd,
         buffer_3_addr,
         buffer_3_inst,
         buffer_3_brchFwd,
         buffer_2_addr,
         buffer_2_inst,
         buffer_2_brchFwd,
         buffer_1_addr,
         buffer_1_inst,
         buffer_1_brchFwd,
         buffer_0_addr,
         buffer_0_inst,
         buffer_0_brchFwd};
  wire [519:0] _outputBufferView_rotated_T_27 =
    _outputBufferView_rotated_T_9[1]
      ? {_outputBufferView_rotated_T_23[1:0], _outputBufferView_rotated_T_23[519:2]}
      : _outputBufferView_rotated_T_23;
  wire [519:0] _outputBufferView_rotated_T_31 =
    _outputBufferView_rotated_T_9[2]
      ? {_outputBufferView_rotated_T_27[3:0], _outputBufferView_rotated_T_27[519:4]}
      : _outputBufferView_rotated_T_27;
  wire [519:0] _outputBufferView_rotated_T_35 =
    _outputBufferView_rotated_T_9[3]
      ? {_outputBufferView_rotated_T_31[7:0], _outputBufferView_rotated_T_31[519:8]}
      : _outputBufferView_rotated_T_31;
  wire [519:0] _outputBufferView_rotated_T_39 =
    _outputBufferView_rotated_T_9[4]
      ? {_outputBufferView_rotated_T_35[15:0], _outputBufferView_rotated_T_35[519:16]}
      : _outputBufferView_rotated_T_35;
  wire [519:0] _outputBufferView_rotated_T_43 =
    _outputBufferView_rotated_T_9[5]
      ? {_outputBufferView_rotated_T_39[31:0], _outputBufferView_rotated_T_39[519:32]}
      : _outputBufferView_rotated_T_39;
  wire [519:0] _outputBufferView_rotated_T_47 =
    _outputBufferView_rotated_T_9[6]
      ? {_outputBufferView_rotated_T_43[63:0], _outputBufferView_rotated_T_43[519:64]}
      : _outputBufferView_rotated_T_43;
  wire [519:0] _outputBufferView_rotated_T_51 =
    _outputBufferView_rotated_T_9[7]
      ? {_outputBufferView_rotated_T_47[127:0], _outputBufferView_rotated_T_47[519:128]}
      : _outputBufferView_rotated_T_47;
  wire [519:0] _outputBufferView_rotated_T_55 =
    _outputBufferView_rotated_T_9[8]
      ? {_outputBufferView_rotated_T_51[255:0], _outputBufferView_rotated_T_51[519:256]}
      : _outputBufferView_rotated_T_51;
  wire [259:0] outputBufferView_rotated =
                                            _outputBufferView_rotated_T_9[9] ? 
                                            {_outputBufferView_rotated_T_55[251:0], _outputBufferView_rotated_T_55[519:512]} : 
                                            _outputBufferView_rotated_T_55[259:0];
  wire         expandedInput_2_ret_valid = io_enqValid > 3'h2;
  wire [9:0]   _rotatedInput_rotated_T_17 = {7'h0, enqPtr} * 10'h42;
  wire [527:0] _rotatedInput_rotated_T_31 =
    _rotatedInput_rotated_T_17[0]
      ? {263'h0,
         io_enqValid[2],
         io_enqData_3_addr,
         io_enqData_3_inst,
         io_enqData_3_brchFwd,
         expandedInput_2_ret_valid,
         io_enqData_2_addr,
         io_enqData_2_inst,
         io_enqData_2_brchFwd,
         |(io_enqValid[2:1]),
         io_enqData_1_addr,
         io_enqData_1_inst,
         io_enqData_1_brchFwd,
         |io_enqValid,
         io_enqData_0_addr,
         io_enqData_0_inst,
         io_enqData_0_brchFwd,
         1'h0}
      : {264'h0,
         io_enqValid[2],
         io_enqData_3_addr,
         io_enqData_3_inst,
         io_enqData_3_brchFwd,
         expandedInput_2_ret_valid,
         io_enqData_2_addr,
         io_enqData_2_inst,
         io_enqData_2_brchFwd,
         |(io_enqValid[2:1]),
         io_enqData_1_addr,
         io_enqData_1_inst,
         io_enqData_1_brchFwd,
         |io_enqValid,
         io_enqData_0_addr,
         io_enqData_0_inst,
         io_enqData_0_brchFwd};
  wire [527:0] _rotatedInput_rotated_T_35 =
    _rotatedInput_rotated_T_17[1]
      ? {_rotatedInput_rotated_T_31[525:0], _rotatedInput_rotated_T_31[527:526]}
      : _rotatedInput_rotated_T_31;
  wire [527:0] _rotatedInput_rotated_T_39 =
    _rotatedInput_rotated_T_17[2]
      ? {_rotatedInput_rotated_T_35[523:0], _rotatedInput_rotated_T_35[527:524]}
      : _rotatedInput_rotated_T_35;
  wire [527:0] _rotatedInput_rotated_T_43 =
    _rotatedInput_rotated_T_17[3]
      ? {_rotatedInput_rotated_T_39[519:0], _rotatedInput_rotated_T_39[527:520]}
      : _rotatedInput_rotated_T_39;
  wire [527:0] _rotatedInput_rotated_T_47 =
    _rotatedInput_rotated_T_17[4]
      ? {_rotatedInput_rotated_T_43[511:0], _rotatedInput_rotated_T_43[527:512]}
      : _rotatedInput_rotated_T_43;
  wire [527:0] _rotatedInput_rotated_T_51 =
    _rotatedInput_rotated_T_17[5]
      ? {_rotatedInput_rotated_T_47[495:0], _rotatedInput_rotated_T_47[527:496]}
      : _rotatedInput_rotated_T_47;
  wire [527:0] _rotatedInput_rotated_T_55 =
    _rotatedInput_rotated_T_17[6]
      ? {_rotatedInput_rotated_T_51[463:0], _rotatedInput_rotated_T_51[527:464]}
      : _rotatedInput_rotated_T_51;
  wire [527:0] _rotatedInput_rotated_T_59 =
    _rotatedInput_rotated_T_17[7]
      ? {_rotatedInput_rotated_T_55[399:0], _rotatedInput_rotated_T_55[527:400]}
      : _rotatedInput_rotated_T_55;
  wire [527:0] _rotatedInput_rotated_T_63 =
    _rotatedInput_rotated_T_17[8]
      ? {_rotatedInput_rotated_T_59[271:0], _rotatedInput_rotated_T_59[527:272]}
      : _rotatedInput_rotated_T_59;
  wire [527:0] rotatedInput_rotated =
    _rotatedInput_rotated_T_17[9]
      ? {_rotatedInput_rotated_T_63[15:0], _rotatedInput_rotated_T_63[527:16]}
      : _rotatedInput_rotated_T_63;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      buffer_0_addr <= 32'h0;
      buffer_0_inst <= 32'h0;
      buffer_0_brchFwd <= 1'h0;
      buffer_1_addr <= 32'h0;
      buffer_1_inst <= 32'h0;
      buffer_1_brchFwd <= 1'h0;
      buffer_2_addr <= 32'h0;
      buffer_2_inst <= 32'h0;
      buffer_2_brchFwd <= 1'h0;
      buffer_3_addr <= 32'h0;
      buffer_3_inst <= 32'h0;
      buffer_3_brchFwd <= 1'h0;
      buffer_4_addr <= 32'h0;
      buffer_4_inst <= 32'h0;
      buffer_4_brchFwd <= 1'h0;
      buffer_5_addr <= 32'h0;
      buffer_5_inst <= 32'h0;
      buffer_5_brchFwd <= 1'h0;
      buffer_6_addr <= 32'h0;
      buffer_6_inst <= 32'h0;
      buffer_6_brchFwd <= 1'h0;
      buffer_7_addr <= 32'h0;
      buffer_7_inst <= 32'h0;
      buffer_7_brchFwd <= 1'h0;
      enqPtr <= 3'h0;
      deqPtr <= 3'h0;
      nEnqueued <= 4'h0;
    end
    else begin if (rotatedInput_rotated[65]) begin
        buffer_0_addr <= rotatedInput_rotated[64:33];
        buffer_0_inst <= rotatedInput_rotated[32:1];
        buffer_0_brchFwd <= rotatedInput_rotated[0];
      end
      if (rotatedInput_rotated[131]) begin
        buffer_1_addr <= rotatedInput_rotated[130:99];
        buffer_1_inst <= rotatedInput_rotated[98:67];
        buffer_1_brchFwd <= rotatedInput_rotated[66];
      end
      if (rotatedInput_rotated[197]) begin
        buffer_2_addr <= rotatedInput_rotated[196:165];
        buffer_2_inst <= rotatedInput_rotated[164:133];
        buffer_2_brchFwd <= rotatedInput_rotated[132];
      end
      if (rotatedInput_rotated[263]) begin
        buffer_3_addr <= rotatedInput_rotated[262:231];
        buffer_3_inst <= rotatedInput_rotated[230:199];
        buffer_3_brchFwd <= rotatedInput_rotated[198];
      end
      if (rotatedInput_rotated[329]) begin
        buffer_4_addr <= rotatedInput_rotated[328:297];
        buffer_4_inst <= rotatedInput_rotated[296:265];
        buffer_4_brchFwd <= rotatedInput_rotated[264];
      end
      if (rotatedInput_rotated[395]) begin
        buffer_5_addr <= rotatedInput_rotated[394:363];
        buffer_5_inst <= rotatedInput_rotated[362:331];
        buffer_5_brchFwd <= rotatedInput_rotated[330];
      end
      if (rotatedInput_rotated[461]) begin
        buffer_6_addr <= rotatedInput_rotated[460:429];
        buffer_6_inst <= rotatedInput_rotated[428:397];
        buffer_6_brchFwd <= rotatedInput_rotated[396];
      end
      if (rotatedInput_rotated[527]) begin
        buffer_7_addr <= rotatedInput_rotated[526:495];
        buffer_7_inst <= rotatedInput_rotated[494:463];
        buffer_7_brchFwd <= rotatedInput_rotated[462];
      end
      enqPtr <= io_flush ? 3'h0 : enqPtr + io_enqValid;
      deqPtr <= io_flush ? 3'h0 : deqPtr + io_deqReady;
      nEnqueued <=
        io_flush ? 4'h0 : nEnqueued + {1'h0, io_enqValid} - {1'h0, io_deqReady};
    end
  end // always @(posedge, posedge)
  `ifdef ENABLE_INITIAL_REG_
    `ifdef FIRRTL_BEFORE_INITIAL
      `FIRRTL_BEFORE_INITIAL
    `endif // FIRRTL_BEFORE_INITIAL
    logic [31:0] _RANDOM[0:16];
    initial begin
      `ifdef INIT_RANDOM_PROLOG_
        `INIT_RANDOM_PROLOG_
      `endif // INIT_RANDOM_PROLOG_
      `ifdef RANDOMIZE_REG_INIT
        for (logic [4:0] i = 5'h0; i < 5'h11; i += 5'h1) begin
          _RANDOM[i] = `RANDOM;
        end
        buffer_0_addr = _RANDOM[5'h0];
        buffer_0_inst = _RANDOM[5'h1];
        buffer_0_brchFwd = _RANDOM[5'h2][0];
        buffer_1_addr = {_RANDOM[5'h2][31:1], _RANDOM[5'h3][0]};
        buffer_1_inst = {_RANDOM[5'h3][31:1], _RANDOM[5'h4][0]};
        buffer_1_brchFwd = _RANDOM[5'h4][1];
        buffer_2_addr = {_RANDOM[5'h4][31:2], _RANDOM[5'h5][1:0]};
        buffer_2_inst = {_RANDOM[5'h5][31:2], _RANDOM[5'h6][1:0]};
        buffer_2_brchFwd = _RANDOM[5'h6][2];
        buffer_3_addr = {_RANDOM[5'h6][31:3], _RANDOM[5'h7][2:0]};
        buffer_3_inst = {_RANDOM[5'h7][31:3], _RANDOM[5'h8][2:0]};
        buffer_3_brchFwd = _RANDOM[5'h8][3];
        buffer_4_addr = {_RANDOM[5'h8][31:4], _RANDOM[5'h9][3:0]};
        buffer_4_inst = {_RANDOM[5'h9][31:4], _RANDOM[5'hA][3:0]};
        buffer_4_brchFwd = _RANDOM[5'hA][4];
        buffer_5_addr = {_RANDOM[5'hA][31:5], _RANDOM[5'hB][4:0]};
        buffer_5_inst = {_RANDOM[5'hB][31:5], _RANDOM[5'hC][4:0]};
        buffer_5_brchFwd = _RANDOM[5'hC][5];
        buffer_6_addr = {_RANDOM[5'hC][31:6], _RANDOM[5'hD][5:0]};
        buffer_6_inst = {_RANDOM[5'hD][31:6], _RANDOM[5'hE][5:0]};
        buffer_6_brchFwd = _RANDOM[5'hE][6];
        buffer_7_addr = {_RANDOM[5'hE][31:7], _RANDOM[5'hF][6:0]};
        buffer_7_inst = {_RANDOM[5'hF][31:7], _RANDOM[5'h10][6:0]};
        buffer_7_brchFwd = _RANDOM[5'h10][7];
        enqPtr = _RANDOM[5'h10][10:8];
        deqPtr = _RANDOM[5'h10][13:11];
        nEnqueued = _RANDOM[5'h10][17:14];
      `endif // RANDOMIZE_REG_INIT
      if (reset) begin
        buffer_0_addr = 32'h0;
        buffer_0_inst = 32'h0;
        buffer_0_brchFwd = 1'h0;
        buffer_1_addr = 32'h0;
        buffer_1_inst = 32'h0;
        buffer_1_brchFwd = 1'h0;
        buffer_2_addr = 32'h0;
        buffer_2_inst = 32'h0;
        buffer_2_brchFwd = 1'h0;
        buffer_3_addr = 32'h0;
        buffer_3_inst = 32'h0;
        buffer_3_brchFwd = 1'h0;
        buffer_4_addr = 32'h0;
        buffer_4_inst = 32'h0;
        buffer_4_brchFwd = 1'h0;
        buffer_5_addr = 32'h0;
        buffer_5_inst = 32'h0;
        buffer_5_brchFwd = 1'h0;
        buffer_6_addr = 32'h0;
        buffer_6_inst = 32'h0;
        buffer_6_brchFwd = 1'h0;
        buffer_7_addr = 32'h0;
        buffer_7_inst = 32'h0;
        buffer_7_brchFwd = 1'h0;
        enqPtr = 3'h0;
        deqPtr = 3'h0;
        nEnqueued = 4'h0;
      end
    end // initial
    `ifdef FIRRTL_AFTER_INITIAL
      `FIRRTL_AFTER_INITIAL
    `endif // FIRRTL_AFTER_INITIAL
  `endif // ENABLE_INITIAL_REG_
  assign io_nEnqueued = nEnqueued;
  assign io_nSpace = 4'h8 - nEnqueued;
  assign io_dataOut_0_addr = outputBufferView_rotated[64:33];
  assign io_dataOut_0_inst = outputBufferView_rotated[32:1];
  assign io_dataOut_0_brchFwd = outputBufferView_rotated[0];
  assign io_dataOut_1_addr = outputBufferView_rotated[129:98];
  assign io_dataOut_1_inst = outputBufferView_rotated[97:66];
  assign io_dataOut_1_brchFwd = outputBufferView_rotated[65];
  assign io_dataOut_2_addr = outputBufferView_rotated[194:163];
  assign io_dataOut_2_inst = outputBufferView_rotated[162:131];
  assign io_dataOut_2_brchFwd = outputBufferView_rotated[130];
  assign io_dataOut_3_addr = outputBufferView_rotated[259:228];
  assign io_dataOut_3_inst = outputBufferView_rotated[227:196];
  assign io_dataOut_3_brchFwd = outputBufferView_rotated[195];
endmodule
`else
module CircularBufferMulti(
  input         clock,
                reset,
  // Enqueue (Write) Ports
  input  [2:0]  io_enqValid, // Indicates N entries to write (0 to 3)
  input  [31:0] io_enqData_0_addr,
                io_enqData_0_inst,
  input         io_enqData_0_brchFwd,
  input  [31:0] io_enqData_1_addr, 
                io_enqData_1_inst,
  input         io_enqData_1_brchFwd,
  input  [31:0] io_enqData_2_addr, 
                io_enqData_2_inst,
  input         io_enqData_2_brchFwd,
  input  [31:0] io_enqData_3_addr, 
                io_enqData_3_inst,
  input         io_enqData_3_brchFwd, // Port 3 unused, max 3-wide write
  
  output [3:0]  io_nEnqueued,
                io_nSpace,
  // Dequeue (Read) Ports: Four simultaneous reads
  output [31:0] io_dataOut_0_addr,
                io_dataOut_0_inst,
  output        io_dataOut_0_brchFwd,
  output [31:0] io_dataOut_1_addr,
                io_dataOut_1_inst,
  output        io_dataOut_1_brchFwd,
  output [31:0] io_dataOut_2_addr,
                io_dataOut_2_inst,
  output        io_dataOut_2_brchFwd,
  output [31:0] io_dataOut_3_addr,
                io_dataOut_3_inst,
  output        io_dataOut_3_brchFwd,
                
  input  [2:0]  io_deqReady,
  input         io_flush
); // Explicitly request Distributed RAM

  // PARAMETERS & MEMORY DECLARATION 
  localparam DEPTH  = 8;       // 8 buffer entries
  localparam ADDR_W = 3;       // Address width log2(8) = 3
  localparam DATA_W = 65;      // 32-bit addr + 32-bit inst + 1-bit branch = 65 bits

  // Memory: Implemented using LUTs (Distributed RAM) for multi-port access flexibility
  reg [DATA_W-1:0] buffer_memory [0:DEPTH-1]   /*synthesis syn_ramstyle="distributed_ram"*/; 

  // Pointers and Count
  reg [ADDR_W-1:0] enqPtr, deqPtr;
  reg [3:0] nEnqueued;

  // WRITE DATA (Bundled for convenience)
  wire [DATA_W-1:0] enq_data_0 = {io_enqData_0_addr, io_enqData_0_inst, io_enqData_0_brchFwd};
  wire [DATA_W-1:0] enq_data_1 = {io_enqData_1_addr, io_enqData_1_inst, io_enqData_1_brchFwd};
  wire [DATA_W-1:0] enq_data_2 = {io_enqData_2_addr, io_enqData_2_inst, io_enqData_2_brchFwd};

  // WRITE ADDRESSES (3 parallel write addresses)
  wire [ADDR_W-1:0] write_addr_0 = enqPtr + 3'h0;
  wire [ADDR_W-1:0] write_addr_1 = enqPtr + 3'h1;
  wire [ADDR_W-1:0] write_addr_2 = enqPtr + 3'h2;
  
  // WRITE ENABLES (3 parallel write enables)
  wire write_enable_0 = io_enqValid >= 3'h1;
  wire write_enable_1 = io_enqValid >= 3'h2;
  wire write_enable_2 = io_enqValid >= 3'h3;
  
  // READ ADDRESSES (4 parallel read addresses)
  wire [ADDR_W-1:0] read_addr_0 = deqPtr;
  wire [ADDR_W-1:0] read_addr_1 = deqPtr + 1'b1;
  wire [ADDR_W-1:0] read_addr_2 = deqPtr + 2'h2;
  wire [ADDR_W-1:0] read_addr_3 = deqPtr + 2'h3;
  
  // READ DATA OUTPUTS (Registered from memory read) 
  reg [DATA_W-1:0] rdata_0, rdata_1, rdata_2, rdata_3;

  // PARALLEL? LOGIC (Pointer & Memory Update) 
  always @(posedge clock) begin
    if (reset || io_flush) begin
      enqPtr    <= {ADDR_W{1'b0}};
      deqPtr    <= {ADDR_W{1'b0}};
      nEnqueued <= 4'h0;
    end else begin
      // Pointer Updates (Implicit modulo 8 due to 3-bit width)
      enqPtr    <= enqPtr + io_enqValid;
      deqPtr    <= deqPtr + io_deqReady;
      nEnqueued <= nEnqueued + {1'h0, io_enqValid} - {1'h0, io_deqReady};
    end
  end
  // Write
  always @(posedge clock) begin
    if ((!reset)&&(io_flush)) begin
      // Multi-Write logic (Distributed RAM handles these non-conflicting writes)
      if (write_enable_0) begin
        buffer_memory[write_addr_0] <= enq_data_0;
      end
      if (write_enable_1) begin
        buffer_memory[write_addr_1] <= enq_data_1;
      end
      if (write_enable_2) begin
        buffer_memory[write_addr_2] <= enq_data_2;
      end
    end
  end
  // Read
  always @(posedge clock) begin
    if ((!reset)&&(io_flush)) begin
      // Multi-Read logic (Outputs are registered from memory, 4 parallel reads)
      rdata_0 <= buffer_memory[read_addr_0];
      rdata_1 <= buffer_memory[read_addr_1];
      rdata_2 <= buffer_memory[read_addr_2];
      rdata_3 <= buffer_memory[read_addr_3];
    end
  end

  // COMBINATIONAL OUTPUTS 
  assign io_nEnqueued = nEnqueued;
  assign io_nSpace = DEPTH - nEnqueued;

  // UNPACKING THE DISTRIBUTED RAM OUTPUTS 
  // Output 0
  assign io_dataOut_0_addr    = rdata_0[64:33];
  assign io_dataOut_0_inst    = rdata_0[32:1];
  assign io_dataOut_0_brchFwd = rdata_0[0];
  
  // Output 1
  assign io_dataOut_1_addr    = rdata_1[64:33];
  assign io_dataOut_1_inst    = rdata_1[32:1];
  assign io_dataOut_1_brchFwd = rdata_1[0];

  // Output 2
  assign io_dataOut_2_addr    = rdata_2[64:33];
  assign io_dataOut_2_inst    = rdata_2[32:1];
  assign io_dataOut_2_brchFwd = rdata_2[0];

  // Output 3
  assign io_dataOut_3_addr    = rdata_3[64:33];
  assign io_dataOut_3_inst    = rdata_3[32:1];
  assign io_dataOut_3_brchFwd = rdata_3[0];
endmodule
`endif
