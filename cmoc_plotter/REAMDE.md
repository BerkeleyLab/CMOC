# HOWTO Kivi GUI for the CMOC application

Running the Kivy GUI for the CMOC application is a three step process.

## Generate the register map

First you need to generate the JSON files containing the register map.
You can do this from the `cmoc_plotter` directory by typing:

	$ make

This command assumes that `ethio` is used as a submodule in the CMOC project. It will use the tools in the `build` submodule to parse the CMOC Verilog code and generate JSON files containing the register map information. Those files are then assembled into a single JSON file which will be parsed by the GUI application (`ethio/cmoc/json/llrf_core_expand.json`).

## Provide configuration file for Kivy GUI to run CMOC application

The Kivy GUI is designed to support different applications. In order to indicate the high-level Python program to run the CMOC-specific routines, a file has been provided as an example in the `ethio/cmoc` directory. In order for the GUI to take it into account, and from the `ethio` directory, type:

	$ cp cmoc_plotter/kivygui.ini.cmoc kivy/kivygui.ini

Note configuration parameteres such as the IP address in the `kivygui.ini` file, please adapt as needed to match the firmware loaded in the FPGA where CMOC is running.

	$ cd submodules/ethio ; ln -s /path/to/cmoc_plotter cmoc_plotter

## Launch the Kivy GUI Application

Once the register map JSON file is available and the GUI application has its configuration file ready, you need to launch the application, which is located in the `ethio/kivy` directory. From that directory, simply type:

	$ python kivy/main.py
