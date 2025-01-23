module uart_interface (
    input uart_data_ce,         // Chip enable for UART data register
    input uart_status_ce,       // Chip enable for UART status register
    input i_RW,                 // Read/Write signal (1 = read, 0 = write)
    input [7:0] i_DATA_BUS,     // Data bus for 6809
    input clk,                  // System clock (44.33 MHz)
    input reset,                // System reset
    input i_UART_TX,            // FT2232 TX line (serial data from host)
    output reg o_UART_RX = 1'b1, // FT2232 RX line (serial data to host)
    output reg [7:0] o_DATA = 8'b0, // Data output to 6809
    output reg o_IRQ = 1'b0      // Interrupt signal to 6809
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
                            data_ready <= 1'b1; // Mark data ready
                            o_IRQ <= 1'b1;      // Trigger interrupt
                        end
                    end
                end
            endcase
        end
    end

    // 6809 Interface Logic
    always @(posedge clk) begin
        if (reset) begin
            o_DATA <= 8'b0;
            o_IRQ <= 1'b0;
        end else begin
            if (uart_data_ce && i_RW) begin
                // Read UART Data Register
                o_DATA <= uart_rx_data;
                data_ready <= 1'b0; // Clear data ready flag after read
                o_IRQ <= 1'b0;      // Clear interrupt
            end else if (uart_status_ce && i_RW) begin
                // Read UART Status Register
                o_DATA <= {7'b0, data_ready}; // Status: Bit 0 = data ready
            end else if (uart_data_ce && !i_RW) begin
                // Write to UART Data Register (transmit)
                o_UART_RX <= i_DATA_BUS[0]; // Only sending the first bit for now
            end
        end
    end
endmodule
