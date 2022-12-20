`include "Def.v"

module mem_ctrl(
    // cpu
    input wire                  clk,
    input wire                  rst,
    input wire			        rdy,
    input wire                  io_buffer_full,

    // jump wrong
    input wire                  jump_wrong_flag,

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
    input wire [1:0]            LSB_width, // 0: 1 byte, 1: 2 byte, 3: 4 byte
    input wire                  LSB_type, // 0: load, 1: store
    input wire [31:0]           LSB_addr,
    input wire [31:0]           LSB_val,
    input wire [31:0]           LSB_rob_id,

    // lsb done
    output reg                  lsb_done_flag,

    // ld cdb 
    output reg                  ld_cdb_flag,
    output reg [31:0]           ld_cdb_val,
    output reg [31:0]           ld_cdb_rob_id
    );

    // combinational logic
    wire just_mem_done = lsb_done_flag || inst_IF_flag;
    assign just_mem_done = lsb_done_flag || inst_IF_flag;
    `ifdef LOG
        reg[1:0] log_status;
    `endif

    // sequential logic
    reg [23:0]  mem_res = 24'b0;
    reg [1:0]   step_IF = 2'b00;
    reg [1:0]   step_LS = 2'b00;

    // sync with memory interface without delay
    always @(*) begin
        // register initial
        mem_dout = 0;
        mem_a = 0;
        mem_wr = 0;
        inst_IF = 0;
        ld_cdb_val = 0;

        if(LSB_req && !just_mem_done && (!inst_IF_req || step_IF == 0)) begin
            mem_a = LSB_addr + {{30{1'b0}},step_LS};
            if(LSB_type == 1'b0) begin // load
                `ifdef LOG
                    log_status = 2'b1;
                `endif
                mem_wr = 1'b0;
            end
            else begin // store
                `ifdef LOG
                    log_status = 2'd2;
                `endif
                if(io_buffer_full && LSB_addr >= `hci_addr) begin
                    mem_wr = 1'b0;
                    mem_a = 0;
                end
                else begin
                    mem_wr = 1'b1;
                    case (step_LS)
                        2'b00 : mem_dout = LSB_val[7:0];
                        2'b01 : mem_dout = LSB_val[15:8];
                        2'b10 : mem_dout = LSB_val[23:16];
                        2'b11 : mem_dout = LSB_val[31:24];
                    endcase
                end
            end
        end
        else if(inst_IF_req && !just_mem_done) begin // req during 0,1,2,3
            `ifdef LOG
                log_status = 2'd3;
            `endif
            mem_wr = 1'b0;
            mem_a = inst_IF_addr + {{30{1'b0}},step_IF};
        end
        else begin
            `ifdef LOG
                log_status = 2'd0;
            `endif
        end

        if(lsb_done_flag && LSB_type == 1'b0) begin // last is load
            case(LSB_width)
                2'b00 : ld_cdb_val = {{24{1'b0}},mem_din};
                2'b01 : ld_cdb_val = {{16{1'b0}},mem_din,mem_res[7:0]};
                2'b11 : ld_cdb_val = {mem_din,mem_res[23:0]};
                default:;
            endcase
        end

        if(inst_IF_flag) begin // next 0, receive 3's result
            inst_IF = {mem_din,mem_res[23:0]};
        end
    end

    always @(posedge clk) begin
        // flag initial
        inst_IF_flag <= `False;
        lsb_done_flag <= `False;
        ld_cdb_flag <= `False;

        if (rst || jump_wrong_flag) begin // reset
            mem_res <= 24'b0;
            step_IF <= 2'b00;
            step_LS <= 2'b00;
        end
        else if (!rdy) begin // pause
        end
        else begin
            if(LSB_req && !just_mem_done && (!inst_IF_req || step_IF == 0)) begin
                if(io_buffer_full && LSB_addr >= `hci_addr && LSB_type == 1'b1) begin
                end
                else begin
                    step_LS <= step_LS + 2'b01;
                    if(LSB_width == step_LS)begin
                        step_LS <= 2'b00;
                        lsb_done_flag <= `True;
                        if(LSB_type == 1'b0)begin
                            ld_cdb_flag <= `True;
                            ld_cdb_rob_id <= LSB_rob_id;
                        end
                    end
                    if(LSB_type == 1'b0)begin
                        case(step_LS)
                            2'b01 : mem_res[7:0] <= mem_din;
                            2'b10 : mem_res[15:8] <= mem_din;
                            2'b11 : mem_res[23:16] <= mem_din;
                            default :;
                        endcase
                    end
                end
            end
            else if(inst_IF_req && !just_mem_done) begin
                step_IF <= step_IF + 2'b01;
                if(step_IF == 2'b11)
                    inst_IF_flag <= `True;
                case(step_IF)
                    2'b01 : mem_res[7:0] <= mem_din;
                    2'b10 : mem_res[15:8] <= mem_din;
                    2'b11 : mem_res[23:16] <= mem_din;
                    default :;
                endcase
            end
        end
    end

endmodule