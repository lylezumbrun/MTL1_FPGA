module uart_interface (
    input clk,                  // System clock (44.33 MHz)
    input reset,                // System reset
    input i_UART_TX,            // FT2232 TX line (serial data from host)
    input [7:0] i_control,      // Control register
    input [7:0] i_uart_rxdata,  // Data input from 6809

    output reg o_UART_RX = 1'b1, // FT2232 RX line (serial data to host)
    output reg [7:0] o_uart_txdata, // Data output to 6809
    output reg [7:0] o_uart_status, // UART Status Register
    output reg o_IRQ = 1'b1      // Active-low interrupt signal to 6809
);

    // Parameters
    parameter CLOCK_DIVISOR = 4618; // Divisor for 9600 bps with 44.33 MHz clock
    localparam RXIDLE = 1'b0, RECEIVE = 1'b1; // UART RX states
    localparam TXIDLE = 1'b0, TRANSMIT = 1'b1; // UART TX states

    // Internal Signals
    reg [12:0] counter = 0;     // Baud rate counter
    reg baud_clk = 0;           // Baud rate clock
    reg [3:0] rx_bit_counter = 0;  // Bit counter for RX
    reg [3:0] tx_bit_counter = 0;  // Bit counter for TX
    reg [7:0] uart_rx_data = 8'b0; // Data received from FT2232
    reg [7:0] uart_tx_data = 8'b0; // Data to transmit
    reg rx_state = RXIDLE;      // UART RX state
    reg tx_state = TXIDLE;      // UART TX state
    reg rx_start = 1'b0;        // RX start bit detected
    reg data_ready = 1'b0;      // Data ready flag
    reg irq_flag = 1'b1;        // Internal interrupt flag (active-low)
    reg	control_tx = 8'b0;
   
   
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
            rx_state <= RXIDLE;
            rx_bit_counter <= 0;
            uart_rx_data <= 8'b0;
            rx_start <= 1'b0;
            data_ready <= 1'b0;
            irq_flag <= 1'b1; // Interrupt inactive
        end else begin
            case (rx_state)
                RXIDLE: begin
                    if (!i_UART_TX) begin // Start bit detected (low)
                        rx_state <= RECEIVE;
                        rx_start <= 1'b1;
                        rx_bit_counter <= 0;
                    end
                end
                RECEIVE: begin
		   if (rx_start) begin
		      uart_rx_data <= {i_UART_TX, uart_rx_data[7:1]}; // Shift in RX data
		      rx_bit_counter <= rx_bit_counter + 1;
		      if (rx_bit_counter == 7) begin
			 rx_state <= RXIDLE;
			 if (i_UART_TX == 1'b1) begin // Stop bit check
			    data_ready <= 1'b1;
			    irq_flag <= 1'b0;
			 end
		      end
		   end      
           endcase
        end
    end

    // UART TX Process
    always @(posedge baud_clk or posedge reset) begin
        if (reset) begin
            tx_state <= TXIDLE;
            tx_bit_counter <= 0;
            o_UART_RX <= 1'b1; // Idle state (high)
        end else begin
	   case (tx_state)
	     TXIDLE: begin
		if (control_tx == 8'h01) begin
		   tx_state <= TRANSMIT;
		   tx_bit_counter <= 0;
		   uart_tx_data <= {1'b1, i_uart_rxdata, 1'b0}; // Append stop and start bit
		end
	     end
	     TRANSMIT: begin
		o_UART_RX <= uart_tx_data[tx_bit_counter];
		tx_bit_counter <= tx_bit_counter + 1;
		if (tx_bit_counter == 9) begin
		   control_tx <= 8'h00;
		   tx_state <= TXIDLE;
		   o_UART_RX <= 1'b1; // Idle line
		end
	     end
	   endcase
        end
    end

    // Assign the IRQ output and control register for UART TX
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            o_IRQ <= 1'b1; // Interrupt inactive (default high)
        end else begin
	   if (tx_state == TXIDLE)  begin
		control_tx <= i_control;
	     end
            o_IRQ <= irq_flag; // Follow the internal interrupt flag
        end
    end
endmodule // uart_interface
