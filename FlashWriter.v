module spi_flash_writer (
    input clk_internal,
    input i_FT_CS,
    input i_FT_SCK,	// SPI Clock from FT2232
    input i_FT_MOSI,	// Master Out, Slave In (FT2232 to FPGA)
    output o_FT_MISO,

    input i_SPI_MISO,
    output o_SPI_CLK,
    output o_SPI_MOSI,
    output o_SPI_CS,

    output o_HALT,
    output o_RESET

);

assign i_FT_FLASH_WRITE = !i_FT_CS; // FT2232 CS (active low) triggers flash programming mode
assign o_SPI_CLK = i_FT_FLASH_WRITE ? i_FT_SCK : spi_clk;
assign o_SPI_MOSI = i_FT_FLASH_WRITE ? i_FT_MOSI : spi_mosi;
assign o_SPI_CS = i_FT_FLASH_WRITE ? i_FT_CS : spi_cs;
// MISO from flash goes to both the FPGA SPI controller and FT2232
assign o_FT_MISO = i_FT_FLASH_WRITE ? i_SPI_MISO : 1'bz;

  always @(posedge clk_internal) begin
    if (i_FT_FLASH_WRITE) begin
        o_HALT <= 1'b1;  // Halt the 6809
        o_RESET <= 1'b1; // Optionally reset the 6809 to ensure idle state

    end else begin
        o_HALT <= 1'b0;  // Resume 6809 operation
        o_RESET <= 1'b0;

    end
end

endmodule

