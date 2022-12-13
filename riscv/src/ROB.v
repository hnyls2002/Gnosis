`include "Def.v"
module reorder_buffer(
    // cpu
    input wire  clk,
    input wire  rst,
    input wire  rdy,

    // inst info
    input wire              inst_ID_flag,
    input wire [5:0]        inst_ID_code,
    input wire [2:0]        inst_ID_type,
    input wire [`REGBW-1:0] inst_ID_des,
    input wire [31:0]       prd_ID_pc,

    // indicate next
    output wire             ROB_nex_ava,

    // cdb
    input wire              ex_cdb_flag,
    input wire [`ROBBW-1:0] ex_cdb_rob_id,
    input wire [31:0]       ex_cdb_val,
    input wire [31:0]       ex_cdb_rel_pc,
    input wire              ld_cdb_flag,
    input wire [`ROBBW-1:0] ld_cdb_rob_id,
    input wire [31:0]       ld_cdb_val,

    // store_rdy
    input wire              st_rdy_flag,
    input wire [`ROBBW-1:0] st_rdy_rob_id,

    // tell a available rob_id to ID
    output wire [`ROBBW-1:0] ROB_ava_id,

    // commit to reg
    output reg             ROB_cmt_flag,
    output reg [`REGBW-1:0]ROB_cmt_des,
    output reg [31:0]      ROB_cmt_val,

    // commit store
    output reg              ROB_cmt_st_flag,
    output reg [`ROBBW-1:0] ROB_cmt_st_rob_id
);

reg [`ROBSZ-1:0]    busy;
reg [`ROBSZ-1:0]    rob_rdy;
reg [5:0]           inst_code [`ROBSZ-1:0];
reg [2:0]           inst_type [`ROBSZ-1:0];
reg [31:0]          val [`ROBSZ-1:0];
reg [`REGBW-1:0]    des [`ROBSZ-1:0];
reg [31:0]          prd_pc [`ROBSZ-1:0];
reg [31:0]          rel_pc [`ROBSZ-1:0];

integer i, head = 1, tail = 0;
wire [`ROBBW-1:0] hd = head[`ROBBW-1:0];
wire [`ROBBW-1:0] tl = tail[`ROBBW-1:0];
wire [`ROBBW-1:0] nt = tl + 1;

wire rob_rdy_flag = head <= tail && rob_rdy[hd];

assign ROB_nex_ava = rob_rdy_flag || (tail - head + 1 <= `ROBSZ - 2) || (tail - head == `ROBSZ -2 && !inst_ID_flag);
assign ROB_ava_id = nt;

always @(posedge clk) begin
    // update value and ready
    for(i = 0; i < `ROBSZ; i = i + 1) begin
        if(busy[i]) begin
            if(ex_cdb_flag && ex_cdb_rob_id == i[`ROBBW-1:0]) begin
                val[i] <= ex_cdb_val;
                rel_pc[i] <= ex_cdb_rel_pc;
                rob_rdy[i] <= `True;
            end
            if(ld_cdb_flag && ld_cdb_rob_id == i[`ROBBW-1:0]) begin
                val[i] <= ld_cdb_val;
                rob_rdy[i] <= `True;
            end
            if(st_rdy_flag && st_rdy_rob_id == i[`ROBBW-1:0])
                rob_rdy[i] <= `True;
        end
    end

    // receive inst
    if(inst_ID_flag) begin
        busy[nt] <= `True;
        rob_rdy[nt] <= `False;
        inst_code[nt] <= inst_ID_code;
        inst_type[nt] <= inst_ID_type;
        des[nt] <= inst_ID_des;
        prd_pc[nt] <= prd_ID_pc;
        rob_rdy[nt] <= `False;
        tail <= tail + 1;
    end

    if(rob_rdy_flag) begin
        if(inst_type[hd] == `ST) begin
            ROB_cmt_flag <= `False;

            ROB_cmt_st_flag <= `True;
            ROB_cmt_st_rob_id <= hd;
        end
        else begin
            ROB_cmt_st_flag <= `False;

            ROB_cmt_flag <= `True;
            ROB_cmt_des <= des[hd];
            ROB_cmt_val <= val[hd];
        end
        busy[hd] <= `False;
        rob_rdy[hd] <= `False;
        head <= head + 1;
    end

end

endmodule