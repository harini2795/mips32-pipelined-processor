module IF_stage (
    input  wire        clk,
    input  wire        HALTED,

    // Control signals
    input  wire        PCWrite,
    input  wire        IF_ID_Write,

    // Branch information from EX/MEM stage
    input  wire [31:0] EX_MEM_IR,
    input  wire        EX_MEM_COND,
    input  wire [31:0] EX_MEM_ALUOUT,

    // Outputs to IF/ID pipeline register
    output reg  [31:0] IF_ID_IR,
    output reg  [31:0] IF_ID_NPC,

    // Program Counter
    output reg  [31:0] PC
);

    // Instruction memory
    reg [31:0] Mem [0:1023];

    // Opcodes
    parameter BNEQZ = 6'b001101,
              BEQZ  = 6'b001110;

    reg [31:0] next_pc;
    reg        TAKEN_BRANCH;

    // -------------------------------
    // Initialization
    // -------------------------------
    initial begin
        PC        = 32'b0;
        IF_ID_IR  = 32'b0;
        IF_ID_NPC = 32'b0;
    end

    // -------------------------------
    // Branch decision & Next PC logic
    // (Combinational)
    // -------------------------------
    always @(*) begin
        TAKEN_BRANCH = 1'b0;

        if ((EX_MEM_IR[31:26] == BNEQZ && !EX_MEM_COND) ||
            (EX_MEM_IR[31:26] == BEQZ  &&  EX_MEM_COND)) begin

            next_pc      = EX_MEM_ALUOUT + 1;
            TAKEN_BRANCH = 1'b1;

        end else begin
            next_pc = PC + 1;
        end
    end

    // -------------------------------
    // PC Register
    // -------------------------------
    always @(posedge clk) begin
        if (!HALTED && PCWrite) begin
            PC <= next_pc;
        end
    end

    // -------------------------------
    // IF/ID Pipeline Register
    // -------------------------------
    always @(posedge clk) begin
        if (!HALTED && IF_ID_Write) begin

            if (TAKEN_BRANCH) begin
                // Flush wrong-path instruction
                IF_ID_IR  <= 32'b0;
                IF_ID_NPC <= 32'b0;

            end else begin
                // Normal instruction fetch
                IF_ID_IR  <= Mem[PC];
                IF_ID_NPC <= PC + 1;
            end

        end
    end

endmodule
