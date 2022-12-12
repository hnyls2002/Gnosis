`include "Def.v"

module alu(
    // receive from RS
    input wire              flag,
    input wire [31:0]       V1,
    input wire [31:0]       V2,
    input wire [31:0]       A,
    input wire [31:0]       inst_pc,
    input wire [5:0]        inst_code,
    input wire [`ROBBW-1:0] inst_rob_id,

    // result
    output wire                 ex_cdb_flag, 
    output wire [`ROBBW-1:0]    ex_cdb_rob_id,
    output reg  [31:0]          res,
    output reg  [31:0]          rel_pc
);

always @(*) begin
    case(inst_code)
        `ADD    : res = V1 + V2;
        `ADDI   : res = V1 + A; 
        `SUB    : res = V1 - V2;
        `LUI    : res = A;
        `AUIPC  : res = inst_pc + A;
        `XOR    : res = V1 ^ V2;
        `XORI   : res = V1 ^ A;
        `OR     : res = V1 | V2;
        `ORI    : res = V1 | A;
        `AND    : res = V1 & V2;
        `ANDI   : res = V1 & A;
        `SLL    : res = V1 << V2[4:0];
        `SLLI   : res = V1 << A[4:0];
        `SRL    : res = V1 >> V2[4:0];
        `SRLI   : res = V1 >> A[4:0];
        `SRA    : res = $signed(V1) >> V2[4:0];
        `SRAI   : res = $signed(V1) >> A[4:0];
        `SLT    : res = {{31{1'b0}},$signed(V1) < $signed(V2)};
        `SLTI   : res = {{31{1'b0}},$signed(V1) < $signed(A)};
        `SLTU   : res = {{31{1'b0}},V1 < V2};
        `SLTIU  : res = {{31{1'b0}},V1 < A};
        `BEQ    : begin
            if(V1 == V2) rel_pc = inst_pc + A;
            else rel_pc = inst_pc + 4;
        end
        `BNE    : begin
            if(V1 != V2) rel_pc = inst_pc + A;
            else rel_pc = inst_pc + 4;
        end
        `BLT    : begin
            if($signed(V1) < $signed(V2)) rel_pc = inst_pc + A;
            else rel_pc = inst_pc + 4;
        end
        `BGE    : begin
            if($signed(V1) >= $signed(V2)) rel_pc = inst_pc + A;
            else rel_pc = inst_pc + 4;
        end
        `BLTU   : begin
            if(V1 < V2) rel_pc = inst_pc + A;
            else rel_pc = inst_pc + 4;
        end
        `BGEU   : begin
            if(V1 >= V2) rel_pc = inst_pc + A;
            else rel_pc = inst_pc + 4;
        end
        `JAL    : res = inst_pc + 4;
        `JALR   : begin
            res = inst_pc + 4;
            rel_pc = (V1 + A) & (~32'b1);
        end
        default : res = 32'b0;
    endcase
end

endmodule