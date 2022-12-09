module mem_ctrl(
    // cpu
    input wire                  clk_in,
    input wire                  rst_in,
    input wire			        rdy_in,
    input wire                  io_buffer_full,

    // ram
    input wire  [7:0]           mem_din,
    output reg  [7:0]           mem_dout,
    output reg  [31:0]          mem_a,
    output reg                  mem_wr
    // ins_fetcher ...

    // LSB ...
    );

    always @(posedge clk_in) begin
        if (rst_in) begin // reset
        end
        else if (!rdy_in) begin 
        end
        else begin
        end
    end

endmodule