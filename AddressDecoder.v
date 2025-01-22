module address_decoder (
    input i_FT_CS,
    input [15:0] address,     // 16-bit address bus from 6809
    output reg sram_ce,       // SRAM chip enable
    output reg spi_ce         // SPI flash chip select
);

    // Define address ranges for SRAM and SPI Flash
    parameter SRAM_START = 16'h0000;
    parameter SRAM_END = 16'h0FFF;   // SRAM range: 0x0000 to 0x0FFF (4KB)
    
    parameter FLASH_START = 16'hF000; // Starting address for SPI flash (0xF000)
    parameter FLASH_END = 16'hFFFF;   // Ending address for SPI flash (0xFFFF)

    // Decoder logic
    always @(*) begin
        // Default values
        sram_ce = 1'b0;  // Deactivate SRAM by default
        spi_ce = 1'b1;   // Deactivate SPI Flash by default

        // Check if address is in SRAM range
        if (address >= SRAM_START && address <= SRAM_END) begin
            sram_ce = 1'b1;   // Activate SRAM chip enable
        end

        // Check if address is in SPI Flash range and that FT2232 is not active low on the chip select, if active low then its controling the flash chip.
        if (address >= FLASH_START && address <= FLASH_END && i_FT_CS) begin
            spi_ce = 1'b0;    // Activate SPI Flash chip select
        end
    end

endmodule
