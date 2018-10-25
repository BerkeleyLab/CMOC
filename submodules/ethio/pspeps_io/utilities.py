#!/usr/bin/python
import numpy as np
import logging
# matplotlib.use('TkAgg') # for MacOs X backend
# matplotlib.use('module://kivy.garden.matplotlib.backend_kivyagg')
from matplotlib import pyplot as plt
import sys
logger = logging.getLogger(__name__)

def decode_twos_comp(darray, bits=16):
    mask = 2**(bits - 1)
    return -np.bitwise_and(darray, mask) + np.bitwise_and(darray, ~mask)

def decode_2s_comp(val, bits=16, signed=True):
    # mask = 2**(bits - 1)
    # return -(val & mask) + (val & ~mask)
    val = np.bitwise_and(np.uint64(val), np.uint64((1 << bits) - 1))
    if signed:
        return val-(1 << bits) if val >= 1 << (bits - 1) else val
    else:
        return val

def encode_2s_comp(val, bits=16):
    return int(val) & ((1 << bits) - 1) if val < 0 else int(val)

def print_reg(dat):
    if isinstance(dat, dict):
        for key in sorted(dat.iterkeys()):
            # print "%20s: \t %s"%(key, dat[key])
            sys.stdout.write("{:<25}: {:<25}\n".format(key, dat[key]))
    elif isinstance(dat, list):
        for ix in dat:
            print_reg(ix)
    else:
        print dat

class CommonUtilities(object):
    """ Common data manipulation and plotting methods """
    def __init__(self, **kwargs):
        super(CommonUtilities, self).__init__(**kwargs)
        self.adc_len = 128
        self.adc_bits = 16
        self.adc_n_chan = 2
        self.adc_freqs = [100.]*self.adc_n_chan
        self.dac_freq = 100.

    def prep_sin_data(self, samples, bits=16):
        scale = (1 << (bits - 1)) - 1
        t = np.arange(0, 1., 1. / samples)
        return map(self.encode_2s_comp, 0.1*scale*np.sin(2*np.pi*t), [bits]*len(t))

    def prep_sin_data_if(self, samples, step, level, bits=16):
        assert 0 <= level <= 1
        scale = (1 << (bits - 1)) - 1
        t = np.arange(0, step * samples, step)
        return map(self.encode_2s_comp, scale*level*np.sin(2*np.pi*t), [bits]*len(t))

    def print_adc_wfm(self, dat, bits=16):
        for chan_dat in dat:
            chan_dat = map(decode_2s_comp, chan_dat, [bits]*len(chan_dat))
            print chan_dat

    def update_adc_wfm(self, adc_in, bits=16):
        """ FPS = 350 """
        # logger.info('update_adc_wfm: %s'%datetime.now())
        items = enumerate(zip(self.lines, self.axes, self.backgrounds), start=1)
        for i, (line, ax, background) in items:
            self.fig.canvas.restore_region(background)
            y_data = map(decode_2s_comp, adc_in[i-1], [bits]*len(adc_in[i-1]))
            line.set_ydata(y_data)
            ax.draw_artist(line)
            self.fig.canvas.blit(ax.bbox)

    def prep_plot(self):
        self.fig, self.axes = plt.subplots(nrows=self.adc_n_chan, figsize=(10, 15))
        self.fig.show()
        styles = ['ro', 'bo'] * int(self.adc_n_chan / 2)
        t_samples = [1000./f for f in self.adc_freqs]

        def plot(ax, style, t_sample):
            x_data = np.arange(0., t_sample*self.adc_read_len, t_sample)
            return ax.plot(x_data, [0]*self.adc_read_len, style, animated=True)[0]
        self.lines = [plot(ax, style, t_sample) for ax, style, t_sample in zip(
            self.axes, styles, t_samples)]
        self.backgrounds = [self.fig.canvas.copy_from_bbox(ax.bbox) for ax in self.axes]
        for ax in self.axes:
            # ax.set_ylim(-1<<(self.adc_bits-2),1<<(self.adc_bits-2))
            ax.set_ylim(-1200, 1200)
            # ax.set_xlim(420, 520)
            ax.set_xlabel('ns')
            ax.set_ylabel('signed count')
            ax.set_label('adc')
        self.fig.canvas.draw()

    def read_data(self, file_name):
        f = open(file_name, 'r')
        data = f.read()
        f.close()
        data = data.split()
        data = np.array([float(i) for i in data])
        return data
