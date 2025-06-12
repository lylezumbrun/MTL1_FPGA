// SPI device uses SPI Mode 0, with active low Chip Select
// Max speed rating of SPI Flash with read instruction is 50MHz. 
module spi_flash_controller (
    input spi_ce,            // SPI chip select signal from address decoder
    input reset,             // Reset signal
    input i_enable,
    input [15:0] i_ADDRESS_BUS, // Address from 6809 (16 bits)
    input [7:0] i_DataBus,  // Data input from 6809
    input i_RW,               // Read/Write control signal (only reads for flash)
    input clk,                // System clock
    input i_SPI_MISO,         // SPI Master In Slave Out
    output reg o_SPI_CLK,     // SPI Clock
    output reg o_SPI_MOSI,    // SPI Master Out Slave In
    output reg o_SPI_CS,      // SPI Chip Select (active low)
    output reg [7:0] o_spi_data,  // Data output to 6809
    output reg o_MemoryReady,
    output reg o_HALT,
    output reg [7:0] spi_datawrite          // Data to write to SPI flash
);

    wire [7:0] spi_read_command = 8'h03; // Command for SPI flash (READ command is 0x03)
    wire [7:0] spi_page_command = 8'h02; // Command for SPI flash (WRITE PAGE command is 0x02)
    wire [7:0] spi_write_enable_command = 8'h06; // Command for SPI flash (WRITE ENABLE command is 0x06)
    reg [23:0] spi_readaddress = 24'b0; // Address for SPI flash (24 bits)
    reg [23:0] spi_writeaddress = 24'b0; // Address for SPI flash (24 bits)
    reg [5:0] read_bit_counter = 6'd0;     // Tracks SPI transaction progress (6 bits to cover up to 40)
    reg [5:0] write_bit_counter = 6'd0;     // Tracks SPI transaction progress (6 bits to cover up to 40)
    reg [15:0] writedelay_counter = 0;
    reg spi_read_active = 0;               // Indicates SPI read operation is active
    reg spi_write_active = 0;               // Indicates SPI write enable operation is active
    reg start_write_delay = 0;
    reg spi_page_active = 0;               // Indicates SPI page operation is active
    reg read_clock_delay = 0;
    reg write_clock_delay = 0;
    reg start_write = 0;
    reg start_read = 0;
    // SPI flash controller logic
    // Reset logic

    always @(negedge i_enable) begin
        if (!i_RW && spi_ce) begin
            spi_writeaddress <= {12'b0, i_ADDRESS_BUS[11:0]}; // Lower 12 bits of address to 24-bit SPI address
            start_write <= 1'b1;
            spi_datawrite <= i_DataBus;
        end
        else begin
            start_write <= 1'b0;
        end
    end

    always @(posedge i_enable) begin
        if (i_RW && spi_ce) begin
            spi_readaddress <= {12'b0, i_ADDRESS_BUS[11:0]}; // Lower 12 bits of address to 24-bit SPI address
            start_read <= 1'b1;
        end
        else begin
            start_read <= 1'b0;
        end
    end


    always @(posedge clk) begin
        if (~reset) begin
            o_spi_data <= 8'b0;          // Reset data
            read_bit_counter <= 6'b0;       // Reset bit counter
            write_bit_counter <= 6'b0;       // Reset bit counter
            spi_read_active <= 1'b0;        // Reset SPI read active flag
            spi_write_active <= 1'b0;        // Reset SPI write active flag
            spi_page_active <= 1'b0;        // Reset SPI page active flag
            o_MemoryReady <= 1'b1;    // Allow the 6809 to continue
            o_HALT <= 1'b1;         // Deactivate HALT signal
        end

        // Start SPI transaction when chip select is active and it's a read cycle
        if (start_read && !spi_read_active && reset) begin
            spi_read_active <= 1'b1;         // Mark SPI as active
            read_bit_counter <= 6'd0;        // Reset bit counter
            read_clock_delay <= 1'b0;
       end
       if (start_write && !spi_write_active && !spi_page_active && reset) begin
            spi_write_active <= 1'b1;         // Mark write enable as active
            spi_page_active <= 1'b0;         // Mark page as inactive
            write_bit_counter <= 6'd0;        // Reset bit counter
            write_clock_delay <= 1'b0;
        end

        
        // Read data from SPI flash
        if (spi_read_active && reset) begin
            if(spi_write_active || start_write_delay) begin
               o_HALT <= 1'b0;         // Activate HALT signal
            end
            else begin
                o_HALT <= 1'b1;         // Deactivate HALT signal
                o_SPI_CS <= 1'b0;           // Activate SPI chip select
                o_MemoryReady <= 1'b0;     // Keep 6809 in wait state during SPI transaction

                if (read_clock_delay) begin 
                    o_SPI_CLK = ~o_SPI_CLK;   // Toggle SPI clock
                end
                read_clock_delay <= 1'b1;

                if (~o_SPI_CLK) begin
                    // On rising edge of SPI clock, handle data transfer
                    if (read_bit_counter < 6'd8) begin //7
                        // Send SPI command (8 bits)
                        o_SPI_MOSI <= spi_read_command[7 - read_bit_counter];
                    end else if (read_bit_counter < 6'd32) begin
                        // Send 24-bit SPI address (address starts at bit 8)
                        o_SPI_MOSI <= spi_readaddress[31 - read_bit_counter];
                    end else if (read_bit_counter == 6'd40) begin
                        // End of SPI transaction
                        spi_read_active <= 1'b0;      // Mark SPI as inactive
                        o_MemoryReady <= 1'b1;     // Allow the 6809 to continue
                        read_clock_delay <= 1'b0;
                    end
                end
                else begin
                    if (read_bit_counter < 6'd40) begin
                        // Receive 8-bit data (after address)
                        o_spi_data[7 - (read_bit_counter - 6'd32)] <= i_SPI_MISO;
                    end
                    // Increment bit counter (always within 6-bit range, safe to truncate)
                    read_bit_counter <= read_bit_counter + 1;
                end
            end
        end 
        // Enable Write data to SPI flash
        if (spi_write_active && !spi_page_active && reset) begin
            o_SPI_CS <= 1'b0;           // Activate SPI chip select
            if (write_clock_delay) begin 
                o_SPI_CLK = ~o_SPI_CLK;   // Toggle SPI clock
            end
            write_clock_delay <= 1'b1;

            if (~o_SPI_CLK) begin
                // On rising edge of SPI clock, handle data transfer
                if (write_bit_counter < 6'd8) begin //7
                    // Send SPI command (8 bits)
                    o_SPI_MOSI <= spi_write_enable_command[7 - write_bit_counter];
                end  
            end
            else begin
                if (write_bit_counter == 6'd8) begin
                    // End of SPI transaction
                    spi_page_active <= 1'b1;      // Mark SPI page active
                    write_bit_counter <= 6'd0;        // Reset bit counter
                    write_clock_delay <= 1'b0;
                    o_SPI_CS <= 1'b1;           // Deactivate SPI chip select
                    o_SPI_CLK = 1'b0;         // Clock low in idle (for SPI Mode 0)
                end
                // Increment bit counter (always within 6-bit range, safe to truncate)
                else begin
                write_bit_counter <= write_bit_counter + 1;
                end
            end
        end
        // Write data to SPI flash
        if (spi_page_active && reset) begin
            o_SPI_CS <= 1'b0;           // Activate SPI chip select
           
            if (write_clock_delay) begin 
                o_SPI_CLK = ~o_SPI_CLK;   // Toggle SPI clock
            end
            write_clock_delay <= 1'b1;

            if (~o_SPI_CLK) begin
                // On rising edge of SPI clock, handle data transfer
                if (write_bit_counter < 6'd8) begin //7
                    // Send SPI command (8 bits)
                    o_SPI_MOSI <= spi_page_command[7 - write_bit_counter];
                end else if (write_bit_counter < 6'd32) begin
                    // Send 24-bit SPI address (address starts at bit 8)
                    o_SPI_MOSI <= spi_writeaddress[31 - write_bit_counter];

                end
                else if (write_bit_counter < 6'd40) begin
                // Receive 8-bit data (after address)
                o_SPI_MOSI <= spi_datawrite[7 - (write_bit_counter - 6'd32)];
                end    
                else if (write_bit_counter == 6'd40) begin
                    // End of SPI transaction
                    spi_page_active <= 1'b0;      // Mark SPI as inactive
                    spi_write_active <= 1'b0;      // Delay finished for write. 
                    writedelay_counter <= 16'd100;  // Set counter for 6ms @ 8MHz max time for write on a 25LC1024 eeprom, changed to 48000 to 100 for test.
                    start_write_delay <= 1'b1;
                end
            end
            else begin
                // Increment bit counter (always within 6-bit range, safe to truncate)
                write_bit_counter <= write_bit_counter + 1;
            end
        end 
        if(!spi_read_active && !spi_write_active || start_write_delay) begin
            // Idle state: set SPI signals to default
            o_SPI_MOSI <= 1'bz;        // High Impedance at idle
            o_SPI_CLK = 1'b0;         // Clock low in idle (for SPI Mode 0)
            o_MemoryReady <= 1'b1;     // Allow the 6809 to continue
            o_SPI_CS <= 1'b1;        // Deactivate SPI chip select
        end
        if(start_write_delay) begin
                if (writedelay_counter > 0) begin
                writedelay_counter <= writedelay_counter - 1; // count down to zero for delay
                end 
                else begin
                    start_write_delay <= 1'b0;
                end
        end
    end
endmodule
