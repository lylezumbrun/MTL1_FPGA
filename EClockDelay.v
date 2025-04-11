module e_clk_delay (
    input i_clk,          // Fast PLL clock (e.g., 100 MHz)
    input i_e_clk,        // 6809 E clock
    output reg o_e_delayed = 0  // Active-low buffer OE (initialized to disabled)
);

    reg e_prev = 1;
    reg [1:0] counter = 0;
    reg delaying = 0;

    always @(posedge i_clk) begin
        e_prev <= i_e_clk;

        // While E is high, keep output enable active (1)
        if (i_e_clk) begin
            delaying <= 0;
            counter <= 0;
            o_e_delayed <= 1;
        end
        // On falling edge of E, start delay
        else if (e_prev && ~i_e_clk) begin
            delaying <= 1;
            counter <= 2'd2; // 2 cycles delay (20ns @ 100MHz)
            o_e_delayed <= 1;
        end
        // Finish delay after falling edge
        else if (delaying) begin
            if (counter == 0) begin
                o_e_delayed <= 0; // Disable buffer (OE low = inactive)
                delaying <= 0;
            end else begin
                counter <= counter - 1;
                o_e_delayed <= 1; // Still active during delay
            end
        end
        // Default state when idle and not delaying
        else begin
            o_e_delayed <= 0;
        end
    end

endmodule
