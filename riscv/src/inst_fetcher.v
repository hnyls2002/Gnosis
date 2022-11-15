module inst_fetcher(
    // cpu
    input wire                  clk_in,
    input wire                  rst_in,
    input wire			        rdy_in,
    input wire                  io_buffer_full,

    // fetch ins
    output reg                  IF_MC_ask,
    output reg [`Addr_SIZE]     IF_MC_Addr,
    input wire                  MC_IF_ok,
    input wire                  MC_IF_arrive,
    input wire [`Inst_SIZE]     MC_IF_Inst
    );

    reg [`Addr_SIZE] PC = `Start_Addr;

    // IF -> IC
    // IC always combinational logic : PC input
    wire IC_ok;
    wire [`Inst_SIZE] IC_Inst;

    inst_cache inst_cache0(
        .IF_Addr(PC),
        .IF_ok(IC_ok),
        .IF_Inst(IC_Inst)
    );

    reg asked_flag = `False;

    always @(posedge clk_in) begin
        if (rst_in) begin // reset
        end
        else if (!rdy_in) begin // not ready : pause the cpu
        end
        else begin
            if (~IF_MC_ask || (asked_flag && ~MC_IF_ok)) begin
                IF_MC_ask <= `True;
                IF_MC_Addr <= PC;
                asked_flag <= `True;
            end
            else begin
                asked_flag <= `False;
            end

            if(MC_IF_arrive) begin
                PC <= PC + 4;
            end
        end
    end

endmodule