`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 01/15/2026
// Design Name: 
// Module Name: seven_segment
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


module seven_segment(
    input logic [3:0] sw_in,
    output logic [7:0] out
    );
    
    always_comb begin
         
        case(sw_in)          //dec_gfedcba
            4'h0: out = 8'b11000000; // 0
            4'h1: out = 8'b11111001; // 1
            4'h2: out = 8'b10100100; // 2
            4'h3: out = 8'b10110000; // 3
            4'h4: out = 8'b10011001; // 4
            4'h5: out = 8'b10010010; // 5
            4'h6: out = 8'b10000010; // 6
            4'h7: out = 8'b11111000; // 7
            4'h8: out = 8'b10000000; // 8
            4'h9: out = 8'b10010000; // 9
            4'hA: out = 8'b10001000; // A
            4'hB: out = 8'b10000011; // b
            4'hC: out = 8'b11000110; // C
            4'hD: out = 8'b10100001; // d
            4'hE: out = 8'b10000110; // E
            4'hF: out = 8'b10001110; // F
            default: out = 8'b11111111; // all OFF
        endcase
    end
endmodule
