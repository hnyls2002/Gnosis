module mem_ctrl(
    // cpu
    input wire          clk_in,
    input wire          rst_in,
    input wire			rdy_in,

    // memory control
    input wire  [7:0]   mem_din,
    output reg  [7:0]   mem_dout,
    output reg  [31:0]  mem_a,
    output reg          mem_wr, // 1 for write

    // FPGA
    input wire          io_buffer_full);

    integer cnt = 0;

    always @(posedge clk_in) begin
        if (~rst_in) begin
            if (cnt == 0) begin
                mem_wr <= `MEM_R;
                mem_a <= 0;
                cnt <= cnt + 1;
            end
            else begin
                mem_wr <= `MEM_W;
                mem_a <= `END_ADDR;
                mem_dout <= 122;
            end
        end
    end

endmodule