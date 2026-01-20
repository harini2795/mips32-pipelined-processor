
module id_stage(
    input clk,
    input HALTED,
    input Stall,

    // WB write-back interface
    input        WB_RegWrite,
    input [4:0]  WB_rd,
    input [31:0] WB_data,

    input [31:0] IF_ID_IR,
    input [31:0] IF_ID_NPC,

    output reg [31:0] ID_EX_A,
    output reg [31:0] ID_EX_B,
    output reg [31:0] ID_EX_IMM,
    output reg [31:0] ID_EX_NPC,
    output reg [31:0] ID_EX_IR,
    output reg [2:0]  ID_EX_TYPE
);

    reg [31:0] RegFile [0:31];

    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
              SLT=6'b000100, MUL=6'b000101, HLT=6'b111111,
              LW=6'b001000, SW=6'b001001,
              ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
              BNEQZ=6'b001101, BEQZ=6'b001110;

    parameter RR_TYPE=3'b000, RM_TYPE=3'b001,
              LOAD=3'b010, STORE=3'b011,
              BRANCH=3'b100, HALT=3'b101;

    /* ================= WRITE BACK ================= */
    always @(posedge clk) begin
        if (WB_RegWrite && WB_rd != 0)
            RegFile[WB_rd] <= WB_data;
    end

    /* ================= DECODE ================= */
    always @(posedge clk) begin
        if (!HALTED) begin

            if (Stall) begin
                // ✅ INSERT REAL NOP
                ID_EX_TYPE <= HALT;
                ID_EX_A    <= 32'b0;
                ID_EX_B    <= 32'b0;
                ID_EX_IMM  <= 32'b0;
                ID_EX_NPC  <= 32'b0;
                ID_EX_IR   <= 32'b0;

            end else begin
                ID_EX_A   <= (IF_ID_IR[25:21] == 0) ? 0 : RegFile[IF_ID_IR[25:21]];
                ID_EX_B   <= (IF_ID_IR[20:16] == 0) ? 0 : RegFile[IF_ID_IR[20:16]];
                ID_EX_IMM <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};
                ID_EX_NPC <= IF_ID_NPC;
                ID_EX_IR  <= IF_ID_IR;

                case (IF_ID_IR[31:26])
                    ADD,SUB,AND,OR,SLT,MUL: ID_EX_TYPE <= RR_TYPE;
                    ADDI,SUBI,SLTI:         ID_EX_TYPE <= RM_TYPE;
                    LW:                     ID_EX_TYPE <= LOAD;
                    SW:                     ID_EX_TYPE <= STORE;
                    BNEQZ,BEQZ:             ID_EX_TYPE <= BRANCH;
                    HLT:                    ID_EX_TYPE <= HALT;
                    default:                ID_EX_TYPE <= HALT;
                endcase
            end
        end
    end
endmodule
