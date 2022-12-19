`include "Def.v"

module reorder_buffer(
    // cpu
    input wire  clk,
    input wire  rst,
    input wire  rdy,

    // jump wrong
    output reg              jump_wrong_flag,
    output reg              jump_wrong_stall,
    output reg [31:0]       jump_rel_pc,
    input wire              lsb_clear_done,

    // inst info
    input wire              ID_inst_flag,
    input wire [2:0]        ID_inst_type,
    input wire [4:0]        ID_inst_rd,
    input wire [31:0]       ID_inst_prd_pc,

    `ifdef LOG
        input wire [31:0]       log_inst_pc_in,
    `endif

    // indicate next
    output wire             ROB_nex_ava,

    // cdb
    input wire              ex_cdb_flag,
    input wire [`ROBWD-1:0] ex_cdb_rob_id_cut,
    input wire [31:0]       ex_cdb_val,
    input wire [31:0]       ex_cdb_rel_pc,

    input wire              ld_cdb_flag,
    input wire [`ROBWD-1:0] ld_cdb_rob_id_cut,
    input wire [31:0]       ld_cdb_val,

    // store_rdy
    input wire              st_rdy_flag,
    input wire [`ROBWD-1:0] st_rdy_rob_id_cut,

    `ifdef LOG
        input wire [31:0]       log_st_rdy_val,
        input wire [31:0]       log_st_rdy_addr,
    `endif

    // tell a available rob_id to ID
    output wire [31:0]      ROB_ava_id,

    // commit to reg
    output reg              ROB_cmt_rf_flag,
    output reg [4:0]        ROB_cmt_rf_rd,
    output reg [31:0]       ROB_cmt_rf_rob_id,
    output reg [31:0]       ROB_cmt_rf_val,

    // commit store
    output reg              ROB_cmt_st_flag,
    output reg [31:0]       ROB_cmt_st_rob_id,

    // request reg value
    input wire  [`ROBWD-1:0]RF_id1_cut,
    input wire  [`ROBWD-1:0]RF_id2_cut,
    output wire             RF_id1_ready,
    output wire             RF_id2_ready, 
    output wire [31:0]      RF_id1_val,
    output wire [31:0]      RF_id2_val,

    // for input : lsb need know the head of ROB
    output wire [31:0]      ROB_head
);

reg [`ROBSZ-1:0]    busy;
reg [`ROBSZ-1:0]    rob_rdy;
reg [5:0]           inst_code [`ROBSZ-1:0];
reg [2:0]           inst_type [`ROBSZ-1:0];
reg [31:0]          val [`ROBSZ-1:0];
reg [4:0]           rd [`ROBSZ-1:0];
reg [31:0]          prd_pc [`ROBSZ-1:0];
reg [31:0]          rel_pc [`ROBSZ-1:0];

`ifdef LOG
    // log
    reg [31:0]          log_inst_pc[`ROBSZ-1:0];
    reg [31:0]          log_ls_addr[`ROBSZ-1:0];
    reg [31:0]          log_st_val[`ROBSZ-1:0];
    reg [31:0]          log_ld_addr[`ROBSZ-1:0];
    integer             log_inst_cnt = 1;
`endif

assign RF_id1_ready = rob_rdy[RF_id1_cut];
assign RF_id2_ready = rob_rdy[RF_id2_cut];
assign RF_id1_val   = val[RF_id1_cut];
assign RF_id2_val   = val[RF_id2_cut];

integer i, head = 1, tail = 0;
wire [`ROBWD-1:0] hd = head[`ROBWD-1:0];
wire [`ROBWD-1:0] tl = tail[`ROBWD-1:0];
wire [`ROBWD-1:0] nt = tl + 1;

wire rob_rdy_flag = head <= tail && rob_rdy[hd];

assign ROB_nex_ava = rob_rdy_flag || (tail - head + 1 <= `ROBSZ - 2) || (tail - head == `ROBSZ -2 && !ID_inst_flag);

assign ROB_ava_id = tail + 1;
assign ROB_head = head;

`ifdef LOG
    integer log_file;
        initial begin
            log_file=$fopen("debug.out","w");
        end
`endif 

always @(posedge clk) begin
    if(rst) begin
        busy <= 0;
        rob_rdy <= 0;
        head <= 1;
        tail <= 0;
    end
    else if(!rdy) begin
    end
    else if(jump_wrong_stall) begin
        jump_wrong_flag <= `False;
        if(lsb_clear_done) begin
            busy <= 0;
            head <= head + 1;
            tail <= head;
            jump_wrong_stall <= `False;
        end
    end
    else begin
        // update value and ready
        for(i = 0; i < `ROBSZ; i = i + 1) begin
            if(busy[i]) begin
                if(ex_cdb_flag && ex_cdb_rob_id_cut == i[`ROBWD-1:0]) begin
                    val[i] <= ex_cdb_val;
                    rel_pc[i] <= ex_cdb_rel_pc;
                    rob_rdy[i] <= `True;
                end
                if(ld_cdb_flag && ld_cdb_rob_id_cut == i[`ROBWD-1:0]) begin
                    val[i] <= ld_cdb_val;
                    rob_rdy[i] <= `True;
                    // log_ld_addr[i] <= log_ld_addr_in;
                end
                if(st_rdy_flag && st_rdy_rob_id_cut == i[`ROBWD-1:0]) begin
                    rob_rdy[i] <= `True;
                    `ifdef LOG
                        log_ls_addr[i] <= log_st_rdy_addr;
                        log_st_val[i] <= log_st_rdy_val;
                    `endif
                end
            end
        end

        // receive inst
        if(ID_inst_flag) begin
            busy[nt] <= `True;
            rob_rdy[nt] <= `False;
            inst_type[nt] <= ID_inst_type;
            rd[nt] <= ID_inst_rd;
            prd_pc[nt] <= ID_inst_prd_pc;
            `ifdef LOG
                log_inst_pc[nt] <= log_inst_pc_in;
            `endif
            tail <= tail + 1;
        end

        // commit
        if(rob_rdy_flag) begin
            `ifdef LOG
                $fdisplay(log_file,"%0d",log_inst_cnt);
                log_inst_cnt <= log_inst_cnt + 1;
            `endif 
            if(inst_type[hd] == `ALU || inst_type[hd] >= `LD) begin
                `ifdef LOG
                    $fdisplay(log_file,"%h",log_inst_pc[hd]);
                `endif 
                if(inst_type[hd] == `ST) begin
                    `ifdef LOG
                        $fdisplay(log_file,"%h %h",log_st_val[hd],log_ls_addr[hd]);
                    `endif 
                    ROB_cmt_rf_flag <= `False;
                    ROB_cmt_st_flag <= `True;
                    ROB_cmt_st_rob_id <= head;
                end
                else begin
                    /*if(inst_type[hd] == `LD)
                        $display("%h %h",val[hd],log_ld_addr[hd]);
                    else*/
                    `ifdef LOG
                        $fdisplay(log_file,"%h",val[hd]);
                    `endif 
                    ROB_cmt_st_flag <= `False;
                    ROB_cmt_rf_flag <= `True;
                    ROB_cmt_rf_rd <= rd[hd];
                    ROB_cmt_rf_val <= val[hd];
                    ROB_cmt_rf_rob_id <= head;
                end
                busy[hd] <= `False;
                rob_rdy[hd] <= `False;
                head <= head + 1;
            end
            else begin // jump 
                `ifdef LOG
                    $fdisplay(log_file,"%h",log_inst_pc[hd]);
                    $fdisplay(log_file,"%h",rel_pc[hd]);
                `endif 
                if(inst_type[hd] == `JMP) begin // JAL,JALR
                    ROB_cmt_st_flag <= `False;
                    ROB_cmt_rf_flag <= `True;
                    ROB_cmt_rf_rd <= rd[hd];
                    ROB_cmt_rf_val <= val[hd];
                    ROB_cmt_rf_rob_id <= head;
                end
                else begin
                    ROB_cmt_rf_flag <= `False;
                    ROB_cmt_st_flag <= `False;
                end

                if(prd_pc[hd] == rel_pc[hd])begin
                    busy[hd] <= `False;
                    rob_rdy[hd] <= `False;
                    head <= head + 1;
                end
                else begin
                    jump_wrong_flag <= `True;
                    jump_wrong_stall <= `True;
                    jump_rel_pc <= rel_pc[hd];
                end
            end
        end
        else begin
            ROB_cmt_rf_flag <= `False;
            ROB_cmt_st_flag <= `False;
        end
    end
end

endmodule