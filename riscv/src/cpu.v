// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "MC.v"
`include "IF.v"
`include "ID.v"
`include "ALU.v"
`include "LSB.v"
`include "RS.v"
`include "ROB.v"
`include "RF.v"

module cpu(input wire           clk_in,
           input wire           rst_in,
           input wire			rdy_in,
           input wire   [7:0]   mem_din,
           output wire  [7:0]   mem_dout,
           output wire  [31:0]  mem_a,
           output wire          mem_wr,
           input wire           io_buffer_full,// 1 if uart buffer is full
           output wire  [31:0]  dbgreg_dout);
    
    // implementation goes h
    // Specifications:
    // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
    // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
    // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
    // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16] == 2'b11)
    // - 0x30000 read: read a byte from input
    // - 0x30000 write: write a byte to output (write 0x00 is ignored)
    // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
    // - 0x30004 write: indicates program stop (will output '\0' through uart tx)
    
    // MC <-> IF
    wire            IF_MC_req;
    wire [31:0]     IF_MC_addr;
    wire            MC_IF_flag;
    wire [31:0]     MC_IF_inst;

    // LSB -> MC
    wire                LSB_MC_req;
    wire [1:0]          LSB_MC_width;
    wire                LSB_MC_type;
    wire [31:0]         LSB_MC_addr;
    wire [31:0]         LSB_MC_val;
    wire [`ROBBW-1:0]   LSB_MC_rob_id;

    // MC -> LSB
    wire                MC_LSB_done_flag;

    // ROB : jump wrong
    wire                jump_wrong;
    wire [31:0]         jump_rel_pc;
    // LSB : lsb done
    wire                LSB_clear_done;

    // next availables
    wire                RS_nex_ava;
    wire                LSB_nex_ava;
    wire                ROB_nex_ava;

    // IF -> ID
    wire                IF_ID_flag;
    wire [31:0]         IF_ID_inst;

    // ID ->
    wire                ID_flag;
    wire [`REGBW-1:0]   ID_rd;
    wire [`REGBW-1:0]   ID_rs1;
    wire [`REGBW-1:0]   ID_rs2;
    wire [31:0]         ID_A;
    wire [5:0]          ID_code;
    wire [2:0]          ID_type;

    // ID ->
    // get from regfile
    wire [31:0]         ID_V1;
    wire [31:0]         ID_V2;
    wire [`ROBBW-1:0]   ID_Q1;
    wire [`ROBBW-1:0]   ID_Q2;

    // ID ->
    // get from IF
    wire [31:0]         ID_inst_pc;
    wire [31:0]         ID_inst_prd_pc;

    // ID -> 
    // get from ROB
    wire [`ROBBW-1:0]   ID_rob_id;

    // RS -> ALU
    wire RS_ALU_flag;
    wire [31:0]         RS_ALU_V1;
    wire [31:0]         RS_ALU_V2;
    wire [31:0]         RS_ALU_A;
    wire [31:0]         RS_ALU_inst_pc;
    wire [5:0]          RS_ALU_inst_code;
    wire [`ROBBW-1:0]   RS_ALU_rob_id;

    // ex cdb
    wire                ex_cdb_flag;
    wire [31:0]         ex_cdb_val;
    wire [`ROBBW-1:0]   ex_cdb_rob_id;
    wire [31:0]         ex_cdb_rel_pc;

    // ld cdb
    wire                ld_cdb_flag;
    wire [31:0]         ld_cdb_val;
    wire [`ROBBW-1:0]   ld_cdb_rob_id;

    // LSB < - > ROB
    // store commit and ready
    wire                ROB_st_cmt_flag;
    wire [`ROBBW-1:0]   ROB_st_cmt_rob_id;
    wire                LSB_st_rdy_flag;
    wire [`ROBBW-1:0]   LSB_st_rdy_rob_id;

    // ROB commit to RF
    wire                ROB_rf_cmt_flag;
    wire [`REGBW-1:0]   ROB_rf_cmt_des;
    wire [31:0]         ROB_rf_cmt_val;
    wire [`ROBBW-1:0]   ROB_rf_cmt_rob_id;

    // RF request reg value in ROB
    wire [`REGBW-1:0]   RF_id1;
    wire [`REGBW-1:0]   RF_id2;
    wire                RF_id1_ready;
    wire                RF_id2_ready;
    wire [31:0]         RF_id1_val;
    wire [31:0]         RF_id2_val;

    mem_ctrl mem_ctrl0(
        // cpu
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in),
        .io_buffer_full(io_buffer_full),

        // jump wrong
        .jump_wrong(jump_wrong),

        // ram
        .mem_din(mem_din),
        .mem_dout(mem_dout),
        .mem_a(mem_a),
        .mem_wr(mem_wr),

        // IF
        .inst_IF_req(IF_MC_req),
        .inst_IF_addr(IF_MC_addr),
        .inst_IF_flag(MC_IF_flag),
        .inst_IF(MC_IF_inst),

        // LSB
        .LSB_req(LSB_MC_req),
        .LSB_width(LSB_MC_width),
        .LSB_type(LSB_MC_type),
        .LSB_addr(LSB_MC_addr),
        .LSB_val(LSB_MC_val),
        .LSB_rob_id(LSB_MC_rob_id),

        // lsb done
        .lsb_done_flag(MC_LSB_done_flag),

        // ld cdb
        .ld_cdb_flag(ld_cdb_flag),
        .ld_cdb_val(ld_cdb_val),
        .ld_cdb_rob_id(ld_cdb_rob_id)
    );

    inst_fetcher inst_fetcher0(
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in),

        // jump wrong
        .jump_wrong(jump_wrong),
        .jump_rel_pc(jump_rel_pc),

        // MC
        .inst_MC_flag(MC_IF_flag),
        .inst_MC(MC_IF_inst),
        .inst_MC_req(IF_MC_req),
        .inst_MC_addr(IF_MC_addr),

        // stalls
        .RS_nex_ava(RS_nex_ava),
        .LSB_nex_ava(LSB_nex_ava),
        .ROB_nex_ava(ROB_nex_ava),

        // dispatcher
        .inst_ID_flag(IF_ID_flag),
        .inst_ID(IF_ID_inst),
        .inst_pc(ID_inst_pc),
        .inst_prd_pc(ID_inst_prd_pc)
    );

    dispatcher dispatcher0(
        .inst_flag(IF_ID_flag),
        .inst(IF_ID_inst),

        // direct decode infos
        .inst_ID_flag(ID_flag),
        .inst_ID_rd(ID_rd),
        .inst_ID_rs1(ID_rs1),
        .inst_ID_rs2(ID_rs2),
        .inst_ID_A(ID_A),
        .inst_ID_code(ID_code),
        .inst_ID_type(ID_type)
    );

    alu alu0(
        .flag(RS_ALU_flag),
        .V1(RS_ALU_V1),
        .V2(RS_ALU_V2),
        .A(RS_ALU_A),
        .inst_pc(RS_ALU_inst_pc),
        .inst_code(RS_ALU_inst_code),
        .inst_rob_id(RS_ALU_rob_id),

        // ex cdb
        .ex_cdb_flag(ex_cdb_flag),
        .ex_cdb_val(ex_cdb_val),
        .ex_cdb_rob_id(ex_cdb_rob_id),
        .ex_cdb_rel_pc(ex_cdb_rel_pc)
    );

    ls_buffer ls_buffer0(
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in),

        // jump wrong
        .jump_wrong(jump_wrong),
        .lsb_clear_done(LSB_clear_done),

        // inst info
        .inst_ID_flag(ID_flag),
        .inst_ID_V1(ID_V1),
        .inst_ID_V2(ID_V2),
        .inst_ID_Q1(ID_Q1),
        .inst_ID_Q2(ID_Q2),
        .inst_ID_A(ID_A),
        .inst_ID_code(ID_code),
        .inst_ID_type(ID_type),
        .inst_ID_rob_id(ID_rob_id),

        // LSB nex ava
        .LSB_nex_ava(LSB_nex_ava),

        // from MC
        .lsb_done_flag(MC_LSB_done_flag),

        // to MC
        .lsb_req_flag(LSB_MC_req),
        .lsb_req_width(LSB_MC_width),
        .lsb_req_type(LSB_MC_type),
        .lsb_req_addr(LSB_MC_addr),
        .lsb_req_data(LSB_MC_val),
        .lsb_req_rob_id(LSB_MC_rob_id),

        // CDB
        .ex_cdb_flag(ex_cdb_flag),
        .ex_cdb_val(ex_cdb_val),
        .ex_cdb_rob_id(ex_cdb_rob_id),
        .ld_cdb_flag(ld_cdb_flag),
        .ld_cdb_val(ld_cdb_val),
        .ld_cdb_rob_id(ld_cdb_rob_id),

        // store commit
        .st_cmt_flag(ROB_st_cmt_flag),
        .st_cmt_rob_id(ROB_st_cmt_rob_id),

        // pick ready
        .st_rdy_flag(LSB_st_rdy_flag),
        .st_rdy_rob_id(LSB_st_rdy_rob_id)
    );

    rs_station rs_station0(
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in),

        // jump wrong
        .jump_wrong(jump_wrong),

        // inst info
        .inst_ID_flag(ID_flag),
        .inst_ID_V1(ID_V1),
        .inst_ID_V2(ID_V2),
        .inst_ID_Q1(ID_Q1),
        .inst_ID_Q2(ID_Q2),
        .inst_ID_A(ID_A),
        .inst_ID_code(ID_code),
        .inst_ID_type(ID_type),
        .inst_ID_rob_id(ID_rob_id),
        .inst_ID_pc(ID_inst_pc),

        // RS nex ava
        .RS_nex_ava(RS_nex_ava),
        
        // to ALU
        .exe_RS_flag(RS_ALU_flag),
        .exe_RS_V1(RS_ALU_V1),
        .exe_RS_V2(RS_ALU_V2),
        .exe_RS_A(RS_ALU_A),
        .exe_RS_pc(RS_ALU_inst_pc),
        .exe_RS_code(RS_ALU_inst_code),
        .exe_RS_rob_id(RS_ALU_rob_id),

        // CDB
        .ex_cdb_flag(ex_cdb_flag),
        .ex_cdb_val(ex_cdb_val),
        .ex_cdb_rob_id(ex_cdb_rob_id),
        .ld_cdb_flag(ld_cdb_flag),
        .ld_cdb_val(ld_cdb_val),
        .ld_cdb_rob_id(ld_cdb_rob_id)
    );

    reorder_buffer reorder_buffer0(
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in),

        // jump wrong
        .jump_wrong(jump_wrong),
        .jump_rel_pc(jump_rel_pc),
        .lsb_clear_done(LSB_clear_done),

        // inst info
        .inst_ID_flag(ID_flag),
        .inst_ID_code(ID_code),
        .inst_ID_type(ID_type),
        .inst_ID_des(ID_rd),
        .prd_ID_pc(ID_inst_prd_pc),

        // ROB nex ava
        .ROB_nex_ava(ROB_nex_ava),

        // cdb 
        .ex_cdb_flag(ex_cdb_flag),
        .ex_cdb_val(ex_cdb_val),
        .ex_cdb_rob_id(ex_cdb_rob_id),
        .ex_cdb_rel_pc(ex_cdb_rel_pc),
        .ld_cdb_flag(ld_cdb_flag),
        .ld_cdb_val(ld_cdb_val),
        .ld_cdb_rob_id(ld_cdb_rob_id),

        // store rdy
        .st_rdy_flag(LSB_st_rdy_flag),
        .st_rdy_rob_id(LSB_st_rdy_rob_id),

        // ava rob id
        .ROB_ava_id(ID_rob_id),

        // commit reg
        .ROB_cmt_rf_flag(ROB_rf_cmt_flag),
        .ROB_cmt_rf_des(ROB_rf_cmt_des),
        .ROB_cmt_rf_rob_id(ROB_rf_cmt_rob_id),
        .ROB_cmt_rf_val(ROB_rf_cmt_val),

        // commit store
        .ROB_cmt_st_flag(ROB_st_cmt_flag),
        .ROB_cmt_st_rob_id(ROB_st_cmt_rob_id),

        // request reg file
        .RF_id1(RF_id1),
        .RF_id2(RF_id2),
        .RF_id1_ready(RF_id1_ready),
        .RF_id2_ready(RF_id2_ready),
        .RF_id1_val(RF_id1_val),
        .RF_id2_val(RF_id2_val)
    );

    reg_file reg_file0(
        .clk(clk_in),
        .rst(rst_in),
        .rdy(rdy_in),

        // jump wrong
        .jump_wrong(jump_wrong),

        // fetch register
        .rs1(ID_rs1),
        .rs2(ID_rs2),
        .V1(ID_V1),
        .V2(ID_V2),
        .Q1(ID_Q1),
        .Q2(ID_Q2),

        // fetch from ROB
        .id1(RF_id1),
        .id2(RF_id2),
        .id1_ready(RF_id1_ready),
        .id2_ready(RF_id2_ready),
        .id1_val(RF_id1_val),
        .id2_val(RF_id2_val),
        
        // ROB commits
        .flag_ROB(ROB_rf_cmt_flag),
        .rd_ROB(ROB_rf_cmt_des),
        .id_ROB(ROB_rf_cmt_rob_id),
        .val_ROB(ROB_rf_cmt_val),

        // instruction rename
        .flag_rename(ID_flag),
        .rd_rename(ID_rd),
        .id_rename(ID_rob_id),

        // cbd 
        .ex_cdb_flag(ex_cdb_flag),
        .ex_cdb_val(ex_cdb_val),
        .ex_cdb_rob_id(ex_cdb_rob_id),
        .ld_cdb_flag(ld_cdb_flag),
        .ld_cdb_val(ld_cdb_val),
        .ld_cdb_rob_id(ld_cdb_rob_id)
    );

    always @(posedge clk_in) begin
        if (rst_in) begin // reset 
        end
        else if (!rdy_in) begin // pause the cpu
        end
        else begin // just do it
        end
    end
    
endmodule