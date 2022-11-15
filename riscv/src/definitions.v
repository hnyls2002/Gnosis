`define IO_Addr 32'h30000
`define End_Addr 32'h30004
`define Start_Addr 32'h0
`define Mem_W 1'b1
`define Mem_R 1'b0
`define Inst_SIZE 31:0
`define Mem_LEN 1:0
`define Addr_SIZE 31:0
`define Data_SIZE 7:0
`define Word_SIZE 31:0

`define True 1'b1
`define False 1'b0

// IC dedinitions
`define IC_SIZE 255:0
`define IC_Loop 255
`define Tag_SIZE 23:0
`define Index_SIZE 7:0
`define IC_Index 7:0
`define IC_Tag 31:8