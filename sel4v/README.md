# CryoModule On Chip

***
## The Hows and Whys of SEL feedback for LLRF
Larry Doolittle, LBNL, February 2014

Still a work in progress. I know there's a lot broken in here,
as you can tell by a quick grep XXX *.v
Also, the unit testing is still weak, doesn't cover mp_proc.

See ideas.txt

Note the configuration of COMMON_HDL_DIR in Makefile, that works
on my computer.  You need point it to files from the repository
  ssh://atg.lbl.gov/software_firmware/common_hdl.git

To see the paper:
    make doc && xpdf sel4.pdf

This takes a bit of time, because it has to run 8000 cycles of a
system simulation, to make the plots of the cavity turn-on process.

To check that the core data path through the CIC filters and the
CORDIC, not including the PI controllers in mp_proc.v, works:
    make fdbk_core_check

To see that the data flow in mp_proc by itself looks OK:
    make mp_proc_view

To see the 8pi/9 notch filter design, run lp_notch within Octave.

In general, every foo.sav file here is an indication that you can
make foo_view to view the waveforms for module foo.

Other than bug-fixing, the major un-done steps here are turning
on the low-latency data path, and getting a usable configuration
of the low-pass filter, or maybe even a combined 8pi/9 filter.

I'd like the cavity model parameters to be run-time loadable,
maybe via Python.  As a stepping stone toward that goal,
Python is in fact loaded into the cavity simulator.
But it doesn't do anything useful yet, just prints "Hello, world!"

Possible setup for a "scale model" cavity:
Use 20 Hz * 64 = 1300 Hz for the open-loop bandwidth.
One time constant is then 120 us, "only" 12000 clock cycles.
Should be able to fill it in SEL mode, and then close the loop,
in 20000 to 30000 simulation cycles.  This setup would use
coarse_scale=1 instead of 3.

All this is predicated on the idea that you're running on a
Real Computer[TM], with Octave, Icarus Verilog, and GTKWave installed.
I recommend Debian Wheezy.  The block diagrams for the paper (intro.eps,
sel_quad.eps, boxes.eps) are created with xcircuit.

A "full" LLRF DSP subsystem is under construction as llrf_dsp.v.
Its interface is modeled after the one used on APEX and SPX, but
with not so many features.  I hope to connect it to a cavity simulator.
See larger.v.  Users of this Verilog code base can leave everything
here alone, and should reference the code via vsource.mk; see that
file for details.
