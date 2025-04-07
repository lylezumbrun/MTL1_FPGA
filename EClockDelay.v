module e_clk_delay (
    input i_clk,  // PLL-generated fast clock
    input i_e_clk,       // 6809 E clock
    output reg o_e_delayed  // Active-low buffer OE
);

    reg e_prev = 1;
    reg [1:0] counter = 0;
    reg delaying = 0;

    always @(posedge i_clk) begin
        // Detect falling edge of E
        e_prev <= i_e_clk;

        if (e_prev && ~i_e_clk) begin
            delaying <= 1;
            counter <= 2'd2;  // 2 * 10ns = 20ns delay
            o_e_delayed <= 1; // keep buffer active
        end else if (delaying) begin
            if (counter == 0) begin
                o_e_delayed <= 0; // disable buffer
                delaying <= 0;
            end else begin
                counter <= counter - 1;
                o_e_delayed <= 1; // still active
            end
        end else begin
            o_e_delayed <= 0; // default: disable buffer
        end
    end

endmodule
