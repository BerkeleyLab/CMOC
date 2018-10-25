import sys, os

filenames = [os.path.basename(x) for x in sys.argv[1:]]
if len(filenames) != len(set(filenames)):
    print("Remote build doesn't work when there are 2 files in the project\
    hierarchy with the same filename")
    exit(1)

for x in filenames:
    # A set of files that currently aren't part of the source_files args for
    # VIVADO_SYNTH
    if x not in ["system_top.xdc", "project_proc.tcl", "vivado_project.tcl"]:
        print x,
