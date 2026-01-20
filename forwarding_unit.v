
module forwarding_unit(
    input  [4:0] ID_EX_rs,
    input  [4:0] ID_EX_rt,
    input  [4:0] EX_MEM_rd,
    input        EX_MEM_RegWrite,
    input  [4:0] MEM_WB_rd,
    input        MEM_WB_RegWrite,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

always @(*) begin
    // Default: use value from ID/EX registers
    ForwardA = 2'b00;
    ForwardB = 2'b00;

    // --- Forwarding for A operand ---
    if (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs))
        ForwardA = 2'b10;          // EX/MEM has latest value
    else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs))
        ForwardA = 2'b01;          // MEM/WB has latest value

    // --- Forwarding for B operand ---
    if (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt))
        ForwardB = 2'b10;
    else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rt))
        ForwardB = 2'b01;
end

endmodule
