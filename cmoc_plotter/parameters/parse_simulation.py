"""
Python parser of Simulation Configuration parameters from JSON file.
"""

def loadConfig(files, Verbose=True):
    """ Get list of JSON files and return JSON dictionary. """

    from readjson import ReadDict
    # Read the configuration file(s)
    confdict = ReadDict(files, Verbose)

    return confdict

def ParseSimulation(file_list, Verbose=True):
    """ Get list of JSON files and return Simulation object. """

    # Import accelerator-specific functions
    import readjson_accelerator as read_acc
    # Extract dictionary from JSON configuration file(s)
    conf_dictionary = loadConfig(file_list, Verbose)

    # Instantiate accelerator class using configuration in the dictionary
    simulation = read_acc.Simulation(conf_dictionary)

    return simulation

def DoSimulation():

    file_list =  ["configfiles/LCLS-II/default_accelerator.json", "configfiles/LCLS-II/LCLS-II_accelerator.json"]

    simulation = ParseSimulation(file_list)

    print simulation


