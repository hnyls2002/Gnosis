module inst_fetcher(
    input wire  clk,
    input wire  rst,
    input wire  rdy,

    // MC
    input   wire            inst_MC_flag,
    input   wire    [31:0]  inst_MC,
    output  reg             inst_MC_req,
    output  reg     [31:0]  inst_MC_addr,

    // stalls
    input   wire            RS_nex_full,
    input   wire            LSB_nex_full, 
    input   wire            ROB_nex_full, 

    // dispatcher
    output  reg             inst_ID_flag,
    output  reg     [31:0]  inst_ID,
    output  reg     [31:0]  inst_pc
);

reg [31:0] pc = 0;

// Icache : ID 7:0
reg [31:0]          cache   [`ICSZ-1:0];
reg [`TGBW-1:0]     tags    [`ICSZ-1:0];
reg [`ICSZ-1:0]     valid;
wire        hit = valid[pc[`ID]] && (tags[pc[`ID]] == pc[`TG]);
wire [31:0] inst_hit = cache[pc[`ID]];

// add to cache
always @(*) begin
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


// determine this instruction's type
reg [6:0]   opcode;
reg [2:0]   inst_type;
always @(*) begin
    if(inst_MC_flag) begin
        opcode = inst_MC[6:0];
        case (opcode)
            `R_TYPE     : inst_type = `ALU;
            `I_TYPE0    : inst_type = `JMP; 
            `I_TYPE1    : inst_type = `LD;
            `I_TYPE2    : inst_type = `ALU;
            `S_TYPE     : inst_type = `ST;
            `B_TYPE     : inst_type = `BRC;
            `U_TYPE0    : inst_type = `ALU;
            `U_TYPE1    : inst_type = `ALU;
            `J_TYPE     : inst_type = `JMP;
        endcase
    end
end

always @(posedge clk) begin
    if(rst) begin
        valid <= 0;
    end
    else if(!rdy) begin
    end
    else begin
        inst_ID_flag <= `False;
        if(hit && !ROB_nex_full) begin
            if((inst_type <= `BRC && !RS_nex_full) || (inst_type >= `LD && !LSB_nex_full)) begin
                inst_ID_flag <= `True;
                inst_ID <= inst_hit;
                inst_pc <= pc;
                pc <= pc + 4;
            end
        end
    end
end

endmodule