module top (
    // MTL1 6809 interface
    inout [7:0] DATA_BUS,       // 8-bit bidirectional data bus
    input [15:0] i_ADDRESS_BUS, // 16-bit address bus
    input i_RW,                 // Read/Write control signal from 6809
    input i_Q,                  // Phase signal from 6809
    input i_E,                  // Enable signal from 6809
    output o_WE,                // SRAM Write Enable
    output o_RE,                // SRAM Read Enable
    output o_CE,                // SRAM Chip enable active low
    output o_CE2,               // SRAM Chip Enable active high
    input i_RESET,              // Assert RESET signal to 6809
    output o_IRQ,               // Assert an interrupt to 6809
    output o_CONTROL2_OE,       // Enable Bidirectional Voltage-Level Translator for IRQ, FIRQ, RESET, HALT Signals
    output o_CONTROL1_OE,       // Enable Bidirectional Voltage-Level Translator for DBEN, Q, BS, MRDY, DMA, R/W, E, BA
    output o_DBUS_OE,           // Enable Bidirectional Voltage-Level Translator for Data bus
    output o_ABUS_OE,           // Enable Bidirectional Voltage-Level Translator Address Bus
    output o_MRDY,              // Memory Ready signal
    output o_DBEN,              // Data Bus Enable signal
    // FT2232 SPI Interface used to write a ROM file to flash connected to FPGA
    input i_FT_SCK,             // SPI Clock from FT2232
    input i_FT_MOSI,            // Master Out, Slave In (FT2232 to FPGA)
    output o_FT_MISO,           // Master In, Slave Out (FPGA to FT2232)
    input i_FT_CS,              // Chip Select from FT2232 to indicate that flash programming is in operation.
    // FT2232 UART Interface for 6809 to read and write to a terminal
    output o_UART_RX, 
    input i_UART_TX,
    // FLASH SPI Interface for 6809 ROM
    output o_SPI_CLK,
    output o_SPI_MOSI,
    output o_SPI_CS,
    input i_SPI_MISO
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
    wire [7:0] spi_data;
    wire [7:0] uart_txdata;
    reg [7:0] uart_rxdata; // Declare as reg
    wire [7:0] uart_status;
    reg [7:0] input_uart_control; // Declare as reg
    wire [7:0] output_uart_control;

    // Instantiate the internal oscillator
    OSCH #(
        .NOM_FREQ("13.3") // Max speed rating of SPI Flash with read instruction is 50MHz, a 88.67 clock makes a 44.33mhz SPI CLK. 
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
        .i_enable(i_E),
        .i_Q(i_Q),
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
        .i_ADDRESS_BUS(i_ADDRESS_BUS),
        .i_RW(i_RW),
        .clk(clk_internal),
        .i_SPI_MISO(i_SPI_MISO),
        .o_SPI_CLK(spi_clk_ctrl),
        .o_SPI_MOSI(spi_mosi_ctrl),
        .o_SPI_CS(spi_cs_ctrl),
        .o_DATA(spi_data),
        .o_MemoryReady(memory_ready)
    );

    spi_flash_writer spi_writer (
        .i_FT_CS(i_FT_CS),
        .i_FT_SCK(i_FT_SCK),    // SPI Clock from FT2232
        .i_FT_MOSI(i_FT_MOSI),  // Master Out, Slave In (FT2232 to FPGA)
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
        .clk(clk_internal),
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

    // Data Bus Handling with `always` blocks to avoid conflicts
    reg [7:0] data_bus_out;
    assign DATA_BUS = (i_RW && i_E) ? data_bus_out : 8'bz;

    always @(*) begin
        if (spi_ce && i_RW && i_E) begin
            data_bus_out = spi_data;
        end else if (uart_data_ce && i_RW && i_E) begin
            data_bus_out = uart_txdata;
        end else if (uart_status_ce && i_RW && i_E) begin
            data_bus_out = uart_status;
        end else if (uart_control_ce && i_RW && i_E) begin
            data_bus_out = output_uart_control;
        end else begin
            data_bus_out = 8'bz;
        end
    end

    always @(*) begin
        if (uart_data_ce && !i_RW && i_E) begin
            uart_rxdata = DATA_BUS;
        end else begin
            uart_rxdata = 8'bz;
        end
    end

    always @(*) begin
        if (uart_control_ce && !i_RW && i_E) begin
            input_uart_control = DATA_BUS;
        end else begin
            input_uart_control = 8'bz;
        end
    end

    // Multiplexer to choose the active SPI clock driver
    assign o_SPI_CLK = i_FT_CS ? spi_clk_ctrl : spi_clk_writer;
    assign o_SPI_MOSI = i_FT_CS ? spi_mosi_ctrl : spi_mosi_writer;
    assign o_SPI_CS = i_FT_CS ? spi_cs_ctrl : spi_cs_writer;

    // Memory Ready signal
    assign o_MRDY = memory_ready; // driving MRDY low indicates that "memory is not ready". The 6809 will then stretch the E and Q clocks by multiples of a quarter period. If a peripheral needs to be accessed that happens to be slow, the CPU effectively stalls until the peripheral is ready

    // Data Bus Enable signal
    assign o_DBEN = (spi_ce || uart_control_ce || sram_ce) ? 1'b0 : 1'b1;

endmodule