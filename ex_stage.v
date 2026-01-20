module ex_stage(
    input clk,
    input HALTED,

    input [31:0] A, B, IMM, NPC, IR,
    input [2:0]  TYPE,

    // forwarding inputs
    input [31:0] EX_MEM_ALUOUT,
    input [31:0] MEM_WB_ALUOUT,
    input [1:0]  ForwardA,
    input [1:0]  ForwardB,

    output reg [31:0] ALUOUT, B_OUT, IR_OUT,
    output reg COND,
    output reg [2:0] TYPE_OUT,
    output reg TAKEN_BRANCH
);
    wire branch_taken;
    parameter BEQZ  = 6'b001110;
    parameter BNEQZ = 6'b001101;
    
    wire [31:0] A_fwd, B_fwd;
    
    assign branch_taken =((IR[31:26] == BEQZ)  && (A_fwd == 0)) ||((IR[31:26] == BNEQZ) && (A_fwd != 0));
    
    assign A_fwd = (ForwardA == 2'b10) ? EX_MEM_ALUOUT :
                   (ForwardA == 2'b01) ? MEM_WB_ALUOUT :
                                         A;

    assign B_fwd = (ForwardB == 2'b10) ? EX_MEM_ALUOUT :
                   (ForwardB == 2'b01) ? MEM_WB_ALUOUT :
                                         B;

    always @(posedge clk) begin
        if (!HALTED) begin
            TYPE_OUT <= TYPE;
            IR_OUT   <= IR;
            B_OUT    <= B_fwd;

            // Default values
            ALUOUT        <= 32'b0;
            COND          <= 1'b0;
            TAKEN_BRANCH  <= 1'b0;

            case (TYPE)
                3'b000: begin // RR-TYPE
                    case (IR[31:26])
                        6'b000000: ALUOUT <= A_fwd + B_fwd;   // ADD
                        6'b000001: ALUOUT <= A_fwd - B_fwd;   // SUB
                        6'b000010: ALUOUT <= A_fwd & B_fwd;   // AND
                        6'b000011: ALUOUT <= A_fwd | B_fwd;   // OR
                        6'b000100: ALUOUT <= (A_fwd < B_fwd); // SLT
                        6'b000101: ALUOUT <= A_fwd * B_fwd;   // MUL
                    endcase
                end

                3'b001: begin // RM-TYPE
                    case (IR[31:26])
                        6'b001010: ALUOUT <= A_fwd + IMM;     // ADDI
                        6'b001011: ALUOUT <= A_fwd - IMM;     // SUBI
                        6'b001100: ALUOUT <= (A_fwd < IMM);   // SLTI
                    endcase
                end

                3'b010, 3'b011: begin // LOAD / STORE
                    ALUOUT <= A_fwd + IMM;
                end

                3'b100: begin // BRANCH
                    ALUOUT       <= NPC + IMM; // Branch target
                    COND         <= branch_taken;
                    TAKEN_BRANCH <= branch_taken;
                end
            endcase
        end
    end
endmodule
