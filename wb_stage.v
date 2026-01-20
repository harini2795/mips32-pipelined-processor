
module wb_stage(
    input  clk,
    input  TAKEN_BRANCH,
    input  [2:0]  TYPE,
    input  [31:0] IR,
    input  [31:0] ALUOUT,
    input  [31:0] LMD,

    output reg        WB_RegWrite,
    output reg [4:0]  WB_rd,
    output reg [31:0] WB_data,
    output reg        HALTED
);

    always @(posedge clk) begin
        // defaults
        WB_RegWrite <= 1'b0;
        WB_rd       <= 5'b0;
        WB_data     <= 32'b0;

        if (!TAKEN_BRANCH) begin
            case (TYPE)

                // RR type
                3'b000: begin
                    WB_RegWrite <= 1'b1;
                    WB_rd       <= IR[15:11];
                    WB_data     <= ALUOUT;
                end

                // RM type
                3'b001: begin
                    WB_RegWrite <= 1'b1;
                    WB_rd       <= IR[20:16];
                    WB_data     <= ALUOUT;
                end

                // LOAD
                3'b010: begin
                    WB_RegWrite <= 1'b1;
                    WB_rd       <= IR[20:16];
                    WB_data     <= LMD;
                end

                // STORE / BRANCH
                3'b011, 3'b100: begin
                    WB_RegWrite <= 1'b0;
                end

                // HALT
                3'b101: begin
                    HALTED <= 1'b1;
                end
            endcase
        end
    end
endmodule
