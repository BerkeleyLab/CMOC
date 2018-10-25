#!/usr/bin/python
import operator
import json
import os

class Register(object):
    def __init__(self, **kwargs):
        self.name = kwargs.get('name', '')
        self._value = kwargs.get('value', 0)
        self._width = kwargs.get('width', 32)
        self._address = kwargs.get('addr', 0)
        self._access = kwargs.get('access', '')
        self._array_size = kwargs.get('array_size', 0)

        self._sign = kwargs.get('sign', 'unsigned')
        self._min = -(1 << (self._width - 1)) if (self._sign == 'signed') else 0
        self._max = (1 << (self._width - 1)) - 1 if (
            self._sign == 'signed') else (1 << self._width) - 1

    def __repr__(self):
        if isinstance(self.value, (list, tuple)):
            return 'Name: {:<30} Addr: {:>#8x} Min: {:>#8x} Max: {:>#8x}'.format(
                self.name, self.address, self.min, self.max)+' Value'+str(self.value)
        elif isinstance(self.value, float):
            return 'Name: {:<30}  Value: {:>8f}  Addr: {:>#8x} Min: {:>#8x} Max: {:>#8x}'.format(
                self.name, self.value, self.address, self.min, self.max)
        else:
            return 'Name: {:<30}  Value: {:>#8x}  Addr: {:>#8x} Min: {:>#8x} Max: {:>#8x}'.format(
                self.name, self.value, self.address, self.min, self.max)

    @property
    def sign(self):
        return self._sign

    @property
    def width(self):
        return self._width

    @property
    def array_size(self):
        return self._array_size

    @property
    def address(self):
        return self._address

    @address.setter
    def address(self, v):
        self._address = v

    @property
    def access(self):
        return self._access

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, v):
        if isinstance(v, (list, tuple)):
            self._value = v
        elif v < self._min:
            self._value = self._min
        elif v > self._max:
            self._value = self._max
        else:
            self._value = v

    @property
    def max(self):
        return self._max

    @property
    def min(self):
        return self._min

class RegMap(object):
    """
    Assemble register map from json file, decode values from register
    """
    def __init__(self, **kwargs):
        self.base = kwargs.get('base', 0x0)
        self.end = kwargs.get('end', 0x1)
        self.regmap = {}
        self.regmap_short = {}
        self.reg_addr_dict = {}

    def get_sorted_regmap(self):
        """ sort by reg address and print regmap """
        return sorted(self.regmap.items(), key=operator.itemgetter(1))

    def get_reg_by_addr(self, reg_addr):
        """get register by address"""
        return self.regmap[self.reg_addr_dict[reg_addr]]

    def get_reg_by_name(self, reg_name):
        """get register by name"""
        return self.regmap[reg_name]

    def get_reg_addr(self, reg_name):
        """get register address"""
        return self.regmap[reg_name].address

    def get_reg_val(self, reg_name):
        """get register address"""
        return self.regmap[reg_name].value

    def add_reg(self, name, addr, sign, width, access):
        self.regmap[name] = {'addr': addr, 'sign': sign, 'width': width, 'access': access}

    def add_reg_short(self, name, addr, sign, width, array_size, access):
        self.regmap_short[name] = {'addr': addr, 'sign': sign, 'width': width,
                                   'array_size': array_size, 'access': access}

    def _process_offset(self, reg_name, offset):
        if offset.isdigit():
            return self.regmap[reg_name + '_' + offset]
        elif reg_name in self.regmap:
            return self.regmap[reg_name]
        else:
            return self.regmap[reg_name + '_0']

    def get_reg_info(self, name, hierarchy=[]):
        """
        regmap: is a python dictionary of json regmap generated from ./newad.py
        name: is potentially an unique identifier of a register name inside the
        regmap.
        This method tries to identify the register with the name and return it's
        info hierarchy is something that can be used to help the user.
        eg: get_reg_info({...}, [0,1], coarse_freq), looks for the name coarse_freq
        in cavity_0_cav4_elec_mode_1. Since verilog name convention is far from
        perfect this method tries to ease the pain on the python user, to grab
        the register info
        TODO:
        1. This function can be abstracted and the core below must be made recursive
        2. A register array seems to have N registers associated with it with a postfix
           _n. The user should be able to search for the entire array space without the
           postfix.
        3. The variable H below doesn't belong here
        """
        H = [["llrf", "shell", "tgen", "cavity", "station", "station_cav4_elec"],
             ["mode", "freq", "outer_prod", "dot"]]
        reg_names = self.regmap_short.keys()
        offset = 0
        if type(name) is list:
            offset = name[-1].rsplit('_')[-1]
            if offset.isdigit():
                name[-1] = '_'.join(name[-1].rsplit('_')[:-1])
            for n in name:
                reg_names = filter(lambda x: n in x, reg_names)
        else:
            offset = name.rsplit('_')[-1]
            if offset.isdigit(): name = '_'.join(name.rsplit('_')[:-1])
            reg_names = filter(lambda x: name in x, reg_names)

        if len(reg_names) == 0:
            return None
        elif len(reg_names) == 1:
            return self._process_offset(reg_names[0], offset)

        if type(hierarchy) is list and len(hierarchy) > 0:
            for h in H[0]:
                n = hierarchy[0]
                p = '_' if type(n) is int else ''
                reg_names_1 = filter(lambda x: (h + p + str(n)) in x, reg_names)
                if len(reg_names_1) == 1:
                    return self._process_offset(reg_names_1[0], offset)
                if len(hierarchy) > 1:
                    n = hierarchy[1]
                    p = '_' if type(n) is int else ''
                    for h in H[1]:
                        reg_names_2 = filter(lambda x: (h + p + str(n)) in x,
                                             reg_names_1)
                        if len(reg_names_2) == 1:
                            return self._process_offset(reg_names_2[0], offset)
                        elif len(reg_names_2) > 1:
                            raise Exception('Too many register names match %s\n%s' %
                                            (name, str(reg_names_2)))
        elif len(reg_names) > 1:
            raise Exception('Too many register names match %s\n%s' %
                            (name, str(reg_names)))
        return None

    def assemble_regmap(self, core_name, base, prefix='', postfix='', add_prefix=True):
        module = self.json_data[core_name]
        _mod_name = module['name']
        _corebase = base + (int(module['base'], 16) if 'base' in module else 0)
        _key_prefix = prefix + _mod_name + postfix + '_' if add_prefix else ''
        if 'regmap' in module:
            for k, v in module['regmap'].iteritems():
                _key = _key_prefix + k
                # from newad.py, always use low_res
                if type(v) is dict:
                    _reg_base_addr = (v['base_addr'] if type(v['base_addr']) is int else int(v['base_addr'], 16))
                    _reg_width = v['data_width']
                    _reg_sign = v['sign']
                    self.add_reg_short(_key, _reg_base_addr + _corebase, _reg_sign,
                                       _reg_width, 1 << v['addr_width'], v['access'])
                    for ix in xrange(1 << v['addr_width']):
                        ix_str = '_' + str(ix) if v['addr_width'] > 0 else ''
                        self.add_reg(_key + ix_str, _reg_base_addr + _corebase + ix,
                                     _reg_sign, _reg_width, v['access'])
                else:
                    # format : register_name: address
                    _reg_base_addr = (v if type(v) is int else int(v, 16))
                    _reg_width = 32
                    _reg_sign = 'unsigned'
                    self.add_reg(_key, _reg_base_addr + _corebase, _reg_sign, _reg_width, '')
        if 'addr_max' in module:
            # 4DSP style, see board_support.json
            for _reg_base_addr in xrange(0, int(module['addr_max'], 16)+1):
                _key = _key_prefix + 'REG'+hex(_reg_base_addr)
                self.add_reg(_key, _reg_base_addr + _corebase, 'unsigned', 32, '')
        if 'cores' in module:
            for core in module['cores']:
                _postfix = (core['seq'] if 'seq' in core else '')
                self.assemble_regmap(
                    core['name'],
                    _corebase + int(core['base'], 16),
                    prefix=_mod_name, postfix=_postfix, add_prefix=add_prefix)

    def generate_registers(self):
        for k, v in self.regmap.iteritems():
            self.regmap[k] = Register(name=k, addr=v['addr'], sign=v['sign'], width=v['width'], access=v['access'])
            self.reg_addr_dict[v['addr'] & 0xffffff] = k
        for k, v in self.regmap_short.iteritems():
            self.regmap_short[k] = Register(name=k, **v)

class RegMapExpand(RegMap):
    """
    Flattened registers of cores in hierachy from specific level
    """
    def __init__(self, **kwargs):
        super(RegMapExpand, self).__init__(**kwargs)
        base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
        self.core_name = kwargs.get('core_name', 'core_llrf')
        add_prefix = kwargs.get('add_prefix', True)
        fpath = kwargs.get('path', 'parameters/llrf_core_expand.json')
        json_file = os.path.join(base_dir, fpath)
        if os.path.isfile(json_file):
            with open(json_file, 'r') as f:
                self.json_data = json.load(f)
            self.assemble_regmap(self.core_name, self.base, add_prefix=add_prefix)
            self.generate_registers()
        else:
            raise ValueError('Failed to open json file: %s', json_file)
