`include "Def.v"

module ls_buffer(
    // cpu
    input  wire    clk,
    input  wire    rst,
    input  wire    rdy,

    // jump wrong
    input   wire    jump_wrong,
    output  wire    lsb_clear_done,

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

    // receive from mem_ctrl
    input wire                  lsb_done_flag,

    // request to mem_ctrl
    output reg                  lsb_req_flag,
    output reg [1:0]            lsb_req_width,
    output reg                  lsb_req_type,
    output reg [31:0]           lsb_req_addr,
    output reg [31:0]           lsb_req_data,
    output reg [`ROBBW-1:0]     lsb_req_rob_id,

    // CDB to update
    input wire                  ex_cdb_flag,
    input wire [`ROBBW-1:0]     ex_cdb_rob_id,
    input wire [31:0]           ex_cdb_val,
    input  wire [`ROBBW-1:0]    ld_cdb_rob_id,
    input  wire                 ld_cdb_flag,
    input  wire [31:0]          ld_cdb_val,

    // commit store
    input wire                  st_cmt_flag,
    input wire [`ROBBW-1:0]     st_cmt_rob_id,

    // two register calc done, send to ROB
    output reg                  st_rdy_flag,
    output reg [`ROBBW-1:0]     st_rdy_rob_id
);

reg [`LSBSZ-1:0]    busy;
reg [5:0]           inst_code [`LSBSZ-1:0];
reg [2:0]           inst_type [`LSBSZ-1:0];
reg [`ROBBW-1:0]    inst_rob_id [`LSBSZ-1:0];
reg [31:0]          V1[`LSBSZ-1:0], V2[`LSBSZ-1:0];
reg [`ROBBW-1:0]    Q1[`LSBSZ-1:0], Q2[`LSBSZ-1:0];
reg [31:0]          A[`LSBSZ-1:0];
reg [`LSBSZ-1:0]    cmt_done;
reg [`LSBSZ-1:0]    rob_know_store_rdy; // if ture, then ROB knows this store is ready

integer i,head = 1, tail = 0;
wire [`LSBBW-1:0] hd = head[`LSBBW-1:0];
wire [`LSBBW-1:0] tl = tail[`LSBBW-1:0];
wire [`LSBBW-1:0] nt = tl + 1;

reg lsb_rdy_flag;

wire issue_LSB_flag = inst_ID_flag && inst_ID_type >= `LD;
assign LSB_nex_ava = lsb_done_flag || (tail - head + 1 <= `LSBSZ - 2) || (tail - head == `LSBSZ -2  && !issue_LSB_flag);

reg                 store_can_be_knew;
reg [`LSBBW-1:0]    store_can_be_knew_lsb_id;

assign lsb_clear_done = head == tail + 1;

always @(*) begin
    // check the head is ready
    if(tail >= head) begin
        if(inst_type[hd] == `LD && Q1[hd] == 0) lsb_rdy_flag = `True;
        else if(inst_type[hd] == `ST && cmt_done[hd]) lsb_rdy_flag = `True;
        else lsb_rdy_flag = `False;
    end

    // find store can be knew
    store_can_be_knew = `False;
    for(i = 0; i < `LSBSZ; i = i + 1) begin
        if(busy[i] && !rob_know_store_rdy[i] && inst_type[i] == `ST && Q1[i] == 0 && Q2[i] == 0) begin
            store_can_be_knew = `True;
            store_can_be_knew_lsb_id = i[`LSBBW-1:0];
        end
    end
end

always @(posedge clk) begin
    if(rst) begin
        busy <= 0;
        cmt_done <= 0;
        rob_know_store_rdy <= 0;
        head <= 1;
        tail <= 0;
    end
    else if(!rdy) begin
    end
    else if(jump_wrong) begin
        if(!lsb_clear_done) begin
            if(lsb_done_flag) head <= head + 1;
            else if(!lsb_rdy_flag) head <= tail + 1;
            else begin
                if(inst_type[hd] == `LD) head <= head + 1;
                else begin
                    lsb_req_flag <= `True;
                    lsb_req_addr <= V1[hd] + $signed(A[hd]);
                    lsb_req_rob_id <= inst_rob_id[hd];
                    lsb_req_type <= 1'b1;
                    lsb_req_data <= V2[hd];
                    case(inst_code[hd])
                        `SB : lsb_req_width <= 2'b00;
                        `SH : lsb_req_width <= 2'b01;
                        `SW : lsb_req_width <= 2'b10;
                        default:;
                    endcase
                end
            end
        end
    end
    else begin
        // update value
        for(i = 0; i < `LSBSZ; i = i + 1) begin
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

        // send store can be knew to ROB
        if(store_can_be_knew) begin
            st_rdy_flag <= `True;
            st_rdy_rob_id <= inst_rob_id[store_can_be_knew_lsb_id];
            rob_know_store_rdy[store_can_be_knew_lsb_id] <= `True;
        end
        else begin
            st_rdy_flag <= `False;
            st_rdy_rob_id <= 0;
        end

        // push inst
        if(issue_LSB_flag) begin
            busy[nt] <= `True;
            inst_code[nt] <= inst_ID_code;
            inst_type[nt] <= inst_ID_type;
            inst_rob_id[nt] <= inst_ID_rob_id;
            V1[nt] <= inst_ID_V1;
            V2[nt] <= inst_ID_V2;
            Q1[nt] <= inst_ID_Q1;
            Q2[nt] <= inst_ID_Q2;
            A[nt] <= inst_ID_A;
            cmt_done[nt] <= `False;
            rob_know_store_rdy[nt] <= `False;
            tail <= tail + 1;
        end

        // commit store
        if(st_cmt_flag) begin
            for(i = 0; i < `LSBSZ; i = i + 1)
                if(busy[i] && inst_type[i] == `ST && inst_rob_id[i] == st_cmt_rob_id)
                    cmt_done[i] <= `True;
        end

        // memory access done, pop head
        if(lsb_done_flag) begin
            busy[hd] <= `False;
            head <= head + 1;
        end
        else if(lsb_rdy_flag) begin // send to mem_ctrl
            lsb_req_flag <= `True;
            lsb_req_addr <= V1[hd] + $signed(A[hd]);
            lsb_req_rob_id <= inst_rob_id[hd];
            case(inst_type[hd])
                `LD : begin
                    lsb_req_type <= 1'b0;
                    lsb_req_data <= 0;
                end
                `ST : begin 
                    lsb_req_type <= 1'b1;
                    lsb_req_data <= V2[hd];
                end
                default:;
            endcase
            case(inst_code[hd])
                `LB : lsb_req_width <= 2'b00;
                `LW : lsb_req_width <= 2'b10;
                `LBU : lsb_req_width <= 2'b00; 
                `LHU : lsb_req_width <= 2'b01;
                `SB : lsb_req_width <= 2'b00;
                `SH : lsb_req_width <= 2'b01;
                `SW : lsb_req_width <= 2'b10;
                default:;
            endcase
        end
    end
end

endmodule