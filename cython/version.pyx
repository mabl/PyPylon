cdef extern from "pylon/PylonVersionNumber.h":
    int PYLON_VERSION_MAJOR
    int PYLON_VERSION_MINOR
    int PYLON_VERSION_SUBMINOR
    int PYLON_VERSION_BUILD

cdef class PylonVersion:
    property major:
        def __get__(self):
            return PYLON_VERSION_MAJOR

    property minor:
        def __get__(self):
            return PYLON_VERSION_MINOR

    property subminor:
        def __get__(self):
            return PYLON_VERSION_SUBMINOR

    property build:
        def __get__(self):
            return PYLON_VERSION_BUILD

    property version_tuple:
        def __get__(self):
            return self.major, self.minor, self.subminor, self.build

    property version:
        def __get__(self):
            return '%i.%i.%i.build_%i' % self.version_tuple