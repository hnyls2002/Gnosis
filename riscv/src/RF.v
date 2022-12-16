`include "Def.v"

module reg_file(
    // cpu
    input  wire    clk,
    input  wire    rst,
    input  wire    rdy,

    // jump wrong
    input  wire    jump_wrong_stall,

    // fetch register
    input   wire    [4:0]   rs1,
    input   wire    [4:0]   rs2,
    output  reg     [31:0]  VQ1,
    output  reg     [31:0]  VQ2,
    output  reg             rs1_rdy, 
    output  reg             rs2_rdy,

    // fetch from ROB
    output  wire [31:0]         rob_id1, 
    output  wire [31:0]         rob_id2,
    input   wire                rob_id1_rdy,
    input   wire                rob_id2_rdy,
    input   wire [31:0]         rob_id1_val, 
    input   wire [31:0]         rob_id2_val,

    // ROB commits
    input   wire                ROB_cmt_flag,
    input   wire [4:0]          ROB_cmt_rd,
    input   wire [31:0]         ROB_cmt_rob_id,
    input   wire [31:0]         ROB_cmt_val,

    // instruction rename
    input   wire                ID_rnm_flag,
    input   wire [4:0]          ID_rnm_rd,
    input   wire [31:0]         ID_rnm_rob_id,

    // cdb 
    input wire                  ex_cdb_flag,
    input wire [31:0]           ex_cdb_rob_id,
    input wire [31:0]           ex_cdb_val,
    input wire                  ld_cdb_flag,
    input wire [31:0]           ld_cdb_rob_id,
    input wire [31:0]           ld_cdb_val
);

reg [`REGSZ-1:0]    busy;
reg [31:0]          reg_val [`REGSZ-1:0];
reg [31:0]          rob_id  [`REGSZ-1:0];

assign rob_id1 = rob_id[rs1];
assign rob_id2 = rob_id[rs2];

always @(*) begin
    rs1_rdy = `True;
    if(!busy[rs1]) VQ1 = reg_val[rs1];
    else begin
        if(rob_id1_rdy) VQ1 = rob_id1_val;
        else if(ex_cdb_flag && rob_id1 == ex_cdb_rob_id) VQ1 = ex_cdb_val;
        else if(ld_cdb_flag && rob_id1 == ld_cdb_rob_id) VQ1 = ld_cdb_val;
        else begin
            rs1_rdy = `False;
            VQ1 = rob_id1;
        end
    end

    rs2_rdy = `True;
    if(!busy[rs2]) VQ2 = reg_val[rs2];
    else begin
        if(rob_id2_rdy) VQ2 = rob_id2_val;
        else if(ex_cdb_flag && rob_id2 == ex_cdb_rob_id) VQ2 = ex_cdb_val;
        else if(ld_cdb_flag && rob_id2 == ld_cdb_rob_id) VQ2 = ld_cdb_val;
        else begin
            rs2_rdy = `False;
            VQ2 = rob_id2;
        end
    end
end

integer i;

always @(posedge clk) begin
    if(rst) begin
        busy <= 0;
        for(i = 0; i < `REGSZ; i = i + 1)begin
             reg_val[i] <= 0;
             rob_id[i] <= 0;
        end
    end
    else if(!rdy) begin
    end
    else if(jump_wrong_stall) begin
        busy <= 0;
        for(i = 0; i < `REGSZ; i = i + 1) rob_id[i] <= 0;
    end
    else begin
        // update val
        if(busy[ROB_cmt_rd] && ROB_cmt_flag &&  rob_id[ROB_cmt_rd] == ROB_cmt_rob_id) begin
            busy[ROB_cmt_rd] <= `False;
            reg_val[ROB_cmt_rd] <= ROB_cmt_val;
            rob_id[ROB_cmt_rd] <= 0;
        end
        
        // issue rename
        if(ID_rnm_flag) begin
            busy[ID_rnm_rd] <= `True;
            rob_id[ID_rnm_rd] <= ID_rnm_rob_id;
        end

    end

    // zero register
    busy[0] <= `False;
    rob_id[0] <= 0;
    reg_val[0] <= 0;
end

endmodule