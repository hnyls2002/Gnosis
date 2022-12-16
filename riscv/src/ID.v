`include "Def.v"

module dispatcher(
    input   wire                flag_IF,
    input   wire    [31:0]      inst_IF,

    // direct decode infos
    output  wire                ID_flag,
    output  reg [4:0]           ID_rd,
    output  reg [4:0]           ID_rs1,
    output  reg [4:0]           ID_rs2,
    output  reg [31:0]          ID_A, 
    output  reg [5:0]           ID_inst_code,
    output  reg [2:0]           ID_inst_type
);

assign ID_flag = flag_IF;

wire [2:0]  funct3 = inst_IF[14:12];
wire [6:0]  funct7 = inst_IF[31:25];
wire [6:0]  opcode = inst_IF[6:0];

always @(*) begin
    ID_rd = 0;
    ID_rs1 = 0;
    ID_rs2 = 0;
    ID_A = 0;
    ID_inst_code = 0;
    ID_inst_type = 0;
    if(flag_IF) begin
        case (opcode)
            `R_TYPE : begin
                ID_rd  = inst_IF[11:7];
                ID_rs1 = inst_IF[19:15];
                ID_rs2 = inst_IF[24:20];
                ID_inst_type = `ALU;
                case (funct7[5])
                    1'b1 : begin
                        case (funct3)
                            3'b000 : ID_inst_code = `SUB;
                            3'b101 : ID_inst_code = `SRA;
                            default:;
                        endcase
                    end
                    1'b0 : begin
                        case (funct3)
                            3'b000 : ID_inst_code = `ADD;
                            3'b001 : ID_inst_code = `SLL;
                            3'b010 : ID_inst_code = `SLT;
                            3'b011 : ID_inst_code = `SLTU;
                            3'b100 : ID_inst_code = `XOR;
                            3'b101 : ID_inst_code = `SRL;
                            3'b110 : ID_inst_code = `OR;
                            3'b111 : ID_inst_code = `AND;
                        endcase
                    end
                endcase
            end
            `I_TYPE0, `I_TYPE1, `I_TYPE2 : begin
                ID_rd  = inst_IF[11:7];
                ID_rs1 = inst_IF[19:15];
                if(opcode == 7'b0010011 && (funct3 == 3'b001 || funct3 == 3'b101)) 
                    ID_A = {{27{1'b0}},inst_IF[24:20]};
                else ID_A = {{20{inst_IF[31]}},inst_IF[31:20]};
                case(opcode)
                    `I_TYPE0 : begin
                        ID_inst_type = `JMP;
                        ID_inst_code = `JALR;
                    end
                    `I_TYPE1 : begin
                        ID_inst_type = `LD;
                        case (funct3)
                            3'b000 : ID_inst_code = `LB;
                            3'b001 : ID_inst_code = `LH;
                            3'b010 : ID_inst_code = `LW;
                            3'b100 : ID_inst_code = `LBU;
                            3'b101 : ID_inst_code = `LHU;
                            default:;
                        endcase
                    end
                    `I_TYPE2 : begin
                        ID_inst_type = `ALU;
                        case (funct3)
                            3'b000 : ID_inst_code = `ADDI;
                            3'b010 : ID_inst_code = `SLTI;
                            3'b011 : ID_inst_code = `SLTIU;
                            3'b100 : ID_inst_code = `XORI;
                            3'b110 : ID_inst_code = `ORI;
                            3'b111 : ID_inst_code = `ANDI;
                            3'b001 : ID_inst_code = `SLLI; 
                            3'b101 : begin
                                case (funct7[5])
                                    1'b0 : ID_inst_code = `SRLI;
                                    1'b1 : ID_inst_code = `SRAI;
                                endcase
                            end
                        endcase 
                    end
                    default:;
                endcase
            end
            `S_TYPE : begin
                ID_rs1 = inst_IF[19:15];
                ID_rs2 = inst_IF[24:20];
                ID_inst_type = `ST;
                ID_A = {{20{inst_IF[31]}},inst_IF[31:25],inst_IF[11:7]};
                case (funct3)
                    3'b000 : ID_inst_code = `SB;
                    3'b001 : ID_inst_code = `SH;
                    3'b010 : ID_inst_code = `SW;
                    default:;
                endcase
            end
            `B_TYPE : begin
                ID_rs1 = inst_IF[19:15];
                ID_rs2 = inst_IF[24:20];
                ID_inst_type = `BRC;
                ID_A = {{19{inst_IF[31]}},inst_IF[31],inst_IF[7],inst_IF[30:25],inst_IF[11:8],1'b0};
                case (funct3)
                    3'b000 : ID_inst_code = `BEQ;
                    3'b001 : ID_inst_code = `BNE;
                    3'b100 : ID_inst_code = `BLT;
                    3'b101 : ID_inst_code = `BGE;
                    3'b110 : ID_inst_code = `BLTU;
                    3'b111 : ID_inst_code = `BGEU;
                    default:;
                endcase
            end
            `U_TYPE0, `U_TYPE1 : begin
                ID_rd  = inst_IF[11:7];
                ID_inst_type = `ALU;
                ID_A = {inst_IF[31:12],{12{1'b0}}};
                case (opcode)
                    `U_TYPE0 : ID_inst_code = `LUI;
                    `U_TYPE1 : ID_inst_code = `AUIPC;
                    default  :;
                endcase
            end
            `J_TYPE : begin
                ID_rd  = inst_IF[11:7];
                ID_inst_type = `JMP;
                ID_A = {{11{inst_IF[31]}},inst_IF[31],inst_IF[19:12],inst_IF[20],inst_IF[30:21],1'b0};
                ID_inst_code = `JAL;
            end
            default:;
        endcase
    end
end

endmodule