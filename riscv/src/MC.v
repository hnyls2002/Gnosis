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
    output reg                  mem_wr,

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

    // ld cdb 
    output reg                  ld_cdb_flag,
    output reg [`ROBBW-1:0]     ld_cdb_rob_id,
    output reg [31:0]           ld_cdb_val,

    // for commit store
    output reg                  st_done_flag,
    output reg [`ROBBW-1:0]     st_done_rob_id
    );

    reg         last_IF = `False; 
    reg         last_ld = `False;
    reg [1:0]   step_IF = 2'b00;
    reg [1:0]   step_LS = 2'b00;

    reg [31:0]  mem_res = 32'b0;

    // sync with memory interface without delay
    always @(*) begin
        if(LSB_req && (!inst_IF_req || step_IF == 0)) begin
            mem_a = LSB_addr + {{30{1'b0}},step_LS};
            if(LSB_type == 1'b0) begin // load
                case (step_LS)
                    2'b01 : mem_res[7:0] = mem_din;
                    2'b10 : mem_res[15:8] = mem_din;
                    2'b11 : mem_res[23:16] = mem_din;
                    default :;
                endcase
            end
            else begin // store
                case (step_LS)
                    2'b00 : mem_dout = LSB_val[7:0];
                    2'b01 : mem_dout = LSB_val[15:8];
                    2'b10 : mem_dout = LSB_val[23:16];
                    2'b11 : mem_dout = LSB_val[31:24];
                endcase
            end
        end
        else if(inst_IF_req) begin // req during 0,1,2,3
            mem_a = inst_IF_addr + {{30{1'b0}},step_IF};
            case (step_IF)
                2'b01 : mem_res[7:0] = mem_din;
                2'b10 : mem_res[15:8] = mem_din;
                2'b11 : mem_res[23:16] = mem_din;
                default :;
            endcase
        end

        if(last_ld) begin
            mem_res[31:24] = mem_din;
            ld_cdb_val = mem_res;
        end

        if(last_IF) begin // next 0, receive 3's result
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
            last_IF <= `False;
            last_ld <= `False;
            inst_IF_flag <= `False;
            ld_cdb_flag <= `False;
            st_done_flag <= `False;

            if(LSB_req && (!inst_IF_req || step_IF == 0)) begin
                step_LS <= step_LS + 2'b01;
                if((LSB_width == 2'b0 && step_LS == 2'b0)
                || (LSB_width == 2'b1 && step_LS == 2'b1)
                || (LSB_width == 2'b10 && step_LS == 2'b11))begin 
                    step_LS <= 2'b00;
                    if(LSB_type == 1'b0) begin
                        last_ld <= `True;
                        ld_cdb_flag <= `True;
                    end
                    else st_done_flag <= `True;
                end
            end
            else if(inst_IF_req) begin
                step_IF <= step_IF + 2'b01;
                if(step_IF == 2'b11) begin
                    last_IF <= `True;
                    inst_IF_flag <= `True;
                end
            end
        end
    end

endmodule