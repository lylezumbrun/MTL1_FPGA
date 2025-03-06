module spi_flash_controller (
    input spi_ce,               // SPI chip select signal from address decoder
    input [15:0] i_ADDRESS_BUS, // Address from 6809
    input i_RW,                 // Read/Write control signal (only reads for flash)
    input clk,                  // System clock
    input i_SPI_MISO,           // SPI Master In Slave Out
    output reg o_SPI_CLK,   // SPI Clock
    output reg o_SPI_MOSI,  // SPI Master Out Slave In
    output reg o_SPI_CS,    // SPI Chip Select (active low)
    output reg [7:0] o_DATA,     // Data output to 6809
    output reg o_MemoryReady
);

    wire [7:0] spi_command = 8'h03; // Command for SPI flash (READ command is 0x03)
    reg [23:0] spi_address = 24'b0; // Address for SPI flash
    reg [23:0] last_spi_address = 24'b0; // Address for SPI flash
    reg [7:0] spi_data = 8'b0;      // Data read from SPI flash
    reg [5:0] bit_counter = 6'b0;   // Tracks SPI transaction progress (6 bits to cover up to 40)
    reg spi_active = 0;             // Indicates SPI operation is active

    always @(posedge clk) begin

        if (spi_ce && i_RW && !spi_active) begin
            // Start SPI transaction
                   // Activate SPI chip select
            spi_address <= {8'b0, i_ADDRESS_BUS}; // Prepare 24-bit address
            if(spi_address != last_spi_address) begin
                spi_active <= 1'b1;                  // Mark SPI as active
                bit_counter <= 6'd0;                 // Reset bit counter
                last_spi_address <= spi_address;
            end
        end

        if (spi_active) begin
            o_SPI_CS <= 1'b0; 
            // Toggle SPI clock
            o_SPI_CLK = ~o_SPI_CLK;
            o_MemoryReady <= 1'b0; // Insert a wait state to the 6809 to allow time to access data.

            if (o_SPI_CLK) begin
                // On rising edge of SPI clock, handle data transfer
                if (bit_counter < 6'd8) begin
                    // Send SPI command (8 bits)
                    o_SPI_MOSI <= spi_command[7 - bit_counter];
                end else if (bit_counter < 6'd32) begin
                    // Send SPI address (24 bits)
                    o_SPI_MOSI <= spi_address[31 - bit_counter];
                end else if (bit_counter < 6'd40) begin
                    // Receive SPI data (8 bits)
                    spi_data[7 - (bit_counter - 6'd32)] <= i_SPI_MISO;
                end

                // Increment bit counter (always within 6-bit range, safe to truncate)
                bit_counter <= bit_counter + 1;

                if (bit_counter == 6'd40) begin
                    // End of SPI transaction
                    o_SPI_CS <= 1'b1;   // Deactivate chip select
                    spi_active <= 1'b0; // Mark SPI as inactive
                    o_DATA <= spi_data; // Output received data
                end
            end
        end 
        else begin
            // Idle state: set SPI signals to default
            o_SPI_MOSI <= 1'bz; // High Impedance at idle
            o_SPI_CLK <= 1'b0; // need to be low at idle for SPI Mode 0 (CPOL = 0, CPHA = 0) The FT2232 supports mode 0 so follow that requirement
            o_MemoryReady <= 1'b1; // Release wait state allow the 6809 to continue
        end
    end
endmodule
