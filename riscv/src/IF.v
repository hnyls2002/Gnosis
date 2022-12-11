module inst_fetcher(
    input wire  clk,
    input wire  rst,
    input wire  rdy,

    // MC
    input   wire            inst_MC_flag,
    input   wire    [31:0]  inst_MC,
    output  reg             inst_MC_req,
    output  reg     [31:0]  inst_MC_addr,

    // dispatcher
    input   wire            ID_stall,   // indicates if this instruction can be issued
    output  wire            inst_ID_flag,
    output  wire    [31:0]  inst_ID,    // instruction to be issued, the dispatcher should know its type

    // broadcast pc 
    output  wire    [31:0]  now_pc 
);

reg [31:0] pc = 0;

// Icache : ID 7:0
reg [31:0]          cache   [`ICSZ-1:0];
reg [`TGBW-1:0]     tags    [`ICSZ-1:0];
reg [`ICSZ-1:0]     valid;
wire            hit;
assign hit  = valid[pc[`ID]] && (tags[pc[`ID]] == pc[`TG]);
assign inst_ID_flag = hit && !ID_stall;
assign inst_ID = cache[pc[`ID]];

always @(*) begin
    // add to cache
    if(inst_MC_flag) begin
        valid[pc[`ID]] = `True;
        tags[pc[`ID]] = pc[`TG];
        cache[pc[`ID]] = inst_MC;
    end

    if(!hit) begin
        inst_MC_req = `True;
        inst_MC_addr = pc;
    end
    else begin
        inst_MC_req = `False;
        inst_MC_addr = 32'h0;
    end
end

always @(posedge clk) begin
    if(rst) begin
        valid <= 0;
    end
    else if(!rdy) begin
    end
    else begin
        if(inst_ID_flag) begin
            pc <= pc + 4;
        end
    end
end

endmodule