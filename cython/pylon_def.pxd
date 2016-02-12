from libcpp cimport bool
from libc.stdint cimport uint32_t, uint64_t, int64_t
from libcpp.string cimport string

cdef extern from "Base/GCBase.h":
    cdef cppclass gcstring:
        gcstring(char*)

cdef extern from "GenApi/GenApi.h" namespace 'GenApi':

    cdef cppclass INode:
        gcstring GetName(bool FullQualified=False)
        gcstring GetNameSpace()
        gcstring GetDescription()
        gcstring GetDisplayName()
        bool IsFeature()
        gcstring GetValue()

    # Types an INode could be
    cdef cppclass IValue:
        gcstring ToString()
        void FromString(gcstring, bool verify=True)

    cdef cppclass IBoolean:
        bool GetValue()
        void SetValue(bool)

    cdef cppclass IInteger:
        int64_t GetValue()
        void SetValue(int64_t)
        int64_t GetMin()
        int64_t GetMax()

    cdef cppclass IString
    cdef cppclass IFloat:
        double GetValue()
        void SetValue(double)
        double GetMin()
        double GetMax()

    cdef cppclass NodeList_t:
        cppclass iterator:
            INode* operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        NodeList_t()
        CDeviceInfo& operator[](int)
        CDeviceInfo& at(int)
        iterator begin()
        iterator end()

    cdef cppclass ICategory

    cdef cppclass INodeMap:
        void GetNodes(NodeList_t&)
        INode* GetNode(gcstring& )
        uint32_t GetNumNodes()

cdef extern from *:
    IValue* dynamic_cast_ivalue_ptr "dynamic_cast<GenApi::IValue*>" (INode*) except +
    IBoolean* dynamic_cast_iboolean_ptr "dynamic_cast<GenApi::IBoolean*>" (INode*) except +
    IInteger* dynamic_cast_iinteger_ptr "dynamic_cast<GenApi::IInteger*>" (INode*) except +
    IFloat* dynamic_cast_ifloat_ptr "dynamic_cast<GenApi::IFloat*>" (INode*) except +
    INodeMap* dynamic_cast_inodemap_ptr "dynamic_cast<GenApi::INodeMap*>" (INode*) except +
    INodeMap* dynamic_cast_inodemap_ptr "dynamic_cast<GenApi::INodeMap*>" (INode*) except +
    ICategory* dynamic_cast_icategory_ptr "dynamic_cast<GenApi::ICategory*>" (INode*) except +

    bool node_is_readable "GenApi::IsReadable" (INode*) except +
    bool node_is_writable "GenApi::IsWritable" (INode*) except +
    bool node_is_implemented "GenApi::IsImplemented" (INode*) except +

cdef extern from "pylon/PylonIncludes.h" namespace 'Pylon':
    # Common special data types
    cdef cppclass String_t
    cdef cppclass StringList_t

    # Top level init functions
    void PylonInitialize()
    void PylonTerminate()

    # cdef enum EPixelType:

    cdef cppclass IImage:
        uint32_t GetWidth()
        uint32_t GetHeight()
        size_t GetPaddingX()
        size_t GetImageSize()
        void* GetBuffer()
        bool IsValid()

    cdef cppclass CGrabResultData:
        bool GrabSucceeded()

    cdef cppclass CGrabResultPtr:
        IImage& operator()
        #CGrabResultData* operator->()


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
        INodeMap& GetNodeMap()

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

# EVIL HACK: We cannot dereference officially with the -> operator. So we use ugly macros...
cdef extern from 'hacks.h':
    bool ACCESS_CGrabResultPtr_GrabSucceeded(CGrabResultPtr ptr)
    String_t ACCESS_CGrabResultPtr_GetErrorDescription(CGrabResultPtr ptr)
    uint32_t ACCESS_CGrabResultPtr_GetErrorCode(CGrabResultPtr ptr)