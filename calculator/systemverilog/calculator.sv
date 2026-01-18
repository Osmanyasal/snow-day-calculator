`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Osman Yasal
// 
// Create Date: 01/18/2026
// Design Name: 
// Module Name: calculator
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
module calculator(
    input logic CLK100MHZ,
    input logic [15:0] SW,
    input logic BTNU, // a + b
    input logic BTND, // a - b
    input logic BTNL, // a * b
    input logic BTNR, // a / b
    input logic BTNC, // = (calculate)
    output logic [7:0] AN,      // Anodes
    output logic [7:0] out      // Cathodes
    );
    // --- Clock divider to meet timing requirements ---
    logic CLK5MHZ;
    clock_divider clk_div_inst (
        .clk_in(CLK100MHZ),
        .clk_out(CLK5MHZ)
    );
    // --- State & Op Definitions ---
    typedef enum {IDLE, BTN_PRESS, RESULT} state_t;
    state_t current_state, next_state;
    
    typedef enum {NONE, ADD, SUB, MUL, DIV} op_t; 
    op_t current_op;
    
    // --- Internal Signals ---
    logic [2:0] btn_synchronizer;
    logic signed [15:0] a, b;
    logic signed [32:0] total;
    logic btn_edge;
    
    // --- Display Signals ---
    logic [31:0] val_to_display;     // The value routed to the screen
    logic [39:0] bcd_result;         // BCD output from converter
    logic [3:0]  current_nibble;     // Current 4-bit digit to render
    logic [19:0] refresh_counter;    // Mux timer
    logic [2:0]  digit_select;       // Active digit

    // --- Initialization ---
    initial begin
        current_op = NONE;
        btn_edge = 0;
        a = '0;
        b = '0;
        total = '0;
        btn_synchronizer = '0;
        current_state = IDLE;
        next_state = IDLE;
    end
    
    // -------------------------------------------------------------------------
    // 1. State Register & Input Sync
    // -------------------------------------------------------------------------
    always_ff @(posedge CLK5MHZ) begin
        current_state <= next_state;
        btn_synchronizer <= ((btn_synchronizer << 1) | BTNU | BTND | BTNL | BTNR | BTNC);  
    end
    
    // -------------------------------------------------------------------------
    // 2. Next State Logic
    // -------------------------------------------------------------------------
    always_comb begin
        next_state = current_state;
        btn_edge = (btn_synchronizer[2:1] == 2'b01); 
        
        case (current_state)
            IDLE: begin
                // Transition 1: User enters 'a' then presses Op
                if(btn_edge && (BTNU | BTND | BTNL | BTNR))
                    next_state = BTN_PRESS;
            end
            BTN_PRESS: begin
                // Transition 2: User enters 'b' then presses Equals
                if(btn_edge && BTNC)
                    next_state = RESULT;
            end
            RESULT: begin
                // Transition 3: Reset
                if(btn_edge)
                    next_state = IDLE;
            end
        endcase
    end
    
    // -------------------------------------------------------------------------
    // 3. Datapath Logic
    // -------------------------------------------------------------------------
    always_ff @(posedge CLK5MHZ) begin
        if(btn_edge) begin
            
            // ff Operation
            if(BTNU) current_op <= ADD;
            else if(BTND) current_op <= SUB;
            else if(BTNL) current_op <= MUL;
            else if(BTNR) current_op <= DIV;
            
            case(current_state)
                IDLE: begin
                    if (BTNU | BTND | BTNL | BTNR) begin
                        a <= SW; // ff 'a'
                    end
                end
                
                BTN_PRESS: begin
                    if (BTNC) begin
                        b <= SW; // ff 'b'
                        
                        // Calculate Total based on 'a' and current SW ('b')
                        case (current_op)
                            ADD: total <= a + SW;
                            SUB: total <= a - SW;
                            MUL: total <= a * SW;
                            DIV: begin
                                if(SW != 0) total <= a / SW;
                                else total <= '0; 
                            end
                            default: total <= '0;
                        endcase
                    end
                end
            endcase
        end
    end
    
    // -------------------------------------------------------------------------
    // 4. Output Logic (Display Mux)
    // -------------------------------------------------------------------------

    // A. Select Value based on Order/State
    always_comb begin
        case(current_state)
            // Phase 1: User is selecting inputs for A
            IDLE: begin
                val_to_display = {16'b0, SW}; 
            end

            // Phase 2: User is selecting inputs for B
            // (Even though 'a' is stored, we show SW so user can see what they type for 'b')
            BTN_PRESS: begin
                val_to_display = {16'b0, SW}; 
            end

            // Phase 3: Show calculation result
            RESULT: begin
                // Handle Negative Numbers (Show Magnitude)
                if (total < 0) 
                    val_to_display = -total;
                else 
                    val_to_display = total[31:0];
            end
            
            default: val_to_display = 0;
        endcase
    end

    // B. Binary to BCD Conversion
    bin32_to_bcd bcd_conv_inst (
        .binary(val_to_display),
        .bcd(bcd_result)
    );

    // C. Multiplexing Timer
    always_ff @(posedge CLK100MHZ) begin
        refresh_counter <= refresh_counter + 1;
    end
    assign digit_select = refresh_counter[19:17]; 

    // D. Digit Selector
    always_comb begin
        case(digit_select)
            3'd0: current_nibble = bcd_result[3:0];   
            3'd1: current_nibble = bcd_result[7:4];   
            3'd2: current_nibble = bcd_result[11:8];  
            3'd3: current_nibble = bcd_result[15:12]; 
            3'd4: current_nibble = bcd_result[19:16]; 
            3'd5: current_nibble = bcd_result[23:20]; 
            3'd6: current_nibble = bcd_result[27:24]; 
            3'd7: current_nibble = bcd_result[31:28]; 
        endcase
    end

    // E. 7-Segment Decoder
    seven_segment seg_decode_inst (
        .sw_in(current_nibble),
        .out(out)
    );

    // F. Anode Driver
    always_comb begin
        AN = 8'b11111111; 
        AN[digit_select] = 1'b0; 
    end

endmodule