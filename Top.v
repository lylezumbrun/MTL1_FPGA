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

input	 i_Q,		// Phase signal from 6809
input	 i_BA,		// used to indicate that the buses (address and data) and the read/write output are in the high-impedance state
input	 i_BS,		// indicates whether the CPU is currently actively using the system bus
output	 o_HALT,	// Assert HALT active low signal to 6809
output	 o_FIRQ,	// Assert a fast interrupt to 6809
output	 o_DMA,		// Assert low to suspend program execution and make the buses available for another use such as a direct memory access or a dynamic memory refresh.
output   o_UART_RTS,
input	 i_UART_CTS,
output	 o_DBEN,	// Assert low to force 6809 disconnect from databus to high impedance state
*/
module top (
    // MTL1 6809 interface
    inout [7:0]	 DATA_BUS,	// 8-bit bidirectional data bus
    output [7:0] DATA_BUS_TEST,	// 8-bit bidirectional data bus
    input [15:0] i_ADDRESS_BUS,	// 16-bit address bus
    input	 i_RW,		// Read/Write control signal from 6809
    input    i_E,       // E clock signal from 6809
    output	 o_WE,		// SRAM Write Enable
    output	 o_RE,		//SRAM Read Enable
    output	 o_CE,		// SRAM Chip enable active low
    output	 o_CE2,		// SRAM Chip Enable active high
    input	 i_RESET,	// RESET signal
    output	 o_IRQ,		// Assert a interrupt to 6809
    output	 o_CONTROL2_OE,	// Enable Bidirectional Voltage-Level Translator for IRQ, FIRQ, RESET, HALT Signals
    output	 o_CONTROL1_OE,	// Enable Bidirectional Voltage-Level Translator for DBEN, Q, BS, MRDY, DMA, R/W, E, BA
    output	 o_DBUS_OE,	// Enable Bidirectional Voltage-Level Translator for Data bus
    output	 o_ABUS_OE,	// Enable Bidirectional Voltage-Level Translator Address Bus
    output	 o_MRDY,	// driving MRDY low indicates that "memory is not ready". The 6809 will then stretch the E and Q clocks by multiples of a quarter period. If a peripheral needs to be accessed that happens to be slow, the CPU effectively stalls until the peripheral is ready
    output   o_DBEN,
    output	 o_HALT,	// Assert HALT active low signal to 6809
    // FT2232 SPI Interface used to write a ROM file to flash connected to FPGA
    input	 i_FT_SCK,	// SPI Clock from FT2232
    input	 i_FT_MOSI,	// Master Out, Slave In (FT2232 to FPGA)
    output	 o_FT_MISO,	// Master In, Slave Out (FPGA to FT2232)
    input	 i_FT_CS,	// Chip Select from FT2232 to indicate that flash programming is in operation.
  
    // FT2232 UART Interface for 6809 to read and write to a terminal
    output	 o_UART_RX, 
    input	 i_UART_TX,

    // FLASH SPI Interface for 6809 ROM
    output	 o_SPI_CLK,
    output	 o_SPI_MOSI,
    output	 o_SPI_CS,
    input	 i_SPI_MISO,

    output	 o_SPI_CLK_M,
    output	 o_SPI_MOSI_M,
    output	 o_SPI_CS_M,
    output	 i_SPI_MISO_M,
    output   o_SPI_CE,
    output   o_RW,
    output   o_E
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
    wire memory_ready;
    wire halt;
	wire [7:0] spi_data;
    wire [7:0] uart_txdata;
    wire [7:0] uart_rxdata;
    wire [7:0] uart_status;
    wire [7:0] input_uart_control;
    wire [7:0] output_uart_control;
    wire clk_100mhz;
    wire clk_8mhz;
    wire pll_locked;
    wire E_LongDelay;
    wire E_ShortDelay;

	   // Instantiate the internal oscillator
    OSCH #(
        .NOM_FREQ("133.00") 
    ) internal_oscillator (
        .STDBY(1'b0),  // Standby control (active-low) used to enable the oscillator. Here it is set to always on.
        .OSC(clk_internal), // Oscillator output
        .SEDSTDBY()         // Status (unused here)
    );

     Clock_PLL clock_gen (
        .CLKI(clk_internal),
        .CLKOP(clk_100mhz),
        .CLKOS(clk_8mhz),
        .LOCK(pll_locked)
    );
    // Address Decoder -  SRAM range: 0x0000 to 0x0FFF (4KB),  SPI flash 0xF000 to 0xFFFF
    // Instantiate the address decoder, this decodes the addresses and activates either the sram_ce or spi_cs. 
    
    e_clk_delay E_ClockDelay (
        .i_clk(clk_100mhz),
        .i_e_clk(i_E),
        .i_reset(i_RESET),
        .o_e_longdelay(E_LongDelay),
        .o_e_shortdelay(E_ShortDelay)
    );
    
    address_decoder addr_dec (
        .i_FT_CS(i_FT_CS),
        .i_reset(i_RESET),
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
        .i_enable(E_LongDelay),
        .o_WE(o_WE),
        .o_RE(o_RE),
        .o_CE(o_CE),
        .o_CE2(o_CE2)
    );

    // SPI Master for Flash (activated by spi_ce)
    // SPI Flash Controller
    spi_flash_controller spi_ctrl (
        .spi_ce(spi_ce),
        .reset(i_RESET),
        .i_enable(E_LongDelay),
        .i_ADDRESS_BUS(i_ADDRESS_BUS),
        .i_DataBus(DATA_BUS),
        .i_RW(i_RW),
        .clk(clk_8mhz),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(spi_clk_ctrl),
        .o_SPI_MOSI(spi_mosi_ctrl),
        .o_SPI_CS(spi_cs_ctrl),
        .o_spi_data(spi_data),
        .o_MemoryReady(memory_ready),
        .o_HALT(halt)
    );

    spi_flash_writer spi_writer (
        .i_FT_CS(i_FT_CS),
        .i_FT_SCK(i_FT_SCK),	// SPI Clock from FT2232
        .i_FT_MOSI(i_FT_MOSI),	// Master Out, Slave In (FT2232 to FPGA)
    	.o_FT_MISO(o_FT_MISO),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(spi_clk_writer),
        .o_SPI_MOSI(spi_mosi_writer),
        .o_SPI_CS(spi_cs_writer)
    );

    uart_interface uart(
        .i_RW(i_RW),
        .i_uart_data_ce(uart_data_ce),
        .i_uart_control_ce(uart_control_ce),
        .clk(clk_8mhz),
        .reset(i_RESET),
        .i_UART_TX(i_UART_TX),
        .i_control(input_uart_control),
        .i_uart_rxdata(uart_rxdata),
        .o_UART_RX(o_UART_RX),
        .o_uart_txdata(uart_txdata),
        .o_uart_status(uart_status),
        .o_control(output_uart_control),
        .o_IRQ(o_IRQ)
    );


    // Enable Bidirectional Voltage-Level Translators
    assign o_CONTROL2_OE = 1'b1; 
    assign o_CONTROL1_OE = 1'b1;
    assign o_ABUS_OE = 1'b1;
    assign o_DBUS_OE = 1'b1;


    assign DATA_BUS_TEST = DATA_BUS;
    assign o_SPI_CLK_M = spi_clk_ctrl;
    assign o_SPI_MOSI_M = spi_mosi_ctrl;
    assign o_SPI_CS_M = spi_cs_ctrl;
    assign i_SPI_MISO_M = i_SPI_MISO;

    assign o_RW = i_RW;
    assign o_SPI_CE = spi_ce;
    assign o_E = E_LongDelay;


    // Data Bus Handling
    assign DATA_BUS = (spi_ce && i_RW) ? spi_data : 8'bz;
    assign DATA_BUS = (uart_data_ce && i_RW) ? uart_txdata : 8'bz;
    assign uart_rxdata = (uart_data_ce && !i_RW) ? DATA_BUS : 8'bz;
    assign DATA_BUS = (uart_status_ce && i_RW) ? uart_status : 8'bz;
    assign input_uart_control = (uart_control_ce && !i_RW) ? DATA_BUS : 8'bz;
    assign DATA_BUS = (uart_control_ce && i_RW) ? output_uart_control : 8'bz;
    assign o_MRDY =  memory_ready; 
    
    assign o_DBEN = (spi_ce && memory_ready && i_RW || spi_ce && E_ShortDelay && !i_RW  || uart_control_ce || sram_ce && E_ShortDelay) ? 1'b0 : 1'b1;
    
    assign o_HALT = halt;
  
    // Multiplexer to choose the active SPI clock driver
    assign o_SPI_CLK = i_FT_CS ? spi_clk_ctrl : spi_clk_writer;
    assign o_SPI_MOSI = i_FT_CS ? spi_mosi_ctrl : spi_mosi_writer;
    assign o_SPI_CS = i_FT_CS ? spi_cs_ctrl : spi_cs_writer;


endmodule
