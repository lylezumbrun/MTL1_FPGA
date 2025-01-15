module top (
    // MTL1 6809 interface
    inout [7:0] DATA_BUS,    // 8-bit bidirectional data bus
    input [15:0] i_ADDRESS_BUS,// 16-bit address bus
    input i_RW,               // Read/Write control signal from 6809
    input i_E,                 // Enable signal from 6809
    input i_Q,                 // Phase signal from 6809
	input i_BA,  // used to indicate that the buses (address and data) and the read/write output are in the high-impedance state
	input i_BS,  // indicates whether the CPU is currently actively using the system bus
    output o_WE,          // SRAM Write Enable
	output o_RE,		//SRAM Read Enable
	output o_CE,		// SRAM Chip enable active low
	output o_CE2,		// SRAM Chip Enable active high
    output o_HALT,    // Assert HALT signal to 6809
    output o_RESET,   // Assert RESET signal to 6809
	output o_FIRQ,    // Assert a fast interrupt to 6809
	output o_IRQ,   // Assert a interrupt to 6809
	output o_CONTROL2_OE, // Enable Bidirectional Voltage-Level Translator for IRQ, FIRQ, RESET, HALT Signals
	output o_CONTROL1_OE, // Enable Bidirectional Voltage-Level Translator for DBEN, Q, BS, MRDY, DMA, R/W, E, BA
	output o_DBUS_OE, // Enable Bidirectional Voltage-Level Translator for Data bus
	output o_ABUS_OE, // Enable Bidirectional Voltage-Level Translator Address Bus
	output o_DBEN, // Assert low to force 6809 disconnect from databus to high impedance state
	output o_DMA, // Assert low to suspend program execution and make the buses available for another use such as a direct memory access or a dynamic memory refresh.
	output o_MRDY, // driving MRDY low indicates that "memory is not ready". The 6809 will then stretch the E and Q clocks by multiples of a quarter period. If a peripheral needs to be accessed that happens to be slow, the CPU effectively stalls until the peripheral is ready
    // FT2232 SPI Interface used to write a ROM file to flash connected to FPGA
    input i_FT_SCK,         // SPI Clock from FT2232
    input i_FT_MOSI,        // Master Out, Slave In (FT2232 to FPGA)
    output o_FT_MISO,       // Master In, Slave Out (FPGA to FT2232)
    input i_FT_CS,         // Chip Select from FT2232
    // FT2232 UART Interface for 6809 to read and write to a terminal
    output o_UART_RX, 
    input i_UART_TX,
    output o_UART_RTS,
    output i_UART_CTS,
    // FLASH SPI Interface for 6809 ROM
    output o_SPI_CLK,
    output o_SPI_MOSI,
    output o_SPI_CS,
    input i_SPI_MISO


);

	wire clk_internal;
	
	   // Instantiate the internal oscillator
    OSCH #(
        .NOM_FREQ("133.0") // Nominal frequency: "3.3", "12.0", or "133.0" MHz
    ) internal_oscillator (
        .STDBY(1'b0),  // Standby control (active-low)
        .OSC(clk_internal), // Oscillator output
        .SEDSTDBY()         // Status (unused here)
    );

    // Instantiate the address decoder
    address_decoder addr_dec (
        .address(i_ADDRESS_BUS),
        .sram_ce(sram_ce),
        .spi_cs(spi_cs)
    );

    // SRAM Controller (activated by sram_ce)
    sram_controller sram_ctrl (
        .address(i_ADDRESS_BUS),
        .rw(i_RW),
        .enable(i_E),
        .q(i_Q),
        .we(o_WE),
        .re(o_RE),
        .ce(o_CE),
        .ce2(o_CE2)
    );

    // SPI Master for Flash (activated by spi_cs)
    spi_master flash_spi (
        .clk(clk_internal),
        .mosi(o_SPI_MOSI),
        .miso(i_SPI_MISO),
        .sck(o_SPI_CLK),
        .cs(o_SPI_CS)
    );


    // Add additional submodules as needed
endmodule
