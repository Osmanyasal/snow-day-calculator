`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 01/18/2026
// Design Name: 
// Module Name: clock_divider
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


module clock_divider(
    input logic clk_in,      // 100 MHz
    output logic clk_out     // 5 MHz
    );
    
    // To get 5 MHz from 100 MHz, we divide by 20.
    // Count 0 to 9 (10 cycles) = Toggle.
    // 10 cycles high + 10 cycles low = 20 cycles total.
    
    logic [4:0] counter = 0;
    logic slow_clk = 0;
    
    always_ff @(posedge clk_in) begin
        if (counter == 9) begin
            counter <= 0;
            slow_clk <= ~slow_clk; // Toggle
        end else begin
            counter <= counter + 1;
        end
    end
    
    assign clk_out = slow_clk;
    
endmodule
