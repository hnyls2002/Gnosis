`include "Def.v"

module reg_file(
    // cpu
    input  wire    clk,
    input  wire    rst,
    input  wire    rdy,

    // jump wrong
    input  wire    jump_wrong,

    // fetch register
    input   wire    [`REGBW-1:0]   rs1,
    input   wire    [`REGBW-1:0]   rs2,
    output  reg     [31:0]         V1,
    output  reg     [31:0]         V2, 
    output  reg     [`ROBBW-1:0]   Q1,
    output  reg     [`ROBBW-1:0]   Q2,

    // fetch from ROB
    output  wire [`ROBBW-1:0]   id1, 
    output  wire [`ROBBW-1:0]   id2,
    input   wire                id1_ready,
    input   wire                id2_ready,
    input   wire [31:0]         id1_val, 
    input   wire [31:0]         id2_val,

    // ROB commits
    input   wire                flag_ROB,
    input   wire [`REGBW-1:0]   rd_ROB, 
    input   wire [`ROBBW-1:0]   id_ROB,
    input   wire [31:0]         val_ROB,

    // instruction rename
    input   wire                flag_rename,
    input   wire [`REGBW-1:0]   rd_rename,
    input   wire [`ROBBW-1:0]   id_rename,

    // cdb 
    input wire                  ex_cdb_flag,
    input wire [`ROBBW-1:0]     ex_cdb_rob_id,
    input wire [31:0]           ex_cdb_val,
    input wire                  ld_cdb_flag,
    input wire [`ROBBW-1:0]     ld_cdb_rob_id,
    input wire [31:0]           ld_cdb_val
);

reg [31:0]          reg_val [`REGSZ-1:0];
reg [`ROBBW-1:0]    rob_id  [`REGSZ-1:0]; // rob_id start from 1

assign id1 = rob_id[rs1];
assign id2 = rob_id[rs2];

always @(*) begin
    V1 = 0;
    V2 = 0;
    Q1 = 0;
    Q2 = 0;
    if(id1 == 0) V1 = reg_val[rs1];
    else begin
        if(id1_ready) V1 = id1_val;
        else if(ex_cdb_flag && id1 == ex_cdb_rob_id) V1 = ex_cdb_val;
        else if(ld_cdb_flag && id1 == ld_cdb_rob_id) V1 = ld_cdb_val;
        else Q1 = id1;
    end
    if(id2 == 0) V2 = reg_val[rs2];
    else begin
        if(id2_ready) V2 = id2_val;
        else if(ex_cdb_flag && id2 == ex_cdb_rob_id) V2 = ex_cdb_val;
        else if(ld_cdb_flag && id2 == ld_cdb_rob_id) V2 = ld_cdb_val;
        else Q2 = id2;
    end
end

integer i;

always @(posedge clk) begin
    if(rst || jump_wrong) begin
        for(i = 0; i < `REGSZ; i = i + 1)
            rob_id [i] <= 0;
    end
    else if(!rdy) begin
    end
    else begin
        if(flag_ROB && rob_id[rd_ROB] == id_ROB) begin
            reg_val [rd_ROB] <= val_ROB;
            rob_id  [rd_ROB] <= 0;
        end
        if(flag_rename) rob_id[rd_rename] <= id_rename;
    end
end

endmodule