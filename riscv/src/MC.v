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
    output reg [`ISZ]           inst_IF

    // LSB ...
    );

    reg         last_IF = `False; 
    reg [1:0]   step_IF = 2'b00;

    reg [31:0]  mem_res = 32'b0;

    always @(*) begin
        if(inst_IF_req) begin // req during 0,1,2,3
            mem_a = inst_IF_addr + step_IF;
            case (step_IF)
                2'b01 : mem_res[7:0] = mem_din;
                2'b10 : mem_res[15:8] = mem_din;
                2'b11 : mem_res[23:16] = mem_din;
            endcase
        end
        if(last_IF) begin // next 0, receive 3's result
            mem_res[31:24] = mem_din;
            inst_IF_flag = `True;
            inst_IF = mem_res;
            last_IF = `False;
        end
    end

    always @(posedge clk) begin
        if (rst) begin // reset
        end
        else if (!rdy) begin // pause
        end
        else begin
            inst_IF_flag <= `False;
            if(inst_IF_req) begin
                step_IF <= step_IF + 2'b01;
                if(step_IF == 2'b11)
                    last_IF <= `True;
            end
        end
    end

endmodule