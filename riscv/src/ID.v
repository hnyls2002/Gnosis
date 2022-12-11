module dispatcher(
    input   wire            inst_flag,
    input   wire    [31:0]  inst,

    // inst info
    output wire         inst_ID_flag,
    output reg [4:0]    rd, rs1, rs2,
    output reg [31:0]   imm,
    output reg [5:0]    inst_code,
    output reg [2:0]    inst_type

);

assign inst_ID_flag = inst_flag;

reg [6:0]   opcode;
reg [2:0]   funct3;
reg [6:0]   funct7;

always @(*) begin
    if(inst_flag) begin
        opcode  = inst[6:0];
        rd      = inst[11:7];
        rs1     = inst[19:15];
        rs2     = inst[24:20];
        funct3  = inst[14:12];
        funct7  = inst[31:25];
        case (opcode)
            `R_TYPE : begin
                inst_type = `ALU;
                case (funct7[5])
                    1'b1 : begin
                        case (funct3)
                            3'b000 : inst_code = `SUB;
                            3'b101 : inst_code = `SRA;
                        endcase
                    end
                    1'b0 : begin
                        case (funct3)
                            3'b000 : inst_code = `ADD;
                            3'b001 : inst_code = `SLL;
                            3'b010 : inst_code = `SLT;
                            3'b011 : inst_code = `SLTU;
                            3'b100 : inst_code = `XOR;
                            3'b101 : inst_code = `SRL;
                            3'b110 : inst_code = `OR;
                            3'b111 : inst_code = `AND;
                        endcase
                    end
                endcase
            end
            `I_TYPE0, `I_TYPE1, `I_TYPE2 : begin
                if(opcode == 7'b0010011 && (funct3 == 3'b001 || funct3 == 3'b101)) imm = {{27{1'b0}},inst[24:20]};
                else imm = {{20{inst[31]}},inst[31:20]};
                case(opcode)
                    `I_TYPE0 : begin
                        inst_type = `JMP;
                        inst_code = `JALR;
                    end
                    `I_TYPE1 : begin
                        inst_type = `LD;
                        case (funct3)
                            3'b000 : inst_code = `LB;
                            3'b001 : inst_code = `LH;
                            3'b010 : inst_code = `LW;
                            3'b100 : inst_code = `LBU;
                            3'b101 : inst_code = `LHU;
                        endcase
                    end
                    `I_TYPE2 : begin
                        inst_type = `ALU;
                        case (funct3)
                            3'b000 : inst_code = `ADDI;
                            3'b010 : inst_code = `SLTI;
                            3'b011 : inst_code = `SLTIU;
                            3'b100 : inst_code = `XORI;
                            3'b110 : inst_code = `ORI;
                            3'b111 : inst_code = `ANDI;
                            3'b001 : inst_code = `SLLI; 
                            3'b101 : begin
                                case (funct7[5])
                                    1'b0 : inst_code = `SRLI;
                                    1'b1 : inst_code = `SRAI;
                                endcase
                            end
                        endcase 
                    end
                endcase
            end
            `S_TYPE : begin
                inst_type = `ST;
                imm = {{20{inst[31]}},inst[31:25],inst[11:7]};
                case (funct3)
                    3'b000 : inst_code = `SB;
                    3'b001 : inst_code = `SH;
                    3'b010 : inst_code = `SW;
                endcase
            end
            `B_TYPE : begin
                inst_type = `BRC;
                imm = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                case (funct3)
                    3'b000 : inst_code = `BEQ;
                    3'b001 : inst_code = `BNE;
                    3'b100 : inst_code = `BLT;
                    3'b101 : inst_code = `BGE;
                    3'b110 : inst_code = `BLTU;
                    3'b111 : inst_code = `BGEU;
                endcase
            end
            `U_TYPE0, `U_TYPE1 : begin
                inst_type = `ALU;
                imm = {inst[31:12],{12{1'b0}}};
                case (opcode)
                    `U_TYPE0 : inst_code = `LUI;
                    `U_TYPE1 : inst_code = `AUIPC;
                endcase
            end
            `J_TYPE : begin
                inst_type = `JMP;
                imm = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
                inst_code = `JAL;
            end
        endcase
    end
end

endmodule