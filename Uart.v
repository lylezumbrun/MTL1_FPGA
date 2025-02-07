    module uart_interface (
    input i_RW,
    input i_uart_data_ce,
    input i_uart_control_ce, 
    input clk,                  // System clock (44.33 MHz)
    input reset,                // System reset
    input i_UART_TX,            // FT2232 TX line (serial data from host)
    input [7:0] i_control,      // Input to Control register
    input [7:0] i_uart_rxdata,  // Data input from 6809

    output reg o_UART_RX = 1'b1, // FT2232 RX line (serial data to host)
    output reg [7:0] o_uart_txdata, // Data output to 6809
    output reg [7:0] o_uart_status, // UART Status Register
    output reg [7:0] o_control, // output the control register
    output reg o_IRQ = 1'b1      // Active-low interrupt signal to 6809
    );

    // Parameters
    parameter CLOCK_DIVISOR = 9236; // Divisor for 9600 bps with 88.67 MHz clock
    localparam RXIDLE = 1'b0, RECEIVE = 1'b1; // UART RX states
    localparam TXIDLE = 1'b0, TRANSMIT = 1'b1; // UART TX states

    // Internal Signals
    reg [12:0] counter = 0;     // Baud rate counter
    reg baud_clk = 0;           // Baud rate clock
    reg [3:0] rx_bit_counter = 0;  // Bit counter for RX
    reg [3:0] tx_bit_counter = 0;  // Bit counter for TX
    reg [7:0] uart_rx_data = 8'b0; // Data received from FT2232
    reg rx_state = RXIDLE;      // UART RX state
    reg tx_state = TXIDLE;      // UART TX state
    reg irq_flag = 1'b1;        // Internal interrupt flag (active-low)
    reg transmit_flag = 1'b0;
    reg receive_flag = 1'b0;
    reg	[7:0] control_uart = 8'b0;    // bit 0 = Data Ready to Tranmsit, bit 1 =  Enable interrupt
    reg [9:0] uart_tx_data = 10'b0;
    reg [7:0] uart_data_out = 8'b0;

   
   
       
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
         rx_state <= RXIDLE; // default to IDLE state
         rx_bit_counter <= 0; // set counter to zero
         uart_rx_data <= 8'b0; // zero register
         irq_flag <= 1'b1;  // Interrupt inactive on reset
      end else begin
         case (rx_state)
           RXIDLE: begin
              if (!i_UART_TX) begin // Start bit detected (low)
                 rx_state <= RECEIVE; // change to state to receive
                 rx_bit_counter <= 0; // set counter to zero
              end
           end
           RECEIVE: begin
                 uart_rx_data <= {i_UART_TX, uart_rx_data[7:1]}; // shift in the received bit to MSB by concentation TX-->BITS(7-1) makes 8 bits. LSB is dropped with each cycle
                 if (rx_bit_counter == 7) begin
                    rx_state <= RXIDLE;
                    if (control_uart[1]) begin
                       irq_flag <= 1'b0;  // Assert interrupt (active-low)
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
	    o_uart_status[1] <= 1'b0; // clear the transmit busy flag
        end else begin
	   case (tx_state)
	     TXIDLE: begin
            if (transmit_flag) begin   
                tx_state <= TRANSMIT;
                o_uart_status[1] <= 1'b1; // Set the transmit busy flag
                tx_bit_counter <= 0;
                uart_tx_data <= {1'b1, uart_data_out, 1'b0}; // Append stop and start bit
            end
	     end
	     TRANSMIT: begin
            o_UART_RX <= uart_tx_data[tx_bit_counter];
            tx_bit_counter <= tx_bit_counter + 1;
            if (tx_bit_counter == 9) begin
                o_uart_status[1] <= 1'b0; // clear the transmit status busy flag
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
            transmit_flag <= 1'b0;
            o_uart_status[0] <= 1'b0; // clear rx data ready flag
        end 
        else begin
            if(i_RW && i_uart_control_ce) begin
                o_control <= control_uart;
            end 
            if (!i_RW && i_uart_control_ce) begin
                control_uart <= i_control;
                
            end
            if (!i_RW && i_uart_data_ce && !tx_state) begin
                uart_data_out <= i_uart_rxdata;
                transmit_flag <= 1'b1; // Start transmit for data 
            end
            if (tx_state) begin
                transmit_flag <= 1'b0; // In transmit state, clear the flag
            end
            if (rx_bit_counter == 7 && rx_state == RXIDLE) begin
                o_uart_status[0] <= 1'b1;  // Set RX data ready flag
            end
            if (rx_state == RECEIVE || i_RW && i_uart_data_ce) begin
                o_uart_status[0] <= 1'b0;  // Set RX data ready flag
            end
            if (i_RW && i_uart_data_ce) begin
                o_uart_txdata <= uart_rx_data;  // Set RX data ready flag
            end

            o_IRQ <= irq_flag; // Follow the internal interrupt flag

    end
end




endmodule // uart_interface
