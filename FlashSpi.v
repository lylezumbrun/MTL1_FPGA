module spi_flash_controller (
    input spi_ce,              // SPI chip select signal from address decoder
    input [15:0] i_ADDRESS_BUS, // Address from 6809
    input i_RW,                // Read/Write control signal (only reads for flash)
    input clk,                 // System clock
    input i_SPI_MISO,          // SPI Master In Slave Out
    output reg o_SPI_CLK,      // SPI Clock
    output reg o_SPI_MOSI,     // SPI Master Out Slave In
    output reg o_SPI_CS,       // SPI Chip Select
    output reg [7:0] o_DATA    // Data output to 6809
);

    reg [7:0] spi_command;  // Command for SPI flash (READ command is 0x03)
    reg [23:0] spi_address; // Address for SPI flash
    reg [7:0] spi_data;     // Data read from SPI flash
    reg [3:0] bit_counter;  // Tracks SPI transaction progress
    reg spi_active;         // Indicates SPI operation is active

    always @(posedge clk) begin
        if (spi_ce && i_RW) begin
            // Start SPI read operation
            o_SPI_CS <= 1'b0;  // Activate SPI chip select
            spi_active <= 1'b1;

            // Prepare SPI command and address
            spi_command <= 8'h03;  // SPI read command
            spi_address <= {8'b0, i_ADDRESS_BUS}; // Address (24 bits)
            bit_counter <= 4'd0;  // Reset bit counter
        end

        if (spi_active) begin
            // Generate SPI clock
            o_SPI_CLK <= ~o_SPI_CLK;

            if (o_SPI_CLK) begin
                // On rising edge of SPI clock, shift data out
                if (bit_counter < 8) begin
                    // Send SPI command
                    o_SPI_MOSI <= spi_command[7 - bit_counter];
                end else if (bit_counter < 32) begin
                    // Send SPI address
                    o_SPI_MOSI <= spi_address[31 - bit_counter];
                end else if (bit_counter < 40) begin
                    // Receive SPI data
                    spi_data[7 - (bit_counter - 32)] <= i_SPI_MISO;
                end

                bit_counter <= bit_counter + 1;

                if (bit_counter == 40) begin
                    // End SPI transaction
                    o_SPI_CS <= 1'b1;  // Deactivate chip select
                    spi_active <= 1'b0;
                    o_DATA <= spi_data;  // Output received data
                end
            end
        end
    end

endmodule
