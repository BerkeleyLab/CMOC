`timescale  100 ps / 10 ps

module ac701_clocks(
    input  glbl_rst,

    // Sys clock from U51
    input  sysclk_p,
    input  sysclk_n,
    // User clock from U34
    // input  USER_CLOCK_P,
    // input  USER_CLOCK_N,

    // User SMA clock from J31/J32
    // input  USER_SMA_CLOCK_P,
    // input  USER_SMA_CLOCK_N,

    output clk_pll,     // PLL OUTPUT 1
    output clk_pll_90,  // PLL OUTPUT 1, phase 90
    output clk_100,     // 100 MHz

    // Master Clock for memory controller block
    output pll_lock // from PLL
);
    parameter   clk1_period = 5;  // PLLE2_BASE CLKIN1_PERIOD in ns. default 200MHz input.
    parameter   mult = 5; // PLLE2_BASE CLKFB_OUT_MULT.
    parameter   div_pll = 8;// PLLE2_BASE CLKOUT5_DIVIDE

`ifndef SIMULATE
/* System Clock */
wire                osc_clk_ibufgds;

IBUFGDS #(
  .DIFF_TERM("FALSE"),    // Differential Termination (Virtex-4/5, Spartan-3E/3A)
  .IBUF_LOW_PWR("TRUE"), // Low power="TRUE", Highest performance="FALSE"
  .IOSTANDARD("DEFAULT")  // Specify the input I/O standard
) inibufgds (
  .O(osc_clk_ibufgds),  // Clock buffer output
  .I(sysclk_p),       // Diff_p clock buffer input (connect directly to top-level port)
  .IB(sysclk_n)       // Diff_n clock buffer input (connect directly to top-level port)
);

wire clkfbout; // Clock from PLLFBOUT to PLLFBIN
wire pll_clk_0, pll_clk_90;
wire clk_25_bufg_in, clk_50_bufg_in, clk_250_bufg_in, clk_100_bufg_in;

PLLE2_BASE #(
    .BANDWIDTH("OPTIMIZED"), // OPTIMIZED, HIGH, LOW
    .CLKFBOUT_MULT(mult), // Multiply value for all CLKOUT, (2-64)
    .CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB, (-360.000-360.000).
    .CLKIN1_PERIOD(clk1_period), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
    .CLKOUT0_DIVIDE(div_pll), // 1000 MHz /8  = 125 MHz
    .CLKOUT1_DIVIDE(div_pll), // 1000 MHz /8  = 125 MHz
    .CLKOUT2_DIVIDE(40),// 1000 MHz /40 = 25 MHz
    .CLKOUT3_DIVIDE(20),// 1000 MHz /20 = 50 MHz
    .CLKOUT4_DIVIDE(4), // 1000 MHz /4  = 250 MHz
    .CLKOUT5_DIVIDE(10), // 1000 MHz /10  = 100 MHz
    // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT5_DUTY_CYCLE(0.5),
    // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
    .CLKOUT0_PHASE(0.0),
    .CLKOUT1_PHASE(90.0),
    .CLKOUT2_PHASE(0.0),
    .CLKOUT3_PHASE(0.0),
    .CLKOUT4_PHASE(0.0),
    .CLKOUT5_PHASE(0.0),
    .DIVCLK_DIVIDE(1), // Master division value, (1-56)
    .REF_JITTER1(0.0), // Reference input jitter in UI, (0.000-0.999).
    .STARTUP_WAIT("FALSE") // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
)
PLLE2_BASE_inst (
    .CLKIN1(osc_clk_ibufgds),
    // Clock Outputs: 1-bit (each) output: User configurable clock outputs
    .CLKOUT0(pll_clk_0),        // 125 MHz, 0 degree
    .CLKOUT1(pll_clk_90),       // 125 MHz, 180 degree
    .CLKOUT2(clk_25_bufg_in),   // 1000/40 = 25 MHz, 0 degree
    .CLKOUT3(clk_50_bufg_in),   // 1000/20 = 50 MHz, 0 degree
    .CLKOUT4(clk_250_bufg_in),  // 1000/4 = 250 MHz, 0 degree
    .CLKOUT5(clk_100_bufg_in),  // 1000/10 = 100 MHz, 0 degree
    // Feedback Clocks: 1-bit (each) output: Clock feedback ports
    .CLKFBOUT(clkfbout), // 1-bit output: Feedback clock
    .LOCKED(pll_lock),
    // Control Ports: 1-bit (each) input: PLL control ports
    .PWRDWN(1'b0), // 1-bit input: Power-down
    .RST(glbl_rst), // 1-bit input: Reset
    // Feedback Clocks: 1-bit (each) input: Clock feedback ports
    .CLKFBIN(clkfbout) // 1-bit input: Feedback clock
);

BUFG clk_pll_bufg (
    .I(pll_clk_0),
    .O(clk_pll)
);

BUFG clk_pll_90_bufg (
    .I(pll_clk_90),
    .O(clk_pll_90)
);

BUFG clk_100_bufg (
    .I(clk_100_bufg_in),
    .O(clk_100)
);

`endif // !`ifndef SIMULATE
endmodule
