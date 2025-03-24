// SPI device uses SPI Mode 0, with active low Chip Select
module spi_flash_controller (
    input spi_ce,            // SPI chip select signal from address decoder
    input reset,             
    input [15:0] i_ADDRESS_BUS, // Address from 6809 (16 bits)
    input i_RW,               // Read/Write control signal (only reads for flash)
    input clk,                // System clock
    input i_SPI_MISO,         // SPI Master In Slave Out
    output reg o_SPI_CLK,     // SPI Clock
    output reg o_SPI_MOSI,    // SPI Master Out Slave In
    output reg o_SPI_CS,      // SPI Chip Select (active low)
    output reg [7:0] o_DATA,  // Data output to 6809
    output reg o_MemoryReady
);

    wire [7:0] spi_command = 8'h03; // Command for SPI flash (READ command is 0x03)
    reg [23:0] spi_address = 24'b0; // Address for SPI flash (24 bits)
    reg [23:0] last_spi_address = 24'b0; // Last address for SPI flash
    reg [7:0] spi_data = 8'b0;        // Data read from SPI flash
    reg [5:0] bit_counter = 6'd0;     // Tracks SPI transaction progress (6 bits to cover up to 40)
    reg [5:0] memoryready_counter = 6'd0;     // Tracks SPI transaction progress (6 bits to cover up to 40)
    reg spi_active = 0;               // Indicates SPI operation is active
    reg clock_delay = 0;

    always @(posedge clk) begin
        if (~reset) begin
            spi_address <= 24'b0;     // Reset address
            last_spi_address <= 24'b0; // Reset address
            spi_data <= 8'b0;          // Reset data
            bit_counter <= 6'b0;       // Reset bit counter
            spi_active <= 1'b0;        // Reset SPI active flag
            o_SPI_CLK = 1'b0;         // Reset SPI clock
        end

        // Start SPI transaction when chip select is active and it's a read cycle
        if (spi_ce && i_RW && !spi_active && reset) begin
            spi_address <= {12'b0, i_ADDRESS_BUS[11:0]}; // Lower 12 bits of address to 24-bit SPI address
            if (spi_address != last_spi_address) begin
                spi_active <= 1'b1;         // Mark SPI as active
                last_spi_address <= spi_address; // Store the last address
                bit_counter <= 6'd0;        // Reset bit counter
                clock_delay <= 1'b0;
                o_MemoryReady <= 1'b0;     // Keep 6809 in wait state during SPI transaction

            end
        end

        if (spi_active && reset) begin
            o_SPI_CS <= 1'b0;           // Activate SPI chip select


            if (clock_delay) begin 
                o_SPI_CLK = ~o_SPI_CLK;   // Toggle SPI clock
                memoryready_counter <= 6'd0;
            end
            clock_delay <= 1'b1;

            if (~o_SPI_CLK) begin
                // On rising edge of SPI clock, handle data transfer
                if (bit_counter < 6'd8) begin //7
                    // Send SPI command (8 bits)
                    o_SPI_MOSI <= spi_command[7 - bit_counter];
                end else if (bit_counter < 6'd32) begin
                    // Send 24-bit SPI address (address starts at bit 8)
                    o_SPI_MOSI <= spi_address[31 - bit_counter];
                end else if (bit_counter == 6'd40) begin
                    // End of SPI transaction
                    spi_active <= 1'b0;      // Mark SPI as inactive
                    o_DATA <= spi_data;      // Output received data to 6809   
                end


            end
            else begin
                if (bit_counter < 6'd40) begin
                    // Receive 8-bit data (after address)
                    spi_data[7 - (bit_counter - 6'd32)] <= i_SPI_MISO;
                end
                // Increment bit counter (always within 6-bit range, safe to truncate)
                bit_counter <= bit_counter + 1;
            end
        end else begin
            // Idle state: set SPI signals to default
            o_SPI_MOSI <= 1'bz;        // High Impedance at idle
            o_SPI_CLK <= 1'b0;         // Clock low in idle (for SPI Mode 0)
            o_MemoryReady <= 1'b1;     // Allow the 6809 to continue
            o_SPI_CS <= 1'b1;        // Deactivate SPI chip select
            
        end
    end
endmodule
