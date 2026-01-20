module hazard_unit(
    input        ID_EX_MemRead,
    input  [4:0] ID_EX_rt,
    input  [4:0] IF_ID_rs,
    input  [4:0] IF_ID_rt,
    output reg   PCWrite,
    output reg   IF_ID_Write,
    output reg   Stall
);

always @(*) begin
    if (ID_EX_MemRead &&
       ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt))) begin
        PCWrite     = 0;
        IF_ID_Write = 0;
        Stall       = 1;
    end else begin
        PCWrite     = 1;
        IF_ID_Write = 1;
        Stall       = 0;
    end
end
endmodule
