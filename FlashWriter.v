
// Input CS needs pulled up and MISO pulled up when not in use.

module spi_flash_writer (
    input i_FT_CS,
    input i_FT_SCK,    // SPI Clock from FT2232
    input i_FT_MOSI,   // Master Out, Slave In (FT2232 to FPGA)
    output reg o_FT_MISO, // Changed to reg

    input i_SPI_MISO,
    output reg o_SPI_CLK,
    output reg o_SPI_MOSI,
    output reg o_SPI_CS
);

// Combinational logic to handle control signals
always @(*) begin
    if (~i_FT_CS) begin
        // When FT2232 is active, control SPI signals
        o_SPI_CLK <= i_FT_SCK;   // Pass SPI clock through
        o_SPI_MOSI <= i_FT_MOSI; // Pass MOSI data through
        o_SPI_CS <= i_FT_CS;     // Pass CS state through
        o_FT_MISO <= i_SPI_MISO; // Pass MISO data back to FT2232
    end else begin
        o_SPI_CLK <= 1'b0;  // Tri-state to allow 6809 control
        o_SPI_MOSI <= 1'bz; // Tri-state to allow 6809 control
        o_SPI_CS <= 1'b1;   // Tri-state to allow 6809 control
        o_FT_MISO <= 1'bz;  // Tri-state MISO when FT2232 is not active
    end
end




endmodule
