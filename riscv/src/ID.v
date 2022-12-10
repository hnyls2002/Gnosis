module dispatcher(
    input   wire            inst_flag,
    input   wire    [31:0]  inst,
    output  wire            ID_stall
);

reg [4:0]   rd, rs1, rs2;
reg [31:0]  imm;
reg [6:0]   opcode;
reg [2:0]   funct3;
reg [6:0]   funct7;

always @(*) begin
    if(inst_flag) begin
        opcode = inst[6:0];
    end
end

endmodule