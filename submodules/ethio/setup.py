try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

config = {
    'description': 'PSPEPS IO interface with auto register mapping',
    'version': '0.1',
    'packages': ['pspeps_io'],
    'name': 'pspeps_io'
}

setup(**config)
