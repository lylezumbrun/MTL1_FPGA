module uart_interface (
    input clk,                  // System clock (44.33 MHz)
    input reset,                // System reset
    input i_UART_TX,            // FT2232 TX line (serial data from host)
    input [7:0] i_control, // Control register 
    input [7:0] i_uart_rxdata,

    output reg o_UART_RX = 1'b1, // FT2232 RX line (serial data to host)
    output reg [7:0] o_uart_txdata, // Data output to 6809
    output reg [7:0] o_uart_status, // Uart Status Register
    output reg o_IRQ = 1'b1      // Active-low interrupt signal to 6809
);

    // Parameters
    parameter CLOCK_DIVISOR = 4618; // Divisor for 9600 bps with 44.33 MHz clock
    parameter IDLE = 1'b0, RECEIVE = 1'b1; // UART RX states

    // Internal Signals
    reg [12:0] counter = 0;     // Baud rate counter
    reg baud_clk = 0;           // Baud rate clock
    reg [3:0] bit_counter = 0;  // Bit counter for RX
    reg [7:0] uart_rx_data = 8'b0; // Data received from FT2232
    reg rx_state = IDLE;        // UART RX state
    reg rx_start = 1'b0;        // RX start bit detected
    reg data_ready = 1'b0;      // Data ready flag
   
    reg irq_flag = 1'b1;        // Internal interrupt flag (active-low)

    // Baud Rate Generator
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            baud_clk <= 0;
        end else begin
            if (counter == (CLOCK_DIVISOR - 1)) begin
                counter <= 0;
                baud_clk <= ~baud_clk; // Toggle the baud clock
            end else begin
                counter <= counter + 1;
            end
        end
    end

    // UART RX Process
    always @(posedge baud_clk or posedge reset) begin
        if (reset) begin
            rx_state <= IDLE;
            bit_counter <= 0;
            uart_rx_data <= 8'b0;
            rx_start <= 1'b0;
            data_ready <= 1'b0;
            irq_flag <= 1'b1; // Interrupt inactive
        end else begin
            case (rx_state)
                IDLE: begin
                    if (!i_UART_TX) begin // Start bit detected (low)
                        rx_state <= RECEIVE;
                        rx_start <= 1'b1;
                        bit_counter <= 0;
                    end
                end
                RECEIVE: begin
                    if (rx_start) begin
                        uart_rx_data[bit_counter] <= i_UART_TX; // Shift in RX data bits
                        bit_counter <= bit_counter + 1;
                        if (bit_counter == 7) begin // All 8 data bits received
                            rx_state <= IDLE;
                            o_uart_status <= {7'b0, data_ready}; // Status: Bit 0 = data ready / Mark data ready
                            irq_flag <= 1'b0;    // Set interrupt flag (active-low)
                        end
                    end
                end
            endcase
        end
    end


    // Assign the IRQ output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            o_IRQ <= 1'b1; // Interrupt inactive (default high)
        end else begin
            o_IRQ <= irq_flag; // Follow the internal interrupt flag
        end
    end
endmodule
