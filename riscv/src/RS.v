`include "Def.v"

module rs_station(
    // cpu
    input  wire    clk,
    input  wire    rst,
    input  wire    rdy,

    // jump wrong
    input wire                  jump_wrong,

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
    input wire  [31:0]          inst_ID_pc,

    // indicate next cycle will be available
    output wire                 RS_nex_ava,

    // to excute
    output reg                  exe_RS_flag,
    output reg  [31:0]          exe_RS_V1,
    output reg  [31:0]          exe_RS_V2,
    output reg  [31:0]          exe_RS_A,
    output reg  [31:0]          exe_RS_pc,
    output reg  [5:0]           exe_RS_code,
    output reg  [`ROBBW-1:0]    exe_RS_rob_id,

    // CDB to update
    input wire              ex_cdb_flag,
    input wire [`ROBBW-1:0] ex_cdb_rob_id,
    input wire [31:0]       ex_cdb_val,
    input wire              ld_cdb_flag,
    input wire [`ROBBW-1:0] ld_cdb_rob_id,
    input wire [31:0]       ld_cdb_val
);

reg [`RSSZ-1:0]     busy; 
reg [5:0]           inst_code   [`RSSZ-1:0];
reg [31:0]          inst_pc     [`RSSZ-1:0];
reg [31:0]          V1          [`RSSZ-1:0], V2[`RSSZ-1:0];
reg [`ROBBW-1:0]    Q1          [`RSSZ-1:0], Q2[`RSSZ-1:0];
reg [31:0]          A           [`RSSZ-1:0];
reg [`ROBBW-1:0]    rob_id      [`RSSZ-1:0];

integer i;
reg                 rs_ava_flag;
reg                 rs_rdy_flag;
reg [`RSBW-1:0]     rs_ava_id;
reg [`RSBW-1:0]     rs_rdy_id;
reg                 rs_ava_2; // has two or more available

wire issue_RS_flag = inst_ID_flag && inst_ID_type <= `BRC;
assign RS_nex_ava = rs_rdy_flag || rs_ava_2 || (rs_ava_flag && !issue_RS_flag);

// find available and find_ready
always @(*) begin
    rs_ava_flag = `False;
    rs_rdy_flag = `False;
    rs_ava_2    = `False;
    for(i = `RSSZ-1; i >= 0; i = i - 1)
        if(!busy[i])begin
            if(rs_ava_flag == `True)
                rs_ava_2 = `True;
            rs_ava_flag = `True;
            rs_ava_id = i[`RSBW-1:0];
        end
    for(i = `RSSZ-1; i >= 0; i = i - 1)
        if(busy[i] && Q1[i] == 0 && Q2[i] == 0) begin
            rs_rdy_flag = `True;
            rs_rdy_id = i[`RSBW-1:0];
        end
end


always @(posedge clk) begin
    if(rst || jump_wrong) begin
        busy <= 0;
    end
    else if(!rdy) begin
    end
    else begin
        // update Q to V using sequential logic
        for(i = 0; i < `RSSZ; i = i + 1) begin
            if(busy[i]) begin
                if(ex_cdb_flag) begin
                    if(Q1[i] == ex_cdb_rob_id) begin
                        V1[i] <= ex_cdb_val;
                        Q1[i] <= 0;
                    end
                    if(Q2[i] == ex_cdb_rob_id) begin
                        V2[i] <= ex_cdb_val;
                        Q2[i] <= 0;
                    end
                end
                if(ld_cdb_flag) begin
                    if(Q1[i] == ld_cdb_rob_id) begin
                        V1[i] <= ld_cdb_val;
                        Q1[i] <= 0;
                    end
                    if(Q2[i] == ld_cdb_rob_id) begin
                        V2[i] <= ld_cdb_val;
                        Q2[i] <= 0;
                    end
                end
            end
        end

        // insert new
        if(issue_RS_flag) begin
            busy        [rs_ava_id] <= `True;
            inst_code   [rs_ava_id] <= inst_ID_code;
            inst_pc     [rs_ava_id] <= inst_ID_pc;
            A           [rs_ava_id] <= inst_ID_A;
            rob_id      [rs_ava_id] <= inst_ID_rob_id;
            V1          [rs_ava_id] <= inst_ID_V1;
            V2          [rs_ava_id] <= inst_ID_V2;
            Q1          [rs_ava_id] <= inst_ID_Q1;
            Q2          [rs_ava_id] <= inst_ID_Q2;
            // $display("RS insert new  pc = %H : V1 = %d V2 = %d Q1 = %d Q2 = %d",inst_ID_pc, inst_ID_V1, inst_ID_V2, inst_ID_Q1, inst_ID_Q2);
        end

        // send to ALU
        if (rs_rdy_flag) begin
            busy[rs_rdy_id] <= `False;
            exe_RS_flag     <= `True;
            exe_RS_V1       <= V1[rs_rdy_id];
            exe_RS_V2       <= V2[rs_rdy_id];
            exe_RS_A        <= A[rs_rdy_id];
            exe_RS_pc       <= inst_pc[rs_rdy_id];
            exe_RS_code     <= inst_code[rs_rdy_id];
            exe_RS_rob_id   <= rob_id[rs_rdy_id];
        end
        else exe_RS_flag    <= `False;
    end
end

endmodule