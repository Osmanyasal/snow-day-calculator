`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 01/18/2026
// Design Name: 
// Module Name: bin32_to_bcd
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


// double dabble implementation for binary to bcd converter
module bin32_to_bcd(
    input logic [31:0] binary,
    output logic [39:0] bcd // 40 digit
    );
    
    logic [71:0] bcd_binary;
    always_comb begin
        bcd_binary = '0;
        bcd_binary[31:0] = binary;
        
        for(int i=0;i<32;i++) begin
            for(int j=0;j<10;j++) begin
                if(bcd_binary[32 + j*4 +:4] >= 5)
                    bcd_binary[32 + j*4 +:4] += 4'd3;
            end
            bcd_binary = bcd_binary << 1;
        end
        bcd = bcd_binary[71:32];
    end
endmodule
