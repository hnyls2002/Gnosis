// bool
`define True 1'b1
`define False 1'b0

// register
`define REGSZ 32
`define REGBW 5

// cache
`define ICSZ 256
`define TGBW 22
`define ID 9:2
`define TG 31:10

// RS
`define RSSZ 32

// LSB
`define LSBSZ 32

// ROB
`define ROBSZ 32
`define ROBBW 5

// decoder
`define U_TYPE0 7'b0110111
`define U_TYPE1 7'b0010111
`define J_TYPE  7'b1101111
`define I_TYPE0 7'b1100111 
`define I_TYPE1 7'b0000011
`define I_TYPE2 7'b0010011
`define B_TYPE  7'b1100011
`define S_TYPE  7'b0100011
`define R_TYPE  7'b0110011

// U-type
`define LUI     6'd0
`define AUIPC   6'd1
// J-type
`define JAL     6'd2
// I-type
`define JALR    6'd3
// B-type
`define BEQ     6'd4
`define BNE     6'd5
`define BLT     6'd6
`define BGE     6'd7 
`define BLTU    6'd8
`define BGEU    6'd9
// I-type
`define LB      6'd10 
`define LH      6'd11
`define LW      6'd12
`define LBU     6'd13
`define LHU     6'd14
// S-type
`define SB      6'd15
`define SH      6'd16
`define SW      6'd17
// I-type
`define ADDI    6'd18
`define SLTI    6'd19
`define SLTIU   6'd20
`define XORI    6'd21
`define ORI     6'd22
`define ANDI    6'd23
// I-type
`define SLLI    6'd24
`define SRLI    6'd25
`define SRAI    6'd26
// R-type
`define ADD     6'd27
`define SUB     6'd28
`define SLL     6'd29
`define SLT     6'd30
`define SLTU    6'd31
`define XOR     6'd32
`define SRL     6'd33
`define SRA     6'd34
`define OR      6'd35
`define AND     6'd36 

// inst-type
`define ALU     3'd0
`define JMP     3'd1
`define BRC     3'd2
`define LD      3'd3
`define ST      3'd4