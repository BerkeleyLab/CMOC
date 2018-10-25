import os
import sys
from subprocess import call
import numpy as np
import matplotlib.pylab as plt

def write_reg_file(registers, regmap_fdbk_core, filename):
    """
    Write register file with the following format for input to Verilog test-bench:
        'address1 data1'
        'address2 data2'
        ...
    Inputs:
        - registers: Array of Register objects,
        - regmap_fdbk_core: Register map,
        - filename: Name of the output file.
    """

    f = open(filename, 'w')
    for reg in registers:
        base_addr = reg['base_addr']
        for i, val in enumerate(reg['value']):
            line = '%d %d\n' % (base_addr+i, val)
            f.write(line)
    f.close()

def run_test_bench():

	in_file = 'lp1_in.dat'
	out_file = 'lp1_out.dat'

	command = 'vvp -n lp1_tb' + ' +in_file=' + in_file + ' +out_file=' + out_file

	return_code = call(command, shell=True)

if __name__ == "__main__":

    # Run Set-point scaling test
    run_test_bench()
