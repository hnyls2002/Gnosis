`include "Def.v"

module mem_ctrl(
    // cpu
    input wire                  clk,
    input wire                  rst,
    input wire			        rdy,
    input wire                  io_buffer_full,

    // ram
    input wire  [7:0]           mem_din,
    output reg  [7:0]           mem_dout,
    output reg  [31:0]          mem_a,
    output reg                  mem_wr, // 0 : load , 1 : store

    // IF
    input wire                  inst_IF_req,
    input wire [31:0]           inst_IF_addr,
    output reg                  inst_IF_flag, 
    output reg [31:0]           inst_IF,

    // LSB
    input wire                  LSB_req,
    input wire [1:0]            LSB_width, // 0: 1 byte, 1: 2 byte, 2: 4 byte
    input wire                  LSB_type, // 0: load, 1: store
    input wire [31:0]           LSB_addr,
    input wire [31:0]           LSB_val,
    input wire [`ROBBW-1:0]     LSB_rob_id,

    // lsb done
    output reg                  lsb_done_flag,

    // ld cdb 
    output reg                  ld_cdb_flag,
    output reg [31:0]           ld_cdb_val,
    output reg [`ROBBW-1:0]     ld_cdb_rob_id
    );

    reg [`ROBBW-1:0]    last_rob_id = 0;
    reg [1:0]   step_IF = 2'b00;
    reg [1:0]   step_LS = 2'b00;

    reg [31:0]  mem_res = 32'b0;

    reg[1:0] debug_status;

    // sync with memory interface without delay
    always @(*) begin
        if(LSB_req && !lsb_done_flag && (!inst_IF_req || step_IF == 0)) begin
            mem_a = LSB_addr + {{30{1'b0}},step_LS};
            if(LSB_type == 1'b0) begin // load
                debug_status = 2'b1;
                mem_wr = 1'b0;
                case (step_LS)
                    2'b01 : mem_res[7:0] = mem_din;
                    2'b10 : mem_res[15:8] = mem_din;
                    2'b11 : mem_res[23:16] = mem_din;
                    default :;
                endcase
            end
            else begin // store
                debug_status = 2'd2;
                mem_wr = 1'b1;
                case (step_LS)
                    2'b00 : mem_dout = LSB_val[7:0];
                    2'b01 : mem_dout = LSB_val[15:8];
                    2'b10 : mem_dout = LSB_val[23:16];
                    2'b11 : mem_dout = LSB_val[31:24];
                endcase
            end
        end
        else if(inst_IF_req && !inst_IF_flag) begin // req during 0,1,2,3
            debug_status = 2'd3;
            mem_wr = 1'b0;
            mem_a = inst_IF_addr + {{30{1'b0}},step_IF};
            case (step_IF)
                2'b01 : mem_res[7:0] = mem_din;
                2'b10 : mem_res[15:8] = mem_din;
                2'b11 : mem_res[23:16] = mem_din;
                default :;
            endcase
        end
        else begin
            debug_status = 2'd0;
            mem_wr = 1'b0;
        end

        if(lsb_done_flag && LSB_type == 1'b0) begin // last is load
            case(LSB_width)
                2'b00 : begin
                    mem_res[7:0] = mem_din;
                    mem_res[31:8] = 0;
                end
                2'b01 : begin
                    mem_res[15:8] = mem_din;
                    mem_res[31:16] = 0;
                end
                2'b10 : mem_res[31:24] = mem_din;
                default:;
            endcase
            ld_cdb_flag = `True;
            ld_cdb_val = mem_res;
            ld_cdb_rob_id = last_rob_id;
        end

        if(inst_IF_flag) begin // next 0, receive 3's result
            mem_res[31:24] = mem_din;
            inst_IF = mem_res;
        end
    end

    always @(posedge clk) begin
        if (rst) begin // reset
        end
        else if (!rdy) begin // pause
        end
        else begin
            inst_IF_flag <= `False;
            lsb_done_flag <= `False;

            if(LSB_req && !lsb_done_flag && (!inst_IF_req || step_IF == 0)) begin
                step_LS <= step_LS + 2'b01;
                if((LSB_width == 2'b0 && step_LS == 2'b0)
                || (LSB_width == 2'b1 && step_LS == 2'b1)
                || (LSB_width == 2'b10 && step_LS == 2'b11))begin 
                    step_LS <= 2'b00;
                    lsb_done_flag <= `True;
                    last_rob_id <= LSB_rob_id;
                end
            end
            else if(inst_IF_req && !inst_IF_flag) begin
                step_IF <= step_IF + 2'b01;
                if(step_IF == 2'b11)
                    inst_IF_flag <= `True;
            end
        end
    end

endmodule