module e_clk_delay (
    input i_clk,          // Fast PLL clock (e.g., 100 MHz)
    input i_e_clk,        // 6809 E clock
    input i_reset,        // Reset signal (active high)
    output reg o_e_longdelay = 0,  // Active-low buffer OE (initialized to disabled)
    output reg o_e_shortdelay = 0,  // Active-low buffer OE (initialized to disabled)
    output reg o_e_sramlongdelay = 0,  // Active-low buffer OE (initialized to disabled)
    output reg o_e_sramshortdelay = 0  // Active-low buffer OE (initialized to disabled)
);

    reg e_prev = 1;
    reg [2:0] counter = 0; // Increased to 3 bits to accommodate larger delay
    reg delaying = 0;
    reg [6:0] start_counter = 0; // 6-bit counter for delay

    always @(posedge i_clk) begin
        e_prev <= i_e_clk;

        // While E is high, keep output enable active (1)
        if (i_e_clk && i_reset) begin
            delaying <= 0;
            counter <= 0;
            o_e_longdelay <= 1;
            o_e_sramlongdelay <= 1;
           
            if (start_counter < 6'd44) begin
                o_e_shortdelay <= 0; // Enable short delay buffer
                o_e_sramshortdelay <= 0; // Enable short delay buffer
                start_counter <= start_counter + 1;
            end 
            else begin
                o_e_shortdelay <= 1; // Disable short delay buffer
                o_e_sramshortdelay <= 1; // Disable short delay buffer
            end
        end

        // On falling edge of E, start delay
        else if (e_prev && ~i_e_clk) begin
            delaying <= 1;
            counter <= 3'd4; // 4 cycles delay (50ns @ 100MHz)
            o_e_longdelay <= 1;
            o_e_shortdelay <= 1;
            o_e_sramlongdelay <= 1;
            o_e_sramshortdelay <= 1;
        end

        // Finish delay after falling edge
        else if (delaying) begin
            if (counter == 0) begin
                o_e_sramlongdelay <= 0; // Disable buffer (OE low = inactive)
                o_e_sramshortdelay <= 0; // Disable buffer (OE low = inactive
                delaying <= 0;
            end
            if (counter <= 3'd2) begin
                o_e_longdelay <= 0; // Disable buffer (OE low = inactive)
                o_e_shortdelay <= 0; // Disable buffer (OE low = inactive)
            end
            if(counter > 0) begin
                counter <= counter - 1;
            end
        end
        // Default state when idle and not delaying
        else begin
            o_e_longdelay <= 0;
            o_e_shortdelay <= 0;
            o_e_sramlongdelay <= 0;
            o_e_sramshortdelay <= 0;
            start_counter <= 0; // Reset start counter
        end
    end

endmodule
