/*
CIE Microprocessor Trainer Lab Memory Adapter
Verilog Code for LCMXO2-1200HC-4TG100C FPGA
Copyright Lyle Zumbrun 2025

MTL-1 Predefined Memory Range
-----------------------------------
SRAM range: 0x0000 to 0x0FFF (4KB)
ROM (SPI flash) 0xF000 to 0xFFFF

Optional Address area for additional I/O or memory
-----------------------------------------------
0x1000 - 0x7FFF Memory Expansion Area
0xA000 - 0xBFFF I/O Expansion Area
*/


module top (
    // MTL1 6809 interface
    inout [7:0]	 DATA_BUS,	// 8-bit bidirectional data bus
    input [15:0] i_ADDRESS_BUS,	// 16-bit address bus
    input	 i_RW,		// Read/Write control signal from 6809
    input	 i_E,		// Enable signal from 6809
 //   input	 i_Q,		// Phase signal from 6809
 //   input	 i_BA,		// used to indicate that the buses (address and data) and the read/write output are in the high-impedance state
 //   input	 i_BS,		// indicates whether the CPU is currently actively using the system bus
    output	 o_WE,		// SRAM Write Enable
    output	 o_RE,		//SRAM Read Enable
    output	 o_CE,		// SRAM Chip enable active low
    output	 o_CE2,		// SRAM Chip Enable active high
    output	 o_HALT,	// Assert HALT signal to 6809
    inout	 o_RESET,	// Assert RESET signal to 6809
    output	 o_FIRQ,	// Assert a fast interrupt to 6809
    output	 o_IRQ,		// Assert a interrupt to 6809
    output	 o_CONTROL2_OE,	// Enable Bidirectional Voltage-Level Translator for IRQ, FIRQ, RESET, HALT Signals
    output	 o_CONTROL1_OE,	// Enable Bidirectional Voltage-Level Translator for DBEN, Q, BS, MRDY, DMA, R/W, E, BA
    output	 o_DBUS_OE,	// Enable Bidirectional Voltage-Level Translator for Data bus
    output	 o_ABUS_OE,	// Enable Bidirectional Voltage-Level Translator Address Bus
    output	 o_DBEN,	// Assert low to force 6809 disconnect from databus to high impedance state
    output	 o_DMA,		// Assert low to suspend program execution and make the buses available for another use such as a direct memory access or a dynamic memory refresh.
    output	 o_MRDY,	// driving MRDY low indicates that "memory is not ready". The 6809 will then stretch the E and Q clocks by multiples of a quarter period. If a peripheral needs to be accessed that happens to be slow, the CPU effectively stalls until the peripheral is ready
    // FT2232 SPI Interface used to write a ROM file to flash connected to FPGA
    input	 i_FT_SCK,	// SPI Clock from FT2232
    input	 i_FT_MOSI,	// Master Out, Slave In (FT2232 to FPGA)
    output	 o_FT_MISO,	// Master In, Slave Out (FPGA to FT2232)
    input	 i_FT_CS,	// Chip Select from FT2232 to indicate that flash programming is in operation.
    // FT2232 UART Interface for 6809 to read and write to a terminal
    output	 o_UART_RX, 
    input	 i_UART_TX,
//  output o_UART_RTS,
//  input	 i_UART_CTS,
    
    // FLASH SPI Interface for 6809 ROM
    output	 o_SPI_CLK,
    output	 o_SPI_MOSI,
    output	 o_SPI_CS,
    input	 i_SPI_MISO
);

	wire clk_internal;
    wire sram_ce;
    wire spi_ce;
    wire uart_data_ce;
    wire uart_status_ce;
    wire uart_control_ce;

    wire spi_clk_writer;
    wire spi_mosi_writer;
    wire spi_cs_writer;

    wire spi_clk_ctrl;
    wire spi_mosi_ctrl;
    wire spi_cs_ctrl;
	wire [7:0] spi_data;
    wire [7:0] uart_txdata;
    wire [7:0] uart_rxdata;
    wire [7:0] uart_status;
    wire [7:0] uart_control;

	   // Instantiate the internal oscillator
    OSCH #(
        .NOM_FREQ("44.33") // Max speed rating of SPI Flash with read instruction is 50MHz, 44.33 is highest we can use on FPGA without a clock divider. 
    ) internal_oscillator (
        .STDBY(1'b0),  // Standby control (active-low) used to enable the oscillator. Here it is set to always on.
        .OSC(clk_internal), // Oscillator output
        .SEDSTDBY()         // Status (unused here)
    );
    // Address Decoder -  SRAM range: 0x0000 to 0x0FFF (4KB),  SPI flash 0xF000 to 0xFFFF
    // Instantiate the address decoder, this decodes the addresses and activates either the sram_ce or spi_cs. 
    address_decoder addr_dec (
        .i_FT_CS(i_FT_CS),
        .address(i_ADDRESS_BUS),
        .sram_ce(sram_ce),
        .spi_ce(spi_ce),
        .uart_data_ce(uart_data_ce),
        .uart_status_ce(uart_status_ce),
        .uart_control_ce(uart_control_ce)
    );

    // SRAM Controller (activated by sram_ce)
    sram_controller sram_ctrl (
        .sram_ce(sram_ce),
        .i_RW(i_RW),
        .i_E(i_E),
        .o_WE(o_WE),
        .o_RE(o_RE),
        .o_CE(o_CE),
        .o_CE2(o_CE2)
    );

    // SPI Master for Flash (activated by spi_ce)
    // SPI Flash Controller
    spi_flash_controller spi_ctrl (
        .spi_ce(spi_ce),
        .i_ADDRESS_BUS(i_ADDRESS_BUS),
        .i_RW(i_RW),
        .clk(clk_internal),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(spi_clk_ctrl),
        .o_SPI_MOSI(spi_mosi_ctrl),
        .o_SPI_CS(spi_cs_ctrl),
        .o_DATA(spi_data)
    );

    spi_flash_writer spi_writer (
        .i_FT_CS(i_FT_CS),
        .i_FT_SCK(i_FT_SCK),	// SPI Clock from FT2232
        .i_FT_MOSI(i_FT_MOSI),	// Master Out, Slave In (FT2232 to FPGA)
    	.o_FT_MISO(o_FT_MISO),

        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(spi_clk_writer),
        .o_SPI_MOSI(spi_mosi_writer),
        .o_SPI_CS(spi_cs_writer),

        .o_HALT(o_HALT),
        .o_RESET(o_RESET)
    );

    uart_interface uart(
        .clk(clk_internal),
        .reset(Reset),
        .i_UART_TX(i_UART_TX),
        .i_control(uart_control),
        .i_uart_rxdata(uart_rxdata),
        .o_UART_RX(o_UART_RX),
        .o_uart_txdata(uart_txdata),
        .o_uart_status(uart_status),
        .o_IRQ(o_IRQ)
    );






    // Enable Bidirectional Voltage-Level Translators
    assign o_CONTROL2_OE = 1'b1; 
    assign o_CONTROL1_OE = 1'b1;
    assign o_ABUS_OE = 1'b1;
    assign o_DBUS_OE = 1'b1;

    // Set to high impedance or disconnected state
    assign o_DBEN = 1'bz;
    assign o_DMA = 1'bz;
    assign o_MRDY = 1'bz;
    assign o_FIRQ = 1'bz;


    // Data Bus Handling
assign DATA_BUS = (spi_ce && i_RW) ? spi_data : 8'bz;
assign DATA_BUS = (uart_data_ce && i_RW) ? uart_txdata : 8'bz;
assign uart_rxdata = (uart_data_ce && !i_RW) ? DATA_BUS : 8'bz;
assign DATA_BUS = (uart_status_ce && i_RW) ? uart_status : 8'bz;
assign uart_control = (uart_control_ce && !i_RW) ? DATA_BUS : 8'bz;


  
    // Multiplexer to choose the active SPI clock driver
    assign o_SPI_CLK = i_FT_CS ? spi_clk_ctrl : spi_clk_writer;
    assign o_SPI_MOSI = i_FT_CS ? spi_mosi_ctrl : spi_mosi_writer;
    assign o_SPI_CS = i_FT_CS ? spi_cs_ctrl : spi_cs_writer;

    // Add additional submodules as needed
endmodule
