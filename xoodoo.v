`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2020 02:20:14 PM
// Design Name: 
// Module Name: xoodoo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module xoodoo_nc#(
parameter integer x=1, //only 32 bits. No plane, only lane
parameter integer y=3, // number of (p)lanes.
parameter integer z=32, // number of bits in each lane
parameter integer HASH_IN_SIZE = 96, // number of bits in each lane
parameter integer CONCAT_FACTOR = 1, // how many times output to be concatanated
parameter integer HASH_SIZE = CONCAT_FACTOR*96,
parameter integer rounds = 3,
parameter integer rc_round = 12-rounds, // inorder to select the round costant for each round
parameter integer RC_0=32'h00000058,
parameter integer RC_1=32'h00000038,
parameter integer RC_2=32'h000003C0,
parameter integer RC_3=32'h000000D0,
parameter integer RC_4=32'h00000120,
parameter integer RC_5=32'h00000014,
parameter integer RC_6=32'h00000060,
parameter integer RC_7=32'h0000002C,
parameter integer RC_8=32'h00000380,
parameter integer RC_9=32'h000000F0,
parameter integer RC_10=32'h000001A0,
parameter integer RC_11=32'h00000012
)
(
input clk,
input dv,
input [HASH_IN_SIZE-1:0] state, //state
output [HASH_SIZE-1:0] out,
output out_valid
    );

    reg [HASH_SIZE-1:0] out_o=0;
    wire [HASH_IN_SIZE-1:0]round_out[0:rounds-1];
    reg out_valid_o=0;
        
    assign out=out_o;
    assign out_valid = out_valid_o;
    
    generate
        round_fn ROUND_1(     
        .state(state),
        .RC(RC_8),
        .round(round_out[0])
        );
        
        round_fn ROUND_2(     
        .state(round_out[0]),
        .RC(RC_9),
        .round(round_out[1])
        );
        
        round_fn ROUND_3(     
        .state(round_out[1]),
        .RC(RC_10),
        .round(round_out[2])
        );
        
//        round_fn ROUND_4(     
//        .state(round_out[2]),
//        .RC(RC_11),
//        .round(round_out[3])
//        );
    endgenerate
    
    integer i,j,k;
    always@(posedge clk) begin
        if(dv)begin
            out_o = round_out[rounds-1];
            out_valid_o = dv;
        end
        else begin
            out_valid_o = 1'b0;
        end
    end
endmodule


module round_fn#(
parameter integer y=3 // number of (p)lanes.
)
(
input [95:0] state,
input [31:0] RC,
output reg [95:0] round
);

    reg [31:0] A [0:y-1]; //plane A
    reg [31:0] P=0;
    reg [31:0] E, E1, E2;
    reg [31:0] B [0:y-1];
    
    integer i,j;
    always@(*)begin
        A[0] = state[31:0];
        A[1] = state[63:32];
        A[2] = state[95:64];
        //theta ?
        P = A[0] ^ A[1] ^ A[2]; //P <-- A0 xor A1 xor A2
        E = {P[26:0],P[31:27]} ^ {P[17:0],P[31:18]}; //E <-- P <<< (1,5) xor P <<< (1,14). Since x=1, the equation reduces to E <-- P <<< (5) xor P <<< (14). <<< - cyclic shift
        for(i=0;i<y;i=i+1)begin
            A[i] = A[i] ^ E;
        end
        //rhowest ?_west
        A[2] = {A[2][20:0],A[2][31:21]}; //A2 <-- A2 <<< (0,11). A1 <-- A1 <<< (1,0) removed as x=1.
        //iota ?
        A[0] = A[0] ^ RC;
        //chi ?
        B[0] = ~A[1] & A[2];
        B[1] = ~A[2] & A[0];
        B[2] = ~A[0] & A[1];
        for(j=0;j<y;j=j+1)begin
            A[j] = A[j] ^ B[j];
        end
        //rhoeast ?_east
        A[1] = {A[1][30:0],A[1][31]}; //A1 <-- A1 <<< (0,1); reduces to A1 <-- A1 <<< (1)
        A[2] = {A[2][23:0],A[2][31:24]}; //A2 <-- A2 <<< (2,8); reduces to A2 <-- A2 <<< (8)
        
        round={A[2],A[1],A[0]};
    end
endmodule
        
