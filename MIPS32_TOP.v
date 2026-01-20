
module MIPS32_TOP(input clk1, clk2,output HALTED);

    // IF stage signals
    wire [31:0] PC;
    wire [31:0] IF_ID_IR, IF_ID_NPC;
    wire TAKEN_BRANCH;

    // ID stage signals
    wire [31:0] ID_EX_A, ID_EX_B, ID_EX_IMM, ID_EX_NPC, ID_EX_IR;
    wire [2:0]  ID_EX_TYPE;

    // EX stage signals
    wire [31:0] EX_MEM_ALUOUT, EX_MEM_B, EX_MEM_IR;
    wire        EX_MEM_COND;
    wire [2:0]  EX_MEM_TYPE;
    
    wire [4:0] EX_MEM_rd;
    wire [4:0] MEM_WB_rd;

    // MEM/WB signals
    wire [31:0] MEM_WB_ALUOUT, MEM_WB_LMD, MEM_WB_IR;
    wire [2:0]  MEM_WB_TYPE;
    
    // WB stage signals (for write-back)
    wire WB_RegWrite;
    wire [4:0] WB_rd;
    wire [31:0] WB_data;
    
    // Hazard signals
    wire PCWrite, IF_ID_Write, Stall;
    wire ID_EX_MemRead;
    wire [4:0] ID_EX_rt;
    wire [4:0] IF_ID_rs, IF_ID_rt;

    assign IF_ID_rs = IF_ID_IR[25:21];
    assign IF_ID_rt = IF_ID_IR[20:16];
    assign ID_EX_rt = ID_EX_IR[20:16];
    assign ID_EX_MemRead = (ID_EX_TYPE == 3'b010); // LOAD instruction

    // -------------------
    // Forwarding signals
    // -------------------
    wire [1:0] ForwardA, ForwardB;
    wire [1:0] ForwardA_wire, ForwardB_wire;
    assign ForwardA = (EX_MEM_TYPE != 3'b000 && EX_MEM_TYPE != 3'b001) ? 2'b00 : ForwardA_wire;
    assign ForwardB = (EX_MEM_TYPE != 3'b000 && EX_MEM_TYPE != 3'b001) ? 2'b00 : ForwardB_wire;
  
   
    // -------------------
    // Instantiate IF Stage
    // -------------------
   IF_stage IF (
    .clk(clk1),
    .HALTED(HALTED),
    .PCWrite(PCWrite),
    .IF_ID_Write(IF_ID_Write),
    .EX_MEM_IR(EX_MEM_IR),
    .EX_MEM_COND(EX_MEM_COND),
    .EX_MEM_ALUOUT(EX_MEM_ALUOUT),
    .IF_ID_IR(IF_ID_IR),
    .IF_ID_NPC(IF_ID_NPC),
    .PC(PC)
);


    // -------------------
    // Instantiate ID Stage
    // -------------------
 id_stage ID (
    .clk(clk2),           // pipeline clock
    .HALTED(HALTED),     // halt signal from WB stage
    .Stall(Stall),       // stall signal from hazard unit

    // WB write-back interface
    .WB_RegWrite(WB_RegWrite),
    .WB_rd(WB_rd),
    .WB_data(WB_data),

    // Inputs from IF/ID pipeline register
    .IF_ID_IR(IF_ID_IR),
    .IF_ID_NPC(IF_ID_NPC),

    // Outputs to ID/EX pipeline register
    .ID_EX_A(ID_EX_A),
    .ID_EX_B(ID_EX_B),
    .ID_EX_IMM(ID_EX_IMM),
    .ID_EX_NPC(ID_EX_NPC),
    .ID_EX_IR(ID_EX_IR),
    .ID_EX_TYPE(ID_EX_TYPE)
);

    // -------------------
    // Instantiate EX Stage
    // -------------------
    ex_stage EX (
        .clk(clk1),
        .HALTED(HALTED),
        .A(ID_EX_A),
        .B(ID_EX_B),
        .IMM(ID_EX_IMM),
        .NPC(ID_EX_NPC),
        .IR(ID_EX_IR),
        .TYPE(ID_EX_TYPE),
        .EX_MEM_ALUOUT(EX_MEM_ALUOUT),
        .MEM_WB_ALUOUT(MEM_WB_ALUOUT),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ALUOUT(EX_MEM_ALUOUT),
        .B_OUT(EX_MEM_B),
        .IR_OUT(EX_MEM_IR),
        .COND(EX_MEM_COND),
        .TAKEN_BRANCH(TAKEN_BRANCH),
        .TYPE_OUT(EX_MEM_TYPE)
    );

    // -------------------
    // Instantiate MEM Stage
    // -------------------
    mem_stage MEM (
        .clk(clk2),
        .HALTED(HALTED),
        .TAKEN_BRANCH(TAKEN_BRANCH),
        .TYPE(EX_MEM_TYPE),
        .IR(EX_MEM_IR),
        .ALUOUT(EX_MEM_ALUOUT),
        .B(EX_MEM_B),
        .TYPE_OUT(MEM_WB_TYPE),
        .IR_OUT(MEM_WB_IR),
        .ALUOUT_OUT(MEM_WB_ALUOUT),
        .LMD(MEM_WB_LMD)
    );

    // -------------------
    // Instantiate WB Stage
    // -------------------
    wb_stage WB (
    .clk(clk1),
    .TAKEN_BRANCH(TAKEN_BRANCH),
    .TYPE(MEM_WB_TYPE),
    .IR(MEM_WB_IR),
    .ALUOUT(MEM_WB_ALUOUT),
    .LMD(MEM_WB_LMD),
    .WB_RegWrite(WB_RegWrite),
    .WB_rd(WB_rd),
    .WB_data(WB_data),
    .HALTED(HALTED)
);


    // -------------------
    // Instantiate Hazard Unit
    // -------------------
    hazard_unit HAZ (
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_rt(ID_EX_rt),
        .IF_ID_rs(IF_ID_rs),
        .IF_ID_rt(IF_ID_rt),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .Stall(Stall)
    );

    // -------------------
    // Instantiate Forwarding Unit
    // -------------------
    assign EX_MEM_rd =(EX_MEM_TYPE == 3'b000) ? EX_MEM_IR[15:11] :
    (EX_MEM_TYPE == 3'b001 || EX_MEM_TYPE == 3'b010) ? EX_MEM_IR[20:16] :
    5'b0;

    assign MEM_WB_rd =(MEM_WB_TYPE == 3'b000) ? MEM_WB_IR[15:11] :
    (MEM_WB_TYPE == 3'b001 || MEM_WB_TYPE == 3'b010) ? MEM_WB_IR[20:16] :
    5'b0;

    forwarding_unit FU (
        .ID_EX_rs(ID_EX_IR[25:21]),
        .ID_EX_rt(ID_EX_IR[20:16]),
        .EX_MEM_rd(EX_MEM_rd),
        .EX_MEM_RegWrite(EX_MEM_TYPE == 3'b000 || EX_MEM_TYPE == 3'b001 || EX_MEM_TYPE == 3'b010),
        .MEM_WB_rd(MEM_WB_rd),
        .MEM_WB_RegWrite(MEM_WB_TYPE == 3'b000 || MEM_WB_TYPE == 3'b001 || MEM_WB_TYPE == 3'b010),
        .ForwardA(ForwardA_wire),
        .ForwardB(ForwardB_wire)
    );

endmodule
