`timescale 1ns / 1ns
module tb_spi_flash_controller;

    reg spi_ce;
    reg reset;
    reg [15:0] i_ADDRESS_BUS;
    reg i_RW;
    reg clk;
    reg i_SPI_MISO;
    wire o_SPI_CLK;
    wire o_SPI_MOSI;
    wire o_SPI_CS;
    wire [7:0] o_DATA;
    wire o_MemoryReady;

    // Instantiate the Unit Under Test (UUT)
    spi_flash_controller uut (
        .spi_ce(spi_ce),
        .reset(reset),
        .i_ADDRESS_BUS(i_ADDRESS_BUS),
        .i_RW(i_RW),
        .clk(clk),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(o_SPI_CLK),
        .o_SPI_MOSI(o_SPI_MOSI),
        .o_SPI_CS(o_SPI_CS),
        .o_DATA(o_DATA),
        .o_MemoryReady(o_MemoryReady)
    );

    // Clock generation at 88.67 MHz 
    localparam CLOCK_PERIOD_NS = 11.285; // 88.67 MHz 
    initial clk = 0;
    always #(CLOCK_PERIOD_NS / 2) clk = ~clk;

    // Simulation task for SPI flash read operation
    task spi_flash_read(input [15:0] address);
        begin
            reset = 1;
            #10;
            reset = 0;
            #10;
            reset = 1;
            #10;
            spi_ce = 1;
            i_RW = 1;
            i_ADDRESS_BUS = address;
            #882;  // Wait for SPI operation to begin
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 0;
            #24 i_SPI_MISO = 1;
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
        spi_flash_read(16'hfffd);

        $display("Final SPI Data Received: %h", o_DATA);
        $finish;
    end
endmodule
