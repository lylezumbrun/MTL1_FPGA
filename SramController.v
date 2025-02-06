module sram_controller(
    input sram_ce,      // Address decoder select
    input i_RW,         // Read/Write control signal from 6809 (low is write operation)
    input i_E,          // Enable signal from 6809
    output reg o_WE,    // SRAM Write Enable
    output reg o_RE,    // SRAM Read Enable
    output reg o_CE,    // SRAM Chip Enable (active low)
    output reg o_CE2    // SRAM Chip Enable (active high)
);

    always @(*) begin
        // Default assignments to avoid latches
        o_WE = 1'b1;  // Deactivate write enable by default
        o_RE = 1'b1;  // Deactivate read enable by default
        o_CE = 1'b1;  // SRAM not selected by default
        o_CE2 = 1'b0; // SRAM not selected by default

        // If SRAM is selected and the enable signal is active
        if (sram_ce && i_E) begin
            o_WE = i_RW;    // Write Enable (active low) when i_RW is low
            o_RE = !i_RW;     // Read Enable (active high) when i_RW is high
            o_CE = 1'b0;     // Activate SRAM chip enable (active low)
            o_CE2 = 1'b1;    // Activate SRAM chip enable (active high)
        end
    end

endmodule
