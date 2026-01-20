module mem_stage(
    input clk,
    input HALTED,
    input TAKEN_BRANCH,
    input [2:0] TYPE,
    input [31:0] IR, ALUOUT, B,

    output reg [2:0]  TYPE_OUT,
    output reg [31:0] IR_OUT,
    output reg [31:0] ALUOUT_OUT,
    output reg [31:0] LMD
);

    reg [31:0] Mem [0:1023];

    always @(posedge clk) begin
        if (!HALTED) begin

            TYPE_OUT    <= TYPE;
            IR_OUT      <= IR;
            ALUOUT_OUT  <= 32'b0;
            LMD         <= 32'b0;

            case (TYPE)
                // RR & RM
                3'b000, 3'b001: begin
                    ALUOUT_OUT <= ALUOUT;
                end

                // LOAD
                3'b010: begin
                    LMD <= Mem[ALUOUT[9:0]]; // Mask to 10 bits for 1024-depth
                end

                // STORE
                3'b011: begin
                    if (!TAKEN_BRANCH)
                        Mem[ALUOUT[9:0]] <= B;
                end

                // BRANCH
                3'b100: begin
                    // No memory action
                end

                // HALT
                3'b101: begin
                    // Just propagate HALT
                end

                default: begin
                    // NOP
                end
            endcase
        end
    end
endmodule
