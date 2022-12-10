module inst_fetcher(
    input wire  clk,
    input wire  rst,
    input wire  rdy,

    // MC
    input   wire            inst_MC_flag,
    input   wire    [`ISZ]  inst_MC,
    output  reg             inst_MC_req,
    output  reg     [`ADSZ] inst_MC_addr,

    // dispatcher
    input   wire            ID_stall,   // indicates if this instruction can be issued
    output  wire            inst_ID_flag,
    output  wire    [`ISZ]  inst_ID     // instruction to be issued, the dispatcher should know its type
);

reg [31:0] pc = 0;

// Icache : ID 7:0
reg [`ISZ]      cache   [`ICSZ];
reg [`TGSZ]     tags    [`ICSZ];
reg [`ICSZ]     valid;
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
            if(pc % 16 == 0 && pc != 0)
                pc <= pc - 12;
            else 
                pc <= pc + 4;
        end
    end
end

endmodule