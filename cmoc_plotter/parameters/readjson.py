"""
Helper routines to parse JSON files.
"""

import re

def jsontodict(filename, defaultfile=None, Verbose=False):
    """
    Helper routine to read a JSON file (and optionally
    a default file) and return a python dictionary.
    """

    import json

    # Read in file of interest
    f = open(filename)
    nondefault = json.load(f)
    f.close()

    a={}
    # Look for a default file
    if defaultfile:
        try:
            f=open(defaultfile)
            a=json.load(f)
            f.close()
        except Exception,e:
            print "No default parameters read"
            print str(e)

    # Add the new to the default overwriting changed default values
    a.update(nondefault)

    return a

def readentry(dictin,entry,localdic=None, safedic={}):
    """
    readentry: Recursively read and evaluate entries in a dictionary.
        inputs:
            - dictin :   dictionary to be searched if entry cannot be evaluated,
            - entry :    the dictionary value you would like to get,
            - localdic (optional):  input to pass previously found dictionary entries down the recursive chain.
        output:
            - the value of entry is return as float if is can be evaluated using the
            in the dictionary and otherwise it returns the string.
    """

    # Replace localdic with an empty dictionary if nothing passed
    if localdic is None:
        localdic={}

    # Try to evaluate the entry of interest
    try:
        out=eval(str(entry),{},safedic)
        if isinstance(out,str) or isinstance(out,int) or isinstance(out, unicode):
            out = float(out)
        elif isinstance(out,list):
            out = [float(x) if isinstance(x,int) or isinstance(x,str) or isinstance(x,unicode) else x for x in out]

    # If the entry can not be evaluated look at error to get missing entry
    except NameError as e:
        # Pull out the missing variable from the expression
        name=str(e).split("'")[1]
        print 'Looking for {0}'.format(name)

        # Search the dictionary for the entry
        # and add to local variables and retry the evaluation
        try:
            newentry=dictin[str(name)]
        except KeyError:
            try:
                newentry=localdic[str(name)]
            except KeyError:
                print '{0} has no numeric evaluation in dictionary'.format(name)
                newentry = str(name)

        safedic[name]=readentry(dictin,newentry,None,localdic)
        out=readentry(dictin,entry,localdic,safedic)

    except TypeError as e:
        print 'Oops! TypeError: ' + str(e)
        return entry

    return out

def ReadDict(files, Verbose=True):
    """ ReadDict: Build a dictionary from a list of files."""
    import json
    if(type(files)==str):
        files = [files]
    masterdict = {}
    for fname in files:

        # See if the filename is actually a dictionary
        # passed in through the command line.
        if re.match("^{.*}$",fname):
            fdic = json.loads(fname)
        else:
            f = open(fname)
            fdic = json.load(f)
            f.close()

        # See if the user made any references inside of the file...
        try:
            includes = fdic['#include']
            if Verbose: print "INCLUDING THESE FILES: ",includes
            incdict = ReadDict(includes)
            masterdict.update(incdict)
        except:
            pass
        if Verbose: print "Loading ",fname,"..."
        OverlayDict(masterdict,fdic)
    return masterdict

def OverlayDict(olddict,newdict):
    """OverlayDict: Recursively overlay two dictionaries."""

    for k in newdict.iterkeys():
        if type(newdict[k])==dict:
            if olddict.has_key(k):
                OverlayDict( olddict[k], newdict[k] )
            else:
                olddict[k] = newdict[k]
        else:
            olddict[k] = newdict[k]
