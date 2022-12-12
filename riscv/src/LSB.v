`include "Def.v"

module ls_buffer(
    // cpu
    input  wire    clk,
    input  wire    rst,
    input  wire    rdy,

    // inst info
    input wire                  inst_ID_flag, 
    input wire  [31:0]          inst_ID_V1,
    input wire  [31:0]          inst_ID_V2,
    input wire  [`ROBBW-1:0]    inst_ID_Q1,
    input wire  [`ROBBW-1:0]    inst_ID_Q2,
    input wire  [31:0]          inst_ID_A,
    input wire  [5:0]           inst_ID_code,
    input wire  [2:0]           inst_ID_type,
    input wire  [`ROBBW-1:0]    inst_ID_rob_id,

    // indicate next cycle will be available
    output wire                 LSB_nex_ava,

    // to mem_ctrl

    // CDB to update
    input wire              ex_cdb_flag,
    input wire [`ROBBW-1:0] ex_cdb_rob_id,
    input wire [31:0]       ex_cdb_val,
    input wire              ld_cdb_flag,
    input wire [`ROBBW-1:0] ld_cdb_rob_id,
    input wire [31:0]       ld_cdb_val
);

endmodule