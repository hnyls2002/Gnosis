`include "Def.v"

module alu(
    // receive from RS
    input wire              RS_flag,
    input wire [31:0]       RS_V1,
    input wire [31:0]       RS_V2,
    input wire [31:0]       RS_A,
    input wire [31:0]       RS_inst_pc,
    input wire [5:0]        RS_inst_code,
    input wire [31:0]       RS_inst_rob_id,

    // result
    output wire             ex_cdb_flag, 
    output wire [31:0]      ex_cdb_rob_id,
    output reg  [31:0]      ex_cdb_val,
    output reg  [31:0]      ex_cdb_rel_pc
);

assign ex_cdb_flag = RS_flag;
assign ex_cdb_rob_id = RS_inst_rob_id;

always @(*) begin
    ex_cdb_val  = 0;
    ex_cdb_rel_pc = 0;
    if(RS_flag) begin
        case(RS_inst_code)
            `ADD    : ex_cdb_val = RS_V1 + RS_V2;
            `ADDI   : ex_cdb_val = RS_V1 + RS_A; 
            `SUB    : ex_cdb_val = RS_V1 - RS_V2;
            `LUI    : ex_cdb_val = RS_A;
            `AUIPC  : ex_cdb_val = RS_inst_pc + RS_A;
            `XOR    : ex_cdb_val = RS_V1 ^ RS_V2;
            `XORI   : ex_cdb_val = RS_V1 ^ RS_A;
            `OR     : ex_cdb_val = RS_V1 | RS_V2;
            `ORI    : ex_cdb_val = RS_V1 | RS_A;
            `AND    : ex_cdb_val = RS_V1 & RS_V2;
            `ANDI   : ex_cdb_val = RS_V1 & RS_A;
            `SLL    : ex_cdb_val = RS_V1 << RS_V2[4:0];
            `SLLI   : ex_cdb_val = RS_V1 << RS_A[4:0];
            `SRL    : ex_cdb_val = RS_V1 >> RS_V2[4:0];
            `SRLI   : ex_cdb_val = RS_V1 >> RS_A[4:0];
            `SRA    : ex_cdb_val = $signed(RS_V1) >> RS_V2[4:0];
            `SRAI   : ex_cdb_val = $signed(RS_V1) >> RS_A[4:0];
            `SLT    : ex_cdb_val = {{31{1'b0}},$signed(RS_V1) < $signed(RS_V2)};
            `SLTI   : ex_cdb_val = {{31{1'b0}},$signed(RS_V1) < $signed(RS_A)};
            `SLTU   : ex_cdb_val = {{31{1'b0}},RS_V1 < RS_V2};
            `SLTIU  : ex_cdb_val = {{31{1'b0}},RS_V1 < RS_A};
            `BEQ    : begin
                if(RS_V1 == RS_V2) 
                    ex_cdb_rel_pc = RS_inst_pc + RS_A;
                else 
                    ex_cdb_rel_pc = RS_inst_pc + 4;
            end
            `BNE    : begin
                if(RS_V1 != RS_V2) 
                    ex_cdb_rel_pc = RS_inst_pc + RS_A;
                else 
                    ex_cdb_rel_pc = RS_inst_pc + 4;
            end
            `BLT    : begin
                if($signed(RS_V1) < $signed(RS_V2)) 
                    ex_cdb_rel_pc = RS_inst_pc + RS_A;
                else 
                    ex_cdb_rel_pc = RS_inst_pc + 4;
            end
            `BGE    : begin
                if($signed(RS_V1) >= $signed(RS_V2)) 
                    ex_cdb_rel_pc = RS_inst_pc + RS_A;
                else 
                    ex_cdb_rel_pc = RS_inst_pc + 4;
            end
            `BLTU   : begin
                if(RS_V1 < RS_V2) 
                    ex_cdb_rel_pc = RS_inst_pc + RS_A;
                else 
                    ex_cdb_rel_pc = RS_inst_pc + 4;
            end
            `BGEU   : begin
                if(RS_V1 >= RS_V2) 
                    ex_cdb_rel_pc = RS_inst_pc + RS_A;
                else 
                    ex_cdb_rel_pc = RS_inst_pc + 4;
            end
            `JAL    : begin
                ex_cdb_val = RS_inst_pc + 4;
                ex_cdb_rel_pc = RS_inst_pc + RS_A;
            end
            `JALR   : begin
                ex_cdb_val = RS_inst_pc + 4;
                ex_cdb_rel_pc = (RS_V1 + RS_A) & (~32'b1);
            end
            default : ex_cdb_val = 32'b0;
        endcase
    end
    // $display("ex result : %d %d %d",V1,V2,ex_cdb_val);
end

endmodule