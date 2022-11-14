// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(input wire           clk_in,
           input wire           rst_in,
           input wire			rdy_in,
           input wire   [7:0]   mem_din,
           output wire  [7:0]   mem_dout,
           output wire  [31:0]  mem_a,
           output wire          mem_wr,
           input wire           io_buffer_full,// 1 if uart buffer is full
           output wire  [31:0]  dbgreg_dout);
    
    // implementation goes h
    // Specifications:
    // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
    // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
    // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
    // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16] == 2'b11)
    // - 0x30000 read: read a byte from input
    // - 0x30000 write: write a byte to output (write 0x00 is ignored)
    // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
    // - 0x30004 write: indicates program stop (will output '\0' through uart tx)
    
    mem_ctrl mem_ctr0(.clk_in(clk_in),
                      .rst_in(rst_in),
                      .rdy_in(rdy_in),
                      .mem_din(mem_din),
                      .mem_dout(mem_dout),
                      .mem_a(mem_a),
                      .mem_wr(mem_wr),
                      .io_buffer_full(io_buffer_full));

    always @(posedge clk_in) begin
        if (rst_in) begin // reset 
            
        end
        else if (!rdy_in) begin // pause the cpu
            
        end
        else begin // just do it
            
        end
    end
    
endmodule
