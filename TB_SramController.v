`timescale 1us / 1us
module tb_sramcontroller();
// Test Bench Signals
reg sram_ce;
reg i_RW;
reg i_E;

wire o_WE;
wire o_RE;
wire o_CE;
wire o_CE2;


sram_controller uut(
    .sram_ce(sram_ce),
    .i_RW(i_RW),
    .i_E(i_E),
    .o_WE(o_WE),
    .o_RE(o_RE),
    .o_CE(o_CE),
    .o_CE2(o_CE2)
);

initial begin
        $dumpfile("simulation.vcd");
        $dumpvars;
        // Initialize inputs
        sram_ce = 1'b0;
        i_RW = 1'b1;
        i_E = 1'b0;


        // Monitor outputs
        $monitor("Time = %0t, SRAM CE = %b, RW = %b, E = %b, WE = %b, RE = %b, CE = %b, CE2 = %b",
         $time, sram_ce, i_RW, i_E, o_WE, o_RE, o_CE, o_CE2);
        #10;
        // Test 1:
        sram_ce = 1'b1;
        #10;
        i_RW = 1'b1;
        #2;
        i_E = 1'b1;
        #2;
        i_E = 1'b0;
        #10;
        sram_ce = 1'b0;
        #10;
        sram_ce = 1'b1;
        #10;
        i_RW = 1'b0;
        #2;
        i_E = 1'b1;
        #2;
        i_E = 1'b0;
        #2;
        i_RW = 1'b1;
        #10;
        sram_ce = 1'b0;
        #10;
        $finish;
end
endmodule
