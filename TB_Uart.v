`timescale 1ns / 1ns
    module TB_uart;
    reg i_RW;
    reg i_uart_data_ce;
    reg i_uart_control_ce; 
    reg clk;                  // System clock (44.33 MHz)
    reg reset;                // System reset
    reg i_UART_TX;            // FT2232 TX line (serial data from host)
    reg [7:0] i_control;      // reg to Control register
    reg [7:0] i_uart_rxdata;  // Data reg from 6809

    wire o_UART_RX; // FT2232 RX line (serial data to host)
    wire [7:0] o_uart_txdata; // Data output to 6809
    wire [7:0] o_uart_status; // UART Status Register
    wire [7:0] o_control; // output the control register
    wire o_IRQ;      // Active-low interrupt signal to 6809

    // Clock generation at 88.67 MHz 
    localparam CLOCK_PERIOD_NS = 11.285; // 88.67 MHz 
    initial clk = 0;
    always #(CLOCK_PERIOD_NS / 2) clk = ~clk;


uart_interface uut(
    .i_RW(i_RW),
    .i_uart_data_ce(i_uart_data_ce),
    .i_uart_control_ce(i_uart_control_ce), 
    .clk(clk),                  // System clock (44.33 MHz)
    .reset(reset),                // System reset
    .i_UART_TX(i_UART_TX),            // FT2232 TX line (serial data from host)
    .i_control(i_control),      // .to Control register
    .i_uart_rxdata(i_uart_rxdata),  // Data .from 6809

    .o_UART_RX(o_UART_RX), // FT2232 RX line (serial data to host)
    .o_uart_txdata(o_uart_txdata), // Data output to 6809
    .o_uart_status(o_uart_status), // UART Status Register
    .o_control(o_control), // output the control register
    .o_IRQ(o_IRQ)      // Active-low interrupt signal to 6809
);

    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0, TB_uart);

        // Initialize Inputs
        i_control = 0;
        i_RW = 0;
        i_uart_control_ce = 1;
        #20;
        i_control = 2;
        #20;
        i_RW = 1;
        i_uart_data_ce = 0;
        i_uart_control_ce = 0;
        i_UART_TX = 1;

        reset = 0;
        #20;
        reset = 1;
        #20;
        reset = 0;
        #20;
        i_UART_TX = 0;
        #60;
        i_UART_TX = 1;
        #30
        i_UART_TX = 1;


       #800;
       i_uart_data_ce = 1;
       #20;
       i_uart_data_ce = 0; 
       #100;
       i_uart_rxdata = 8'h01;
       i_RW = 0;
       i_uart_data_ce = 1;
       #20;
       i_RW = 1;
       i_uart_data_ce = 0;
       #800;



 


        $display("Final Data Received: %h", o_uart_txdata);
        $finish;
    end





























endmodule