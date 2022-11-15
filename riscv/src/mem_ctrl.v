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
    output reg                  mem_wr,

    // ins_fetcher
    input wire                  IF_MC_ask,
    input wire  [`Addr_SIZE]    IF_MC_Addr,
    output reg                  MC_IF_ok,
    output reg                  MC_IF_arrive,
    output reg  [`Inst_SIZE]    MC_IF_Inst

    // LSB ...
    );

    reg [`Mem_LEN] sending = 2'b00;
    reg [`Addr_SIZE] sending_addr = 32'b0;

    reg [`Mem_LEN] receiving = 2'b00;
    reg [`Word_SIZE] receiving_word = 32'b0;

    always @(posedge clk_in) begin
        if (rst_in) begin // reset
        end
        else if (!rdy_in) begin 
        end
        else begin

            if (sending != 2'b00) begin // sending addr
                mem_a <= sending_addr + sending * 4;
                mem_wr <= `Mem_R;
                sending <= sending + 1;

                if (sending == 2'b01) begin
                    receiving <= 2'b01; // receiving the first byte
                    receiving_word <= mem_dout;
                end
            end

            if(receiving) begin // receiving data byte by byte
                receiving <= receiving + 1;
                receiving_word <= (receiving_word << 8) + mem_dout;

                if(receiving == 2'b11) begin
                    MC_IF_Inst <= (receiving_word << 8) + mem_dout;
                end
            end

            if (IF_MC_ask) begin // asking for ins
                if (sending == 2'b00) begin
                    MC_IF_ok <= `True;

                    mem_a <= sending_addr; 
                    mem_wr <= `Mem_R;
                    sending <= sending + 1;
                end 
                else begin
                    MC_IF_ok <= `False;
                end
            end

        end
    end

endmodule