module top (
    // External I/O ports
    inout [7:0] data_bus,    // 8-bit bidirectional data bus
    input [15:0] address_bus,// 16-bit address bus
    input r_w,               // Read/Write control signal
    input e,                 // Enable signal from 6809
    input q,                 // Phase signal from 6809
	input ba,
	input bs,
    output sram_we,          // SRAM Write Enable
	output sram_re,		//SRAM Read Enable
	output sram_ce,		// SRAM Chip enable active low
	output sram_ce2,		// SRAM Chip Enable active high
	output halt,
	output reset,
	output firq,
	output irq,
	output control2_oe,
	output control1_oe,
	output dbus_oe,
	output abus_oe,
	output dben,
	output dma,
	output mrdy
	
	

    // FT2232 Interface
    input usb_clk,           // FT2232 Clock
    inout usb_data           // FT2232 Data lines
);

    // Internal signals
    wire sram_selected;
    wire flash_selected;
	wire clk_internal;
	
	   // Instantiate the internal oscillator
    OSCH #(
        .NOM_FREQ("12.00") // Nominal frequency: "3.3", "12.0", or "133.0" MHz
    ) internal_oscillator (
        .STDBY(1'b0),  // Standby control (active-low)
        .OSC(clk_internal), // Oscillator output
        .SEDSTDBY()         // Status (unused here)
    );

	
	

    // Instantiate the Address Decoder
    address_decoder addr_dec (
        .address_bus(address_bus),
        .sram_selected(sram_selected),
        .flash_selected(flash_selected)
    );

    // Instantiate the Memory Controller
    memory_controller mem_ctrl (
        .clk(clk),
        .reset_n(reset_n),
        .r_w(r_w),
        .sram_we(sram_we),
        .sram_oe(sram_oe),
        .sram_addr(sram_addr),
        .sram_data(sram_data),
        .sram_selected(sram_selected),
        .flash_selected(flash_selected)
    );

    // Add additional submodules as needed
endmodule
