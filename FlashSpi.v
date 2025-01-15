module spi_master (
    input clk,                // FPGA clock
    input [7:0] data_in,      // Data to send
    input start,              // Start SPI transaction
    output reg mosi,          // SPI MOSI
    input miso,               // SPI MISO
    output reg sck,           // SPI Clock
    output reg cs,            // SPI Chip Select
    output reg [7:0] data_out // Received data
);

    reg [3:0] bit_count;
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (start) begin
            cs <= 0;  // Assert CS (active low)
            bit_count <= 8;
            shift_reg <= data_in;
            data_out <= 8'b0;
        end else if (bit_count > 0) begin
            sck <= ~sck;  // Toggle clock
            if (sck) begin
                mosi <= shift_reg[7];        // Send MSB first
                shift_reg <= {shift_reg[6:0], miso};  // Shift in MISO
                bit_count <= bit_count - 1;
            end
        end else begin
            cs <= 1;  // De-assert CS
        end
    end

endmodule
