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
    output reg  [31:0]          ex_cdb_val,
    output reg  [31:0]          ex_cdb_rel_pc
);

always @(*) begin
    case(inst_code)
        `ADD    : ex_cdb_val = V1 + V2;
        `ADDI   : ex_cdb_val = V1 + A; 
        `SUB    : ex_cdb_val = V1 - V2;
        `LUI    : ex_cdb_val = A;
        `AUIPC  : ex_cdb_val = inst_pc + A;
        `XOR    : ex_cdb_val = V1 ^ V2;
        `XORI   : ex_cdb_val = V1 ^ A;
        `OR     : ex_cdb_val = V1 | V2;
        `ORI    : ex_cdb_val = V1 | A;
        `AND    : ex_cdb_val = V1 & V2;
        `ANDI   : ex_cdb_val = V1 & A;
        `SLL    : ex_cdb_val = V1 << V2[4:0];
        `SLLI   : ex_cdb_val = V1 << A[4:0];
        `SRL    : ex_cdb_val = V1 >> V2[4:0];
        `SRLI   : ex_cdb_val = V1 >> A[4:0];
        `SRA    : ex_cdb_val = $signed(V1) >> V2[4:0];
        `SRAI   : ex_cdb_val = $signed(V1) >> A[4:0];
        `SLT    : ex_cdb_val = {{31{1'b0}},$signed(V1) < $signed(V2)};
        `SLTI   : ex_cdb_val = {{31{1'b0}},$signed(V1) < $signed(A)};
        `SLTU   : ex_cdb_val = {{31{1'b0}},V1 < V2};
        `SLTIU  : ex_cdb_val = {{31{1'b0}},V1 < A};
        `BEQ    : begin
            if(V1 == V2) 
                ex_cdb_rel_pc = inst_pc + A;
            else 
                ex_cdb_rel_pc = inst_pc + 4;
        end
        `BNE    : begin
            if(V1 != V2) 
                ex_cdb_rel_pc = inst_pc + A;
            else 
                ex_cdb_rel_pc = inst_pc + 4;
        end
        `BLT    : begin
            if($signed(V1) < $signed(V2)) 
                ex_cdb_rel_pc = inst_pc + A;
            else 
                ex_cdb_rel_pc = inst_pc + 4;
        end
        `BGE    : begin
            if($signed(V1) >= $signed(V2)) 
                ex_cdb_rel_pc = inst_pc + A;
            else 
                ex_cdb_rel_pc = inst_pc + 4;
        end
        `BLTU   : begin
            if(V1 < V2) 
                ex_cdb_rel_pc = inst_pc + A;
            else 
                ex_cdb_rel_pc = inst_pc + 4;
        end
        `BGEU   : begin
            if(V1 >= V2) 
                ex_cdb_rel_pc = inst_pc + A;
            else 
                ex_cdb_rel_pc = inst_pc + 4;
        end
        `JAL    : ex_cdb_val = inst_pc + 4;
        `JALR   : begin
            ex_cdb_val = inst_pc + 4;
            ex_cdb_rel_pc = (V1 + A) & (~32'b1);
        end
        default : ex_cdb_val = 32'b0;
    endcase
end

endmodule