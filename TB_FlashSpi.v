`timescale 1ns / 1ns
module tb_spi_flash_controller;

    reg spi_ce;
    reg reset;
    reg [15:0] i_ADDRESS_BUS;
    reg [7:0] i_DataBus;
    reg i_RW;
    reg clk;
    reg i_SPI_MISO;
    reg i_enable; // Change from wire to reg
    wire o_SPI_CLK;
    wire o_SPI_MOSI;
    wire o_SPI_CS;
    wire [7:0] o_DATA;
    wire o_MemoryReady;
    wire o_HALT;

    // Instantiate the Unit Under Test (UUT)
    spi_flash_controller uut (
        .spi_ce(spi_ce),
        .reset(reset),
        .i_enable(i_enable),
        .i_ADDRESS_BUS(i_ADDRESS_BUS),
        .i_DataBus(i_DataBus),
        .i_RW(i_RW),
        .clk(clk),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(o_SPI_CLK),
        .o_SPI_MOSI(o_SPI_MOSI),
        .o_SPI_CS(o_SPI_CS),
        .o_spi_data(o_DATA),
        .o_MemoryReady(o_MemoryReady),
        .o_HALT(o_HALT)
    );

    // Clock generation at 88.67 MHz 
    localparam CLOCK_PERIOD_NS = 11.285; // 88.67 MHz 
    initial clk = 0;
    initial i_enable = 0;
    always #(CLOCK_PERIOD_NS / 2) clk = ~clk;
    always #(CLOCK_PERIOD_NS) i_enable = ~i_enable;

    // Simulation task for SPI flash read operation
    task spi_flash_read(input [15:0] address);
        begin
            #24;
            spi_ce = 1;
            i_ADDRESS_BUS = address;
            i_RW = 1;  // Read operation   
            #24       
            spi_ce = 0;
            #774;  // Wait for SPI operation to begin
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 0;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 0;
        end
    endtask
    task spi_flash_reread(input [15:0] address);
    begin
            spi_ce = 1;
            i_ADDRESS_BUS = address;
            i_RW = 1;  // Read operation
            #24
            spi_ce = 0;   
            #774;  // Wait for SPI operation to begin
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 0;
            #24 i_SPI_MISO = 1;
            #24 i_SPI_MISO = 0;
        end
    endtask
    // Simulation task for SPI flash read operation
    task spi_flash_write(input [15:0] address, input [7:0] databus);
        begin
            #24;
            #24;
            #24;
            #24;
            #24;
            #24;
            i_RW = 0;
            spi_ce = 1;
            #24;
            i_ADDRESS_BUS = address;
            i_DataBus = databus;
            spi_ce = 0;
            i_RW = 1;
        end
    endtask

    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0, tb_spi_flash_controller);
        //Initialize Inputs
        spi_ce = 0;
        i_ADDRESS_BUS = 16'h0000;
        i_RW = 1;
        reset = 1;
        #10;
        reset = 0;
        #10;
        reset = 1;
        i_DataBus = 8'h00; // Default value to prevent high-Z
        //Reset SPI Controller signals
        #100;
        //Stimulate SPI flash read for address 0x1234
        spi_flash_read(16'h3AAA);
        #100;  // Return to idle state after operation
        $display("Final SPI Data Received: %h", o_DATA);
        //Initialize Inputs
        spi_flash_write(16'h3000, 8'hAA);
        #1000;  // Wait for SPI operation to begin
        spi_flash_reread(16'h3AAA);
        #2550;  // Wait for SPI operation to begin
        $finish;
    end
endmodule
