module inst_cache(
    // cpu
    input wire clr,
    input wire rdy,

    // try fetch inst
    input wire [`Addr_SIZE] IF_Addr,
    output reg IF_ok,
    output reg [`Inst_SIZE] IF_Inst,

    // put inst
    input wire IF_ask_put,
    input wire [`Inst_SIZE] IF_Inst_put,
    input wire [`Addr_SIZE] IF_Addr_put
);

// cobimnation logic !

reg [`Tag_SIZE] tag [`IC_SIZE];
reg [`Inst_SIZE] inst [`IC_SIZE];
reg valid [`IC_SIZE];

assign id = IF_Addr[`IC_Index];
assign tg = IF_Addr[`IC_Tag];

assign id_put = IF_Addr_put[`IC_Index];
assign tg_put = IF_Addr_put[`IC_Tag];

integer i;

always @(*) begin

    if (clr) begin
        for (i = 0; i <= `IC_Loop; i = i + 1) begin
            valid[i] = `False;
        end
    end
    else if (!rdy) begin
        // do nothing
    end
    else begin
        // put the new inst
        if (IF_ask_put) begin
            valid[id_put] = `True;
            tag[id_put] = tg_put;
            inst[id_put] = IF_Inst_put;
        end

        // fetch the inst
        else if (valid[id] && (tag[id] == tg)) begin
            IF_ok = `True;
            IF_Inst = inst[id];
        end
        else begin
            IF_ok = `False;
        end
    end

end

endmodule