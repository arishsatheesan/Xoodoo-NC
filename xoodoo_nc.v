
`timescale 1ns / 1ps

/*** Only full rounds are considered ***/

module xoodoo_nc#(
parameter integer x=1, //only 32 bits. No plane, only lane
parameter integer y=3, // number of (p)lanes.
parameter integer z=32, // number of bits in each lane
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
input rst,
input dv, // single pulse
input [95:0] state, // state (input message)
output [HASH_SIZE-1:0] out,
output out_valid
    );
    wire clk_i;
    wire dv_i;
    wire rst_i;
    wire [95:0] state_i;
    wire [31:0] RC [0:11];
//    reg delay_dv;

    reg [HASH_SIZE-1:0] out_o;
    reg [95:0]round_out[0:rounds-1];
    reg out_valid_o;
        
    reg [z-1:0] A [0:y-1]; //(p)lane A
    reg [z-1:0] P;
    reg [z-1:0] E;
    reg [z-1:0] B [0:y-1];
    
    assign clk_i = clk;
    assign dv_i = dv;
//    assign dv_i = dv && ~delay_dv;
    assign rst_i = rst;
    assign state_i = state;
    assign out=out_o;
    assign out_valid = out_valid_o;
    
    assign RC[0]=RC_0;
    assign RC[1]=RC_1;
    assign RC[2]=RC_2;
    assign RC[3]=RC_3;
    assign RC[4]=RC_4;
    assign RC[5]=RC_5;
    assign RC[6]=RC_6;
    assign RC[7]=RC_7;
    assign RC[8]=RC_8;
    assign RC[9]=RC_9;
    assign RC[10]=RC_10;
    assign RC[11]=RC_11;
    
    integer i,j,k;
    always@(posedge clk_i) begin
//        delay_dv <= dv;
        if(rst)begin
            out_o = 0;
            out_valid_o = 0;
            round_out[0] = 0;
            round_out[1] = 0;
            round_out[2] = 0;
        end
        else if(dv_i)begin
            //Round 1
            round_out[0]=round(state_i,RC[rc_round]);
            //Round 2
            round_out[1]=round(round_out[0],RC[rc_round+1]);
            //Round 3
            round_out[2]=round(round_out[1],RC[rc_round+2]);
            // Add more rounds according to the the value of 'rounds'
            // Concatanate round outputs if output needed is multiple of 96
            out_o = round_out[2];
            
            out_valid_o = dv_i;
        end
        else begin
            out_o = 0;
            out_valid_o = 1'b0;
        end
    end
        
    function [95:0] round;
        input [95:0] state;
        input [31:0] RC;
        begin
            A[0] = state[31:0];
            A[1] = state[63:32];
            A[2] = state[95:64];
            //theta
            P = A[0] ^ A[1] ^ A[2]; //P <-- A0 xor A1 xor A2
            E = {P[26:0],P[31:27]} ^ {P[17:0],P[31:18]}; //E <-- P <<< (1,5) xor P <<< (1,14). Since x=1, the equation reduces to E <-- P <<< (5) xor P <<< (14). <<< - cyclic shift
            for(i=0;i<y;i=i+1)begin
                A[i] = A[i] ^ E;
            end
            //rhowest 
            A[2] = {A[2][20:0],A[2][31:21]}; //A2 <-- A2 <<< (0,11). A1 <-- A1 <<< (1,0) removed as x=1.
            //iota
            A[0] = A[0] ^ RC;
            //chi
            B[0] = ~A[1] & A[2];
            B[1] = ~A[2] & A[0];
            B[2] = ~A[0] & A[1];
            for(j=0;j<y;j=j+1)begin
                A[j] = A[j] ^ B[j];
            end
            //rhoeast 
            A[1] = {A[1][30:0],A[1][31]}; //A1 <-- A1 <<< (0,1); reduces to A1 <-- A1 <<< (1)
            A[2] = {A[2][23:0],A[2][31:24]}; //A2 <-- A2 <<< (2,8); reduces to A2 <-- A2 <<< (8)
            
            round={A[2],A[1],A[0]};
        end
    endfunction

endmodule
