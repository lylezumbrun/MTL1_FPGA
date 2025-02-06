`timescale 1us / 1us

module tb_address_decoder;

    // Inputs
    reg i_FT_CS;
    reg [15:0] address;

    // Outputs
    wire sram_ce;
    wire spi_ce;
    wire uart_data_ce;
    wire uart_status_ce;
    wire uart_control_ce;

    // Instantiate the module under test
    address_decoder uut (
        .i_FT_CS(i_FT_CS),
        .address(address),
        .sram_ce(sram_ce),
        .spi_ce(spi_ce),
        .uart_data_ce(uart_data_ce),
        .uart_status_ce(uart_status_ce),
        .uart_control_ce(uart_control_ce)
    );

    // Initialize all values and apply stimulus
    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars;
        // Initialize inputs
        i_FT_CS = 1'b1;
        address = 16'h0000;

        // Monitor outputs
        $monitor("Time = %0t, Address = %h, SRAM CE = %b, SPI CE = %b, UART Data CE = %b, UART Status CE = %b, UART Control CE = %b", 
                 $time, address, sram_ce, spi_ce, uart_data_ce, uart_status_ce, uart_control_ce);

        // Test 1: Check SRAM range
        address = 16'h0000;  // SRAM start address
        #10;  // Wait for 10 time units
        address = 16'h0FFF;  // SRAM end address
        #10;

        // Test 2: Check SPI Flash range with FT_CS high (inactive)
        i_FT_CS = 1'b1;
        address = 16'hF000;  // SPI Flash start address
        #10;
        address = 16'hFFFF;  // SPI Flash end address
        #10;

        // Test 3: Check SPI Flash range with FT_CS low (active)
        i_FT_CS = 1'b0;
        address = 16'hF000;  // SPI Flash start address
        #10;
        address = 16'hFFFF;  // SPI Flash end address
        #10;

        // Test 4: Check UART Data register
        address = 16'hA000;  // UART Data register address
        #10;

        // Test 5: Check UART Status register
        address = 16'hA001;  // UART Status register address
        #10;

        // Test 6: Check UART Control register
        address = 16'hA002;  // UART Control register address
        #10;

        // Test 7: Check address outside all ranges (no chip enables active)
        address = 16'h1234;  // Out of range address
        #10;

        // End of test
        $finish;

    end

endmodule

