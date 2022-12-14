`include "Def.v"

module dispatcher(
    input   wire                inst_flag,
    input   wire    [31:0]      inst,

    // direct decode infos
    output  wire                inst_ID_flag,
    output  reg [`REGBW-1:0]    inst_ID_rd,
    output  reg [`REGBW-1:0]    inst_ID_rs1,
    output  reg [`REGBW-1:0]    inst_ID_rs2,
    output  reg [31:0]          inst_ID_A, 
    output  reg [5:0]           inst_ID_code,
    output  reg [2:0]           inst_ID_type

    // // send reg id to reg_file to fetch value
    // input   wire    [31:0]          V1_RF,
    // input   wire    [31:0]          V2_RF,
    // input   wire    [`ROBBW-1:0]    Q1_RF,
    // input   wire    [`ROBBW-1:0]    Q2_RF,

    // // assign V1,V2,Q1,Q2 from RF to ID
    // output  wire [31:0]         inst_ID_V1,
    // output  wire [31:0]         inst_ID_V2,
    // output  wire [`ROBBW-1:0]   inst_ID_Q1,
    // output  wire [`ROBBW-1:0]   inst_ID_Q2,

    // // other infos
    // input   wire [31:0]         inst_IF_pc, 
    // input   wire [31:0]         inst_IF_prd_pc,
    // input   wire [`ROBBW-1:0]   inst_ROB_ava_id,

    // output  wire [31:0]         inst_ID_pc, 
    // output  wire [31:0]         inst_ID_prd_pc,
    // output  wire [`ROBBW-1:0]   inst_ID_rob_id
);

assign inst_ID_flag = inst_flag;

wire [2:0]  funct3 = inst[14:12];
wire [6:0]  funct7 = inst[31:25];
wire [6:0]  opcode = inst[6:0];

always @(*) begin
    if(inst_flag) begin
        inst_ID_rd = 0;
        inst_ID_rs1 = 0;
        inst_ID_rs2 = 0;
        inst_ID_A = 0;
        case (opcode)
            `R_TYPE : begin
                inst_ID_rd  = inst[11:7];
                inst_ID_rs1 = inst[19:15];
                inst_ID_rs2 = inst[24:20];
                inst_ID_type = `ALU;
                case (funct7[5])
                    1'b1 : begin
                        case (funct3)
                            3'b000 : inst_ID_code = `SUB;
                            3'b101 : inst_ID_code = `SRA;
                            default:;
                        endcase
                    end
                    1'b0 : begin
                        case (funct3)
                            3'b000 : inst_ID_code = `ADD;
                            3'b001 : inst_ID_code = `SLL;
                            3'b010 : inst_ID_code = `SLT;
                            3'b011 : inst_ID_code = `SLTU;
                            3'b100 : inst_ID_code = `XOR;
                            3'b101 : inst_ID_code = `SRL;
                            3'b110 : inst_ID_code = `OR;
                            3'b111 : inst_ID_code = `AND;
                        endcase
                    end
                endcase
            end
            `I_TYPE0, `I_TYPE1, `I_TYPE2 : begin
                inst_ID_rd  = inst[11:7];
                inst_ID_rs1 = inst[19:15];
                if(opcode == 7'b0010011 && (funct3 == 3'b001 || funct3 == 3'b101)) inst_ID_A = {{27{1'b0}},inst[24:20]};
                else inst_ID_A = {{20{inst[31]}},inst[31:20]};
                case(opcode)
                    `I_TYPE0 : begin
                        inst_ID_type = `JMP;
                        inst_ID_code = `JALR;
                    end
                    `I_TYPE1 : begin
                        inst_ID_type = `LD;
                        case (funct3)
                            3'b000 : inst_ID_code = `LB;
                            3'b001 : inst_ID_code = `LH;
                            3'b010 : inst_ID_code = `LW;
                            3'b100 : inst_ID_code = `LBU;
                            3'b101 : inst_ID_code = `LHU;
                            default:;
                        endcase
                    end
                    `I_TYPE2 : begin
                        inst_ID_type = `ALU;
                        case (funct3)
                            3'b000 : inst_ID_code = `ADDI;
                            3'b010 : inst_ID_code = `SLTI;
                            3'b011 : inst_ID_code = `SLTIU;
                            3'b100 : inst_ID_code = `XORI;
                            3'b110 : inst_ID_code = `ORI;
                            3'b111 : inst_ID_code = `ANDI;
                            3'b001 : inst_ID_code = `SLLI; 
                            3'b101 : begin
                                case (funct7[5])
                                    1'b0 : inst_ID_code = `SRLI;
                                    1'b1 : inst_ID_code = `SRAI;
                                endcase
                            end
                        endcase 
                    end
                    default:;
                endcase
            end
            `S_TYPE : begin
                inst_ID_rs1 = inst[19:15];
                inst_ID_rs2 = inst[24:20];
                inst_ID_type = `ST;
                inst_ID_A = {{20{inst[31]}},inst[31:25],inst[11:7]};
                case (funct3)
                    3'b000 : inst_ID_code = `SB;
                    3'b001 : inst_ID_code = `SH;
                    3'b010 : inst_ID_code = `SW;
                    default:;
                endcase
            end
            `B_TYPE : begin
                inst_ID_rs1 = inst[19:15];
                inst_ID_rs2 = inst[24:20];
                inst_ID_type = `BRC;
                inst_ID_A = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                case (funct3)
                    3'b000 : inst_ID_code = `BEQ;
                    3'b001 : inst_ID_code = `BNE;
                    3'b100 : inst_ID_code = `BLT;
                    3'b101 : inst_ID_code = `BGE;
                    3'b110 : inst_ID_code = `BLTU;
                    3'b111 : inst_ID_code = `BGEU;
                    default:;
                endcase
            end
            `U_TYPE0, `U_TYPE1 : begin
                inst_ID_rd  = inst[11:7];
                inst_ID_type = `ALU;
                inst_ID_A = {inst[31:12],{12{1'b0}}};
                case (opcode)
                    `U_TYPE0 : inst_ID_code = `LUI;
                    `U_TYPE1 : inst_ID_code = `AUIPC;
                    default  :;
                endcase
            end
            `J_TYPE : begin
                inst_ID_rd  = inst[11:7];
                inst_ID_type = `JMP;
                inst_ID_A = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
                inst_ID_code = `JAL;
            end
            default:;
        endcase
    end
end

// // fetch value from reg_file
// assign inst_ID_V1 = V1_RF;
// assign inst_ID_V2 = V2_RF;
// assign inst_ID_Q1 = Q1_RF;
// assign inst_ID_Q2 = Q2_RF;

// // fetch info from IF and ROB
// assign inst_ID_pc = inst_IF_pc;
// assign inst_ID_prd_pc = inst_IF_prd_pc;
// assign inst_ID_rob_id = inst_ROB_ava_id;

endmodule