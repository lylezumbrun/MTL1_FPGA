`timescale 1ns / 1ps

module EClockDelayTB;

    // Inputs
    reg i_clk;          // Fast PLL clock (e.g., 100 MHz)
    reg i_e_clk;        // 6809 E clock

    // Outputs
    wire o_e_longdelay;   // Long delay output
    wire o_e_shortdelay;  // Short delay output

    // Instantiate the Unit Under Test (UUT)
    e_clk_delay uut (
        .i_clk(i_clk),
        .i_e_clk(i_e_clk),
        .o_e_longdelay(o_e_longdelay),
        .o_e_shortdelay(o_e_shortdelay)
    );

    // Clock generation for i_clk (100 MHz)
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 10ns clock period (100 MHz)
    end

    // Test procedure
    initial begin
        $dumpfile("simulation.vcd");
        $dumpvars(0, EClockDelayTB);

        // Initialize inputs
        i_e_clk = 0;

        // Wait for reset
        #20;

        // Simulate E clock signal (6809 E clock)
        i_e_clk = 1; #500;  // E clock high for 500ns
        i_e_clk = 0; #500;  // E clock low for 500ns
        i_e_clk = 1; #1500;  // E clock high for 500ns
        i_e_clk = 0; #500;  // E clock low for 500ns
        i_e_clk = 1; #500;  // E clock high for 500ns
        i_e_clk = 0; #500;  // E clock low for 500ns

        // End simulation
        #500;
        $finish;
    end

    // Monitor signals for debugging
    initial begin
        $monitor("Time: %0dns, i_clk: %b, i_e_clk: %b, o_e_longdelay: %b, o_e_shortdelay: %b",
                 $time, i_clk, i_e_clk, o_e_longdelay, o_e_shortdelay);
    end

endmodule