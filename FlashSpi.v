module spi_flash_master (
    input clk,               // Clock signal from internal oscillator
    input [7:0] data_in,     // Data input from 6809 to write to SPI flash (if needed)
    input cs,                // Chip select for SPI Flash (from address decoder)
    input rw,                // Read/Write control signal (from 6809)
    output reg [7:0] data_out,  // Data to output to 6809 (from SPI flash)
    output reg sck,          // SPI clock signal to Flash
    output reg mosi,         // SPI Master Out Slave In (FPGA to Flash)
    input miso,              // SPI Master In Slave Out (Flash to FPGA)
    output reg flash_cs      // Chip select for Flash
);

    reg [2:0] bit_count;    // Counter for the 8-bit transfer
    reg [7:0] shift_reg;    // Register for shifting data during SPI transfer
    reg reading;            // Flag to indicate if we are reading from the flash

    always @(posedge clk) begin
        if (cs) begin  // Only act when chip select is active
            if (rw) begin  // Read cycle (6809 wants to read from SPI Flash)
                reading <= 1;
                bit_count <= 3'b000;
                shift_reg <= 8'b0;
                flash_cs <= 0;  // Activate chip select
            end else begin  // Write cycle (6809 wants to write to SPI Flash)
                reading <= 0;
                flash_cs <= 0;  // Activate chip select
            end
        end else begin
            flash_cs <= 1; // Deactivate chip select
        end
    end

    always @(posedge clk) begin
        if (reading) begin
            sck <= ~sck;  // Toggle SPI clock
            if (bit_count < 8) begin
                shift_reg <= {shift_reg[6:0], miso};  // Shift in the MISO bit
                bit_count <= bit_count + 1;
            end else if (bit_count == 8) begin
                data_out <= shift_reg;  // Once 8 bits are received, output data
            end
        end
    end
endmodule
