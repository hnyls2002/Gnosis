`include "Def.v"

module inst_fetcher(
    input wire  clk,
    input wire  rst,
    input wire  rdy,

    // jump wrong
    input   wire            jump_wrong_stall,
    input   wire    [31:0]  jump_rel_pc,

    // MC
    input   wire            MC_flag,
    input   wire    [31:0]  MC_inst,
    output  reg             MC_req,
    output  reg     [31:0]  MC_addr,

    // stalls
    input   wire            RS_nex_ava,
    input   wire            LSB_nex_ava, 
    input   wire            ROB_nex_ava, 

    // dispatcher
    output  reg             ID_flag,
    output  reg     [31:0]  ID_inst,
    output  reg     [31:0]  ID_inst_pc,
    output  reg     [31:0]  ID_inst_prd_pc
);

reg [31:0] pc = 0;

// Icache : ID 7:0
reg [31:0]          cache   [`ICSZ-1:0];
reg [`TGBW-1:0]     tags    [`ICSZ-1:0];
reg [`ICSZ-1:0]     valid;

wire hit = valid[pc[`ID]] && (tags[pc[`ID]] == pc[`TG]);
wire [31:0] inst_now = hit ? cache[pc[`ID]] : MC_inst;

// add to cache
always @(*) begin
    if(jump_wrong_stall || hit) begin
        MC_req = `False;
        MC_addr = 32'h0;
    end
    else begin
        MC_req = `True;
        MC_addr = pc;
    end
end


// determine this instruction's type
wire [6:0] opcode = inst_now[6:0];
wire [31:0] imm = {{11{inst_now[31]}},inst_now[31],inst_now[19:12],inst_now[20],inst_now[30:21],1'b0};
reg [2:0]   inst_type;

always @(*) begin
    inst_type = 0;
    if(hit || MC_flag) begin
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
            default     :;
        endcase
    end
end

always @(posedge clk) begin
    // flags init
    ID_flag <= `False;

    if(rst) begin
        valid <= 0;
        pc <= 0;
    end
    else if(!rdy) begin
    end
    else if (jump_wrong_stall) begin
        pc <= jump_rel_pc;
    end
    else begin
        if(MC_flag) begin
            valid[pc[`ID]] <= `True;
            tags[pc[`ID]] <= pc[`TG];
            cache[pc[`ID]] <= MC_inst;
        end

        if((hit || MC_flag) && ROB_nex_ava) begin
            if((inst_type <= `BRC && RS_nex_ava) 
            || (inst_type >= `LD && LSB_nex_ava)) begin
                ID_flag <= `True;
                ID_inst <= inst_now;
                if(opcode == `J_TYPE) begin // JAL
                    ID_inst_pc <= pc;
                    ID_inst_prd_pc <= pc + imm;
                    pc <= pc + imm;
                end
                else begin
                    ID_inst_pc <= pc;
                    ID_inst_prd_pc <= pc + 4;
                    pc <= pc + 4;
                end
            end
        end
    end
end

endmodule