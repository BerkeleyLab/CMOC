# Accelerator-On-Chip Simulation Engine

This code base includes Verilog code and software used to implement an Accelerator-On- Chip simulation engine.
The core of the simulation runs on an FPGA and the source is contained in the `sel4v/` directory,
and software support can be found int the `runtime/` directory, which both include their own README files.

A series of libraries are used in the form of submodules. To clone this project and get the latest versions of the libraries, type:

		$ git clone --recursive https://github.com/BerkeleyLab/CMOC.git

## Dependencies

* Python 2.7
* Icarus Verilog 10.0
