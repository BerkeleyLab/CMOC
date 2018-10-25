import json
import sys
import os

def main(argv):
    core_frame = argv[1]
    core_regmaps = argv[2:]
    with open(core_frame, 'r') as f:
        json_data = json.load(f, parse_int=int)
    base_dir = os.path.dirname(os.path.realpath(__file__))
    core_names = ['cryomodule']
    for core_name, core_file in zip(core_names, core_regmaps):
        with open(core_file, 'r') as f:
            core_json = json.load(f, parse_int=int)
            json_data[core_name]['regmap'] = core_json
        json_file = os.path.join(base_dir, core_name)
        with open(json_file+'.json', 'w') as out_f:
            json.dump(json_data[core_name], out_f, indent=4, sort_keys=True)

    print json.dumps(json_data, indent=4, sort_keys=True)

#reg_data = []
#reg_dict = {}
#for key,val in core_json.iteritems():
#    print key, val
#    reg_dict['name'] = key
#    reg_dict['addr'] = val
#    reg_dict['value'] = 0
#    reg_dict['vmin'] = 0
#    reg_dict['vmax'] = 100
#    reg_dict['unit'] = ''
#    reg_data.append(reg_dict)
#
#print reg_data
#


if __name__ == "__main__":
    main(sys.argv)
