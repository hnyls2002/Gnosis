`include "Def.v"

module rs_station(
    // cpu
    input  wire    clk,
    input  wire    rst,
    input  wire    rdy,

    // jump wrong
    input wire                  jump_wrong_stall,

    // inst info
    input wire                  ID_flag, 
    input wire  [31:0]          inst_ID_VQ1,
    input wire  [31:0]          inst_ID_VQ2,
    input wire                  inst_ID_rdy1,
    input wire                  inst_ID_rdy2,
    input wire  [31:0]          inst_ID_A,
    input wire  [5:0]           inst_ID_code,
    input wire  [2:0]           inst_ID_type,
    input wire  [31:0]          inst_ID_rob_id,
    input wire  [31:0]          inst_ID_pc,

    // indicate next cycle will be available
    output wire                 RS_nex_ava,

    // to excute
    output reg                  ALU_flag,
    output reg  [31:0]          ALU_V1,
    output reg  [31:0]          ALU_V2,
    output reg  [31:0]          ALU_A,
    output reg  [31:0]          ALU_inst_pc,
    output reg  [5:0]           ALU_inst_code,
    output reg  [31:0]          ALU_inst_rob_id,

    // CDB to update
    input wire              ex_cdb_flag,
    input wire [31:0]       ex_cdb_rob_id,
    input wire [31:0]       ex_cdb_val,

    input wire              ld_cdb_flag,
    input wire [31:0]       ld_cdb_rob_id,
    input wire [31:0]       ld_cdb_val
);

reg [`RSSZ-1:0]     busy; 
reg [5:0]           inst_code   [`RSSZ-1:0];
reg [31:0]          inst_pc     [`RSSZ-1:0];
reg [31:0]          VQ1         [`RSSZ-1:0];
reg [31:0]          VQ2         [`RSSZ-1:0];
reg [`RSSZ-1:0]     rdy1;
reg [`RSSZ-1:0]     rdy2;
reg [31:0]          A           [`RSSZ-1:0];
reg [31:0]          rob_id      [`RSSZ-1:0];

integer i;
reg                 rs_ava_flag;
reg                 rs_rdy_flag;
reg [`RSBW-1:0]     rs_ava_id;
reg [`RSBW-1:0]     rs_rdy_id;
reg                 rs_ava_2; // has two or more available

wire issue_RS_flag = ID_flag && inst_ID_type <= `BRC;
assign RS_nex_ava = rs_rdy_flag || rs_ava_2 || (rs_ava_flag && !issue_RS_flag);

// find available and find_ready
always @(*) begin
    rs_ava_flag = `False;
    rs_rdy_flag = `False;
    rs_ava_2    = `False;
    rs_rdy_id   = 0;
    rs_ava_id   = 0;
    for(i = `RSSZ-1; i >= 0; i = i - 1)
        if(!busy[i])begin
            if(rs_ava_flag == `True)
                rs_ava_2 = `True;
            rs_ava_flag = `True;
            rs_ava_id = i[`RSBW-1:0];
        end
    for(i = `RSSZ-1; i >= 0; i = i - 1)
        if(busy[i] && rdy1[i] && rdy2[i]) begin
            rs_rdy_flag = `True;
            rs_rdy_id = i[`RSBW-1:0];
        end
end


always @(posedge clk) begin
    if(rst || jump_wrong_stall) begin
        busy <= 0;
        rdy1 <= 0;
        rdy2 <= 0;
    end
    else if(!rdy) begin
    end
    else begin
        // update Q to V using sequential logic
        for(i = 0; i < `RSSZ; i = i + 1) begin
            if(busy[i]) begin
                if(ex_cdb_flag) begin
                    if(!rdy1[i] && VQ1[i] == ex_cdb_rob_id) begin
                        rdy1[i] <= `True;
                        VQ1[i] <= ex_cdb_val;
                    end
                    if(!rdy2[i] && VQ2[i] == ex_cdb_rob_id) begin
                        rdy2[i] <= `True;
                        VQ2[i] <= ex_cdb_val;
                    end
                end
                if(ld_cdb_flag) begin
                    if(!rdy1[i] && VQ1[i] == ld_cdb_rob_id) begin
                        rdy1[i] <= `True;
                        VQ1[i] <= ld_cdb_val;
                    end
                    if(!rdy2[i] && VQ2[i] == ld_cdb_rob_id) begin
                        rdy2[i] <= `True;
                        VQ2[i] <= ld_cdb_val;
                    end
                end
            end
        end

        // insert new
        if(issue_RS_flag) begin
            busy        [rs_ava_id] <= `True;
            inst_code   [rs_ava_id] <= inst_ID_code;
            inst_pc     [rs_ava_id] <= inst_ID_pc;
            VQ1         [rs_ava_id] <= inst_ID_VQ1;
            VQ2         [rs_ava_id] <= inst_ID_VQ2;
            rdy1        [rs_ava_id] <= inst_ID_rdy1;
            rdy2        [rs_ava_id] <= inst_ID_rdy2;
            A           [rs_ava_id] <= inst_ID_A;
            rob_id      [rs_ava_id] <= inst_ID_rob_id;
        end

        // send to ALU
        if (rs_rdy_flag) begin
            busy[rs_rdy_id] <= `False;
            ALU_flag        <= `True;
            ALU_V1          <= VQ1[rs_rdy_id];
            ALU_V2          <= VQ2[rs_rdy_id];
            ALU_A           <= A[rs_rdy_id];
            ALU_inst_pc     <= inst_pc[rs_rdy_id];
            ALU_inst_code   <= inst_code[rs_rdy_id];
            ALU_inst_rob_id <= rob_id[rs_rdy_id];
        end
        else begin
            ALU_flag        <= `False;
        end
    end
end

endmodule