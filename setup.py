from setuptools import setup, find_packages
from Cython.Distutils import build_ext, Extension
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
    compiler_config['runtime_library_dirs'] = compiler_config['library_dirs']
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
      packages=find_packages(exclude=['contrib', 'docs', 'tests', 'examples', 'cython']),

      # for the classifiers review see:
      # https://pypi.python.org/pypi?%3Aaction=list_classifiers
      classifiers=[
          'Development Status :: 3 - Alpha',

          'Intended Audience :: Developers',
          'Topic :: Multimedia :: Graphics :: Capture :: Digital Camera'

          'License :: OSI Approved :: BSD License',

          'Programming Language :: Python :: 3',
          'Programming Language :: Python :: 3.2',
          'Programming Language :: Python :: 3.3',
          'Programming Language :: Python :: 3.4',
          'Programming Language :: Python :: 3.5',
      ],
      )