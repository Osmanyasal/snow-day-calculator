`timescale 1ns / 1ps

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

    // --- Clock divider ---
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
    logic is_negative;               // Flag to indicate if we need a minus sign
    logic [31:0] val_to_display;     // The Absolute Value routed to BCD
    logic [39:0] bcd_result;         // BCD output
    logic [3:0]  current_nibble;     // Current 4-bit digit to render
    logic [19:0] refresh_counter;    // Mux timer
    logic [2:0]  digit_select;       // Active digit
    logic [7:0]  decoded_segments;   // Output from 7-seg decoder

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
    // 1. State Register & Input Sync (5MHz)
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
            IDLE:      if(btn_edge && (BTNU | BTND | BTNL | BTNR)) next_state = BTN_PRESS;
            BTN_PRESS: if(btn_edge && BTNC) next_state = RESULT;
            RESULT:    if(btn_edge) next_state = IDLE;
        endcase
    end
    
    // -------------------------------------------------------------------------
    // 3. Datapath Logic (5MHz)
    // -------------------------------------------------------------------------
    always_ff @(posedge CLK5MHZ) begin
        if(btn_edge) begin
            if(BTNU) current_op <= ADD;
            else if(BTND) current_op <= SUB;
            else if(BTNL) current_op <= MUL;
            else if(BTNR) current_op <= DIV;
            
            case(current_state)
                IDLE: if (BTNU | BTND | BTNL | BTNR) a <= SW;
                BTN_PRESS: begin
                    if (BTNC) begin
                        b <= SW;
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

    // A. Calculate Magnitude and Sign
    always_comb begin
        is_negative = 0; // Default
        val_to_display = 0;

        case(current_state)
            // For inputs (IDLE/BTN_PRESS), check if SW is negative (signed 16-bit)
            IDLE, BTN_PRESS: begin
                if (SW[15] == 1) begin // Check Sign Bit
                    val_to_display = -SW; // 2's complement negation
                    is_negative = 1;
                end else begin
                    val_to_display = {16'b0, SW};
                    is_negative = 0;
                end
            end

            // For result, check total
            RESULT: begin
                if (total < 0) begin
                    val_to_display = -total;
                    is_negative = 1;
                end else begin
                    val_to_display = total[31:0];
                    is_negative = 0;
                end
            end
        endcase
    end

    // B. BCD Conversion
    bin32_to_bcd bcd_conv_inst (
        .binary(val_to_display),
        .bcd(bcd_result)
    );

    // C. Multiplexing Timer (100MHz for smooth display)
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
        .out(decoded_segments) // Intermediate signal
    );
    
    // F. Final Output Driver (With Negative Sign Override)
    always_comb begin
        // Anode Control
        AN = 8'b11111111; 
        AN[digit_select] = 1'b0; 
        
        // Cathode Control
        // If we are on the leftmost digit (7) AND the number is negative...
        if (digit_select == 3'd7 && is_negative) begin
             // Display MINUS sign only (Segment G ON, others OFF)
             // 10111111 -> Only 'g' (middle) is 0 (Active)
             out = 8'b10111111; 
        end else begin
             // Otherwise, display the decoded number
             out = decoded_segments;
        end
    end

endmodule
