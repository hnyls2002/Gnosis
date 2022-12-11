module dispatcher(
    input   wire            inst_flag,
    input   wire    [31:0]  inst,

    // direct decode infos
    output  wire                inst_ID_flag,
    output  wire [`REGBW-1:0]   inst_ID_rd,
    output  wire [`REGBW-1:0]   inst_ID_rs1,
    output  wire [`REGBW-1:0]   inst_ID_rs2,
    output  wire [31:0]         inst_ID_A, 
    output  wire [5:0]          inst_ID_code,
    output  wire [2:0]          inst_ID_type,

    // send reg id to reg_file to fetch value
    output  wire    [`REGBW-1:0]    rs1_RF,
    output  wire    [`REGBW-1:0]    rs2_RF,
    input   wire    [31:0]          V1_RF,
    input   wire    [31:0]          V2_RF,
    input   wire    [`ROBBW-1:0]    Q1_RF,
    input   wire    [`ROBBW-1:0]    Q2_RF,

    // assign V1,V2,Q1,Q2 from RF to ID
    output  wire [31:0]         inst_ID_V1,
    output  wire [31:0]         inst_ID_V2,
    output  wire [`ROBBW-1:0]   inst_ID_Q1,
    output  wire [`ROBBW-1:0]   inst_ID_Q2,

    // other infos
    input   wire [31:0]         inst_IF_pc, 
    input   wire [31:0]         inst_IF_jpc,
    input   wire [`ROBBW-1:0]   inst_ROB_ava_id,
    output  wire [31:0]         inst_ID_pc, 
    output  wire [31:0]         inst_ID_jpc,
    output  wire [`ROBBW-1:0]   inst_ID_rob_id
);

assign inst_ID_flag = inst_flag;

// get inst info from decoder
decoder decoder0(
    .inst_flag(inst_flag),
    .inst(inst),
    .rd(inst_ID_rd),
    .rs1(inst_ID_rs1),
    .rs2(inst_ID_rs2),
    .imm(inst_ID_A),
    .inst_code(inst_ID_code),
    .inst_type(inst_ID_type)
);

// fetch value from reg_file
assign rs1_Dec = inst_ID_rs1;
assign rs2_Dec = inst_ID_rs2;
assign inst_ID_V1 = V1_RF;
assign inst_ID_V2 = V2_RF;
assign inst_ID_Q1 = Q1_RF;
assign inst_ID_Q2 = Q2_RF;

assign inst_ID_pc = inst_IF_pc;
assign inst_ID_jpc = inst_IF_jpc;
assign inst_ID_rob_id = inst_ROB_ava_id;

endmodule