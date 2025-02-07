`timescale 1us / 1us
module tb_spi_flash_controller;

    reg spi_ce;
    reg [15:0] i_ADDRESS_BUS;
    reg i_RW;
    reg clk;
    reg i_SPI_MISO;
    wire o_SPI_CLK;
    wire o_SPI_MOSI;
    wire o_SPI_CS;
    wire [7:0] o_DATA;

    // Instantiate the Unit Under Test (UUT)
    spi_flash_controller uut (
        .spi_ce(spi_ce),
        .i_ADDRESS_BUS(i_ADDRESS_BUS),
        .i_RW(i_RW),
        .clk(clk),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(o_SPI_CLK),
        .o_SPI_MOSI(o_SPI_MOSI),
        .o_SPI_CS(o_SPI_CS),
        .o_DATA(o_DATA)
    );

    // Clock generation at 44.33 MHz
    localparam CLOCK_PERIOD_NS = 22.57; // 44.33 MHz -> 1 / 44.33e6 seconds
    initial clk = 0;
    always #(CLOCK_PERIOD_NS / 2) clk = ~clk;

    // Simulation task for SPI flash read operation
    task spi_flash_read(input [15:0] address);
        begin
            spi_ce = 1;
            i_RW = 1;
            i_ADDRESS_BUS = address;
            #1000;  // Wait for SPI operation to begin

            spi_ce = 0;
            i_RW = 0;
            #100;  // Return to idle state after operation
        end
    endtask

    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0, tb_spi_flash_controller);

        // Initialize Inputs
        spi_ce = 0;
        i_ADDRESS_BUS = 16'h0000;
        i_RW = 0;
        i_SPI_MISO = 0;

        // Reset SPI Controller signals
        #100;

        // Stimulate SPI flash read for address 0x1234
        spi_flash_read(16'hffff);

        // Simulate some dummy MISO responses
        #50 i_SPI_MISO = 1;
        #50 i_SPI_MISO = 0;
        #50 i_SPI_MISO = 1;

        // Complete simulation
        #500;
        $display("Final SPI Data Received: %h", o_DATA);
        $finish;
    end
endmodule
