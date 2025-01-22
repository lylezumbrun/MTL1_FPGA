module spi_flash_controller (
    input spi_ce,               // SPI chip select signal from address decoder
    input [15:0] i_ADDRESS_BUS, // Address from 6809
    input i_RW,                 // Read/Write control signal (only reads for flash)
    input clk,                  // System clock
    input i_SPI_MISO,           // SPI Master In Slave Out
    output reg o_SPI_CLK = 0,   // SPI Clock
    output reg o_SPI_MOSI = 0,  // SPI Master Out Slave In
    output reg o_SPI_CS = 1,    // SPI Chip Select (active low)
    output reg [7:0] o_DATA     // Data output to 6809
);

    reg [7:0] spi_command = 8'h03; // Command for SPI flash (READ command is 0x03)
    reg [23:0] spi_address = 24'b0; // Address for SPI flash
    reg [7:0] spi_data = 8'b0;      // Data read from SPI flash
    reg [5:0] bit_counter = 6'b0;   // Tracks SPI transaction progress (6 bits to cover up to 40)
    reg spi_active = 0;             // Indicates SPI operation is active

    always @(posedge clk) begin
        if (spi_ce && i_RW && !spi_active) begin
            // Start SPI transaction
            o_SPI_CS <= 1'b0;                    // Activate SPI chip select
            spi_address <= {8'b0, i_ADDRESS_BUS}; // Prepare 24-bit address
            spi_active <= 1'b1;                  // Mark SPI as active
            bit_counter <= 6'd0;                 // Reset bit counter
        end

        if (spi_active) begin
            // Toggle SPI clock
            o_SPI_CLK <= ~o_SPI_CLK;

            if (o_SPI_CLK) begin
                // On rising edge of SPI clock, handle data transfer
                if (bit_counter < 8) begin
                    // Send SPI command (8 bits)
                    o_SPI_MOSI <= spi_command[7 - bit_counter];
                end else if (bit_counter < 32) begin
                    // Send SPI address (24 bits)
                    o_SPI_MOSI <= spi_address[31 - bit_counter];
                end else if (bit_counter < 40) begin
                    // Receive SPI data (8 bits)
                    spi_data[7 - (bit_counter - 32)] <= i_SPI_MISO;
                end

                // Increment bit counter
                bit_counter <= bit_counter + 1;

                if (bit_counter == 6'd40) begin
                    // End of SPI transaction
                    o_SPI_CS <= 1'b1;   // Deactivate chip select
                    spi_active <= 1'b0; // Mark SPI as inactive
                    o_DATA <= spi_data; // Output received data
                end
            end
        end else begin
            // Idle state: set SPI signals to default
            o_SPI_MOSI <= 1'b0;
            o_SPI_CLK <= 1'b0;
        end
    end
endmodule
