from distutils.core import setup
from Cython.Distutils import build_ext
from distutils.extension import Extension


import subprocess

def detect_pylon(config_config='/opt/pylon5/bin/pylon-config'):
    compiler_config = dict()
    compiler_config['library_dirs'] = [subprocess.check_output([config_config, '--libdir']).decode().strip(), ]
    compiler_config['include_dirs'] = [_.strip() for _ in
                                       subprocess.check_output([config_config,
                                                                '--cflags-only-I']).decode().strip().split('-I') if _]
    compiler_config['libraries'] = [_.strip() for _ in
                                       subprocess.check_output([config_config,
                                                                '--libs-only-l']).decode().strip().split('-l') if _]
    compiler_config['language'] = 'c++'
    return compiler_config


build_options = detect_pylon()

pypylon_extensions = [Extension('pypylon.cython.version', ['cython/version.pyx', ], **build_options),
                      Extension('pypylon.cython.factory', ['cython/factory.pyx', ], **build_options),
                    ]

setup(name='pypylon',
      license="custom",
      description="Cython module to provide access to Pylon's SDK.",
      version='0.0.1',
      author="Matthias Blaicher",
      author_email="matthias@blaicher.com",
      cmdclass={'build_ext': build_ext},
      ext_modules=pypylon_extensions,
      # ext_modules=cythonize('pypylon/*.pyx', language='c++', **detect_pylon()),
      # install_requires=['cython>=0.20.1'],

      )

# for the classifiers review see:
# https://pypi.python.org/pypi?%3Aaction=list_classifiers
#
# Development Status :: 1 - Planning
# Development Status :: 2 - Pre-Alpha
# Development Status :: 3 - Alpha
# Development Status :: 4 - Beta
# Development Status :: 5 - Production/Stable
