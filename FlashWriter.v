module spi_flash_writer (
    input clk,                // Clock input (from FPGA oscillator)
    input [7:0] data_in,      // Data to be written from FT2232 (to SPI flash)
    input cs,                 // Chip Select from FT2232
    input [23:0] flash_addr,  // Address to write to in the SPI flash
    input write_enable,       // Enable signal to start writing (e.g., from FT2232)
    output reg flash_cs,      // Chip select for SPI flash
    output reg spi_clk,       // SPI Clock for SPI flash
    output reg spi_mosi,      // SPI Master Out Slave In (to SPI flash)
    input spi_miso            // SPI Master In Slave Out (from SPI flash)
);

    reg [7:0] shift_reg;      // Buffer to store data to write to SPI Flash
    reg [3:0] bit_count;      // Bit counter for the SPI data transfer
    reg write_in_progress;    // Flag indicating if the write operation is in progress

    // Write enable (WREN) command for SPI flash
    wire [7:0] WREN = 8'h06;  // SPI Write Enable command

    // Page Program (Write) command for SPI flash
    wire [7:0] WRITE_CMD = 8'h02;  // SPI Write command

    // State machine to manage the write process
    always @(posedge clk) begin
        if (cs && write_enable) begin
            if (!write_in_progress) begin
                // Start the write process: send Write Enable (WREN) command first
                flash_cs <= 0;  // Activate chip select
                spi_clk <= 0;   // Start SPI clock
                shift_reg <= WREN;  // Load Write Enable command
                bit_count <= 0;  // Start the SPI transfer
                write_in_progress <= 1;  // Set flag to indicate write is in progress
            end
        end
    end

    // Send the Write Enable (WREN) command
    always @(posedge clk) begin
        if (write_in_progress && bit_count < 8) begin
            spi_clk <= ~spi_clk;  // Toggle SPI clock
            if (spi_clk) begin
                spi_mosi <= shift_reg[7];  // Send the MSB of the command
                shift_reg <= {shift_reg[6:0], 1'b0};  // Shift the command
                bit_count <= bit_count + 1;  // Increment bit counter
            end
        end else if (bit_count == 8) begin
            // Once WREN command is sent, we proceed to page programming
            shift_reg <= {WRITE_CMD, flash_addr};  // Send Write command with address
            bit_count <= 0;  // Reset counter for next transfer
        end
    end

    // Additional state to manage programming data to SPI flash
    always @(posedge clk) begin
        if (write_in_progress && bit_count < 8) begin
            spi_clk <= ~spi_clk;  // Toggle SPI clock
            if (spi_clk) begin
                spi_mosi <= shift_reg[7];  // Send the next bit of data
                shift_reg <= {shift_reg[6:0], 1'b0};  // Shift data
                bit_count <= bit_count + 1;  // Increment bit counter
            end
        end else if (bit_count == 8) begin
            // End the write operation once the byte is written
            write_in_progress <= 0;  // Clear write flag
            flash_cs <= 1;  // Deactivate chip select
        end
    end
endmodule
