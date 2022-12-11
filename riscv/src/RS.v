module rs_station(
    // inst info
    input wire          inst_ID_flag, 
    input wire  [4:0]   rd, rs1, rs2,
    input wire  [31:0]  imm,
    input wire  [5:0]   inst_code,
    input wire  [2:0]   inst_type,
    input wire  [31:0]  now_pc

);

reg                 busy    [`RSSZ-1:0]; 
reg [5:0]           op_code [`RSSZ-1:0];
reg [31:0]          inst_pc [`RSSZ-1:0];
reg [4:0]           Q1      [`RSSZ-1:0], Q2[`RSSZ-1:0];
reg [31:0]          V1      [`RSSZ-1:0], V2[`RSSZ-1:0];
reg [31:0]          A       [`RSSZ-1:0];
reg [`ROBIDBW-1:0]  rob_id  [`RSSZ-1:0];

integer i;

always @(*) begin
    // if(inst_ID_flag && inst_type <= `BRC) begin
    //     for(i = 0; i < `RSSZ; i = i + 1) begin
    //         if(!busy[i]) begin
    //             busy[i]     = `True;
    //             op_code[i]  = inst_code;
    //             inst_pc[i]  = now_pc;
    //             //TODO
    //             break;
    //         end
    //     end
    // end
end

endmodule