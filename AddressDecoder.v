module address_decoder (
    input i_FT_CS,
    input [15:0] address,     // 16-bit address bus from 6809
    input i_enable,
    input i_Q,
    output reg sram_ce,       // SRAM chip enable
    output reg spi_ce,         // SPI flash chip select
    output reg uart_data_ce,
    output reg uart_status_ce,
    output reg uart_control_ce
);
    // Memory expansion area 0x1000 - 0x7FFF
    // Defined address ranges for SRAM
    parameter SRAM_START = 16'h1000;
    parameter SRAM_END = 16'h1FFF;   // SRAM range: 0x1000 to 0x1FFF (4KB)
    // Defined address ranges for ROM
    parameter FLASH_START = 16'h3000; // Starting address for SPI flash (0x3000)
    parameter FLASH_END = 16'h3FFF;   // Ending address for SPI flash (0x3FFF)





    // Defined addresses for UART I/O
    parameter UART_DATA = 16'hA000; // Register for sending and receive UART data
    parameter UART_STATUS = 16'hA001; // UART Status Register
    parameter UART_CONTROL = 16'hA002; // UART Control Register - Optional at this point


    // Decoder logic
    always @(*) begin
        // Default values
        sram_ce = 1'b0;  // Deactivate SRAM by default
        spi_ce = 1'b0;   // Deactivate SPI Flash by default
        uart_data_ce = 1'b0;
        uart_status_ce = 1'b0;
        uart_control_ce = 1'b0;

        // Check if address is in SRAM range
        if (address >= SRAM_START && address <= SRAM_END && i_enable) begin
            sram_ce = 1'b1;   // Activate SRAM chip enable
        end

        // Check if address is in SPI Flash range and that FT2232 is not active low on the chip select, if active low then its controling the flash chip.
        if (address >= FLASH_START && address <= FLASH_END && i_FT_CS && i_Q || i_enable) begin
            spi_ce = 1'b1;    // Activate SPI Flash chip select
        end
        if (address == UART_DATA && i_enable) begin
            uart_data_ce = 1'b1;
        end
        if (address == UART_STATUS && i_enable) begin
            uart_status_ce = 1'b1;
        end
        if (address == UART_CONTROL && i_enable) begin
            uart_control_ce = 1'b1;
        end
    end

endmodule
