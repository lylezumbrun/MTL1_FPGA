module address_decoder (
    input i_FT_CS,
    input i_reset,
    input [15:0] address,     // 16-bit address bus from 6809
    output reg spi_ce,         // SPI flash chip select
    output reg uart_data_ce,
    output reg uart_status_ce,
    output reg uart_control_ce
);

    // Defined address ranges for ROM
    parameter FLASH_START = 16'h3000; // Starting address for SPI flash (0x3000)
    parameter FLASH_END = 16'h7FFF;   // Ending address for SPI flash (0x7FFF) (20KB)

    // Defined addresses for UART I/O
    parameter UART_DATA = 16'hA000; // Register for sending and receive UART data
    parameter UART_STATUS = 16'hA001; // UART Status Register
    parameter UART_CONTROL = 16'hA002; // UART Control Register - Optional at this point


    // Decoder logic
    always @(*) begin
        // Default values
        spi_ce = 1'b0;   // Deactivate SPI Flash by default
        uart_data_ce = 1'b0;
        uart_status_ce = 1'b0;
        uart_control_ce = 1'b0;

        // Check if address is in SPI Flash range and that FT2232 is not active low on the chip select, if active low then its controling the flash chip.
        if (address >= FLASH_START && address <= FLASH_END && i_FT_CS && i_reset) begin
            spi_ce = 1'b1;    // Activate SPI Flash chip select
        end
        if (address == UART_DATA && i_reset) begin
            uart_data_ce = 1'b1;
        end
        if (address == UART_STATUS && i_reset) begin
            uart_status_ce = 1'b1;
        end
        if (address == UART_CONTROL && i_reset) begin
            uart_control_ce = 1'b1;
        end
    end

endmodule
