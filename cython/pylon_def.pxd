from libcpp cimport bool
from libc.stdint cimport uint32_t

cdef extern from "pylon/PylonIncludes.h" namespace 'Pylon':
    # Common special data types
    cdef cppclass String_t
    cdef cppclass StringList_t

    # Top level init functions
    void PylonInitialize()

    # cdef enum EPixelType:

    cdef cppclass IImage:
        uint32_t GetWidth()
        uint32_t GetHeight()
        size_t GetPaddingX()
        size_t GetImageSize()
        void* GetBuffer()

    cdef cppclass CGrabResultPtr:
        IImage& operator()
        #CGrabResultData* operator->()
        pass

    cdef cppclass IPylonDevice:
        pass

    cdef cppclass CDeviceInfo:
        String_t GetSerialNumber()
        String_t GetUserDefinedName()
        String_t GetModelName()
        String_t GetDeviceVersion()
        String_t GetFriendlyName()
        String_t GetVendorName()
        String_t GetDeviceClass()

    cdef cppclass CInstantCamera:
        CInstantCamera()
        void Attach(IPylonDevice*)
        CDeviceInfo& GetDeviceInfo()
        void IsCameraDeviceRemoved()
        void Open()
        void Close()
        bool IsOpen()
        IPylonDevice* DetachDevice()
        void StartGrabbing(size_t maxImages)    #FIXME: implement different strategies
        bool IsGrabbing()
        bool RetrieveResult(unsigned int timeout_ms, CGrabResultPtr& grab_result)  # FIXME: Timout handling

    cdef cppclass DeviceInfoList_t:
        cppclass iterator:
            CDeviceInfo operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        DeviceInfoList_t()
        CDeviceInfo& operator[](int)
        CDeviceInfo& at(int)
        iterator begin()
        iterator end()

    cdef cppclass CTlFactory:
        int EnumerateDevices(DeviceInfoList_t&, bool add_to_list=False)
        IPylonDevice* CreateDevice(CDeviceInfo&)

# Hack to define a static member function
cdef extern from "pylon/PylonIncludes.h"  namespace 'Pylon::CTlFactory':
        CTlFactory& GetInstance()