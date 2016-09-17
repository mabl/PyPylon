from cython.operator cimport dereference as deref, preincrement as inc
from libcpp cimport bool
from libcpp.string cimport string

cimport numpy as np
import numpy as np

from pylon_def cimport *


cdef class DeviceInfo:
    cdef:
        CDeviceInfo dev_info

    @staticmethod
    cdef create(CDeviceInfo dev_info):
        obj = DeviceInfo()
        obj.dev_info = dev_info
        return obj

    property serial_number:
        def __get__(self):
            return (<string>(self.dev_info.GetSerialNumber())).decode('ascii')

    property model_name:
        def __get__(self):
            return (<string>(self.dev_info.GetModelName())).decode('ascii')

    property user_defined_name:
        def __get__(self):
            return (<string>(self.dev_info.GetUserDefinedName())).decode('ascii')

    property device_version:
        def __get__(self):
            return (<string>(self.dev_info.GetDeviceVersion())).decode('ascii')

    property friendly_name:
        def __get__(self):
            return (<string>(self.dev_info.GetFriendlyName())).decode('ascii')

    property vendor_name:
        def __get__(self):
            return (<string>(self.dev_info.GetVendorName())).decode('ascii')

    property device_class:
        def __get__(self):
            return (<string>(self.dev_info.GetDeviceClass())).decode('ascii')

    def __repr__(self):
        return '<DeviceInfo {1}>'.format(self.serial_number, self.friendly_name)

cdef class _PropertyMap:
    cdef:
        INodeMap* map

    @staticmethod
    cdef create(INodeMap* map):
        obj = _PropertyMap()
        obj.map = map
        return obj

    def get_description(self, basestring key):
        cdef bytes btes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(btes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        return (<string>(node.GetDescription())).decode()


    def get_display_name(self, basestring key):
        cdef bytes btes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(btes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        return (<string>(node.GetDisplayName())).decode()


    def __getitem__(self, basestring key):
        cdef bytes btes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(btes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        if not node_is_readable(node):
            raise IOError('Key is not readable')

        # We need to try different types and check if the dynamic_cast succeeds... UGLY!
        # Potentially we could also use GetPrincipalInterfaceType here.
        cdef IBoolean* boolean_value = dynamic_cast_iboolean_ptr(node)
        if boolean_value != NULL:
            return boolean_value.GetValue()

        cdef IInteger* integer_value = dynamic_cast_iinteger_ptr(node)
        if integer_value != NULL:
            return integer_value.GetValue()

        cdef IFloat* float_value = dynamic_cast_ifloat_ptr(node)
        if float_value != NULL:
            return float_value.GetValue()

        # TODO: Probably we also need some type of enum to be useful

        # Potentially, we can always get the setting by string
        cdef IValue* string_value = dynamic_cast_ivalue_ptr(node)
        if string_value == NULL:
            return

        return (<string>(string_value.ToString())).decode()

    def __setitem__(self, str key, value):
        cdef bytes btes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(btes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        if not node_is_writable(node):
            raise IOError('Key is not writable')

        # We need to try different types and check if the dynamic_cast succeeds... UGLY!
        # Potentially we could also use GetPrincipalInterfaceType here.
        cdef IBoolean* boolean_value = dynamic_cast_iboolean_ptr(node)
        if boolean_value != NULL:
            boolean_value.SetValue(value)
            return

        cdef IInteger* integer_value = dynamic_cast_iinteger_ptr(node)
        if integer_value != NULL:
            if value < integer_value.GetMin() or value > integer_value.GetMax():
                raise ValueError('Parameter value for {} not inside valid range [{}, {}], was {}'.format(
                    key, integer_value.GetMin(), integer_value.GetMax(), value))
            integer_value.SetValue(value)
            return

        cdef IFloat* float_value = dynamic_cast_ifloat_ptr(node)
        if float_value != NULL:
            if value < float_value.GetMin() or value > float_value.GetMax():
                raise ValueError('Parameter value for {} not inside valid range [{}, {}], was {}'.format(
                    key, float_value.GetMin(), float_value.GetMax(), value))
            float_value.SetValue(value)
            return

        # TODO: Probably we also need some type of enum to be useful

        # Potentially, we can always set the setting by string
        cdef IValue* string_value = dynamic_cast_ivalue_ptr(node)
        if string_value == NULL:
            raise RuntimeError('Can not set key %s by string' % key)

        cdef bytes bytes_value = str(value).encode()
        string_value.FromString(gcstring(bytes_value))

    def keys(self):
        node_keys = list()

        # Iterate through the discovered devices
        cdef NodeList_t nodes
        self.map.GetNodes(nodes)

        cdef NodeList_t.iterator it = nodes.begin()
        while it != nodes.end():
            if deref(it).IsFeature() and dynamic_cast_icategory_ptr(deref(it)) == NULL:
                name = (<string>(deref(it).GetName())).decode('ascii')
                node_keys.append(name)
            inc(it)

        return node_keys


cdef class Camera:
    cdef:
        CInstantCamera camera

    @staticmethod
    cdef create(IPylonDevice* device):
        obj = Camera()
        obj.camera.Attach(device)
        return obj

    property device_info:
        def __get__(self):
            dev_inf = DeviceInfo.create(self.camera.GetDeviceInfo())
            return dev_inf

    property opened:
        def __get__(self):
            return self.camera.IsOpen()
        def __set__(self, opened):
            if self.opened and not opened:
                self.camera.Close()
            elif not self.opened and opened:
                self.camera.Open()

    def open(self):
        self.camera.Open()

    def close(self):
        self.camera.Close()

    def __del__(self):
        self.close()
        self.camera.DetachDevice()

    def __repr__(self):
        return '<Camera {0} open={1}>'.format(self.device_info.friendly_name, self.opened)

    def grab_images(self, int nr_images, unsigned int timeout=5000):
        if not self.opened:
            raise RuntimeError('Camera not opened')

        self.camera.StartGrabbing(nr_images)

        cdef CGrabResultPtr ptr_grab_result
        cdef IImage* img

        cdef str image_format = str(self.properties['PixelFormat'])
        cdef str bits_per_pixel_prop = str(self.properties['PixelSize'])
        assert bits_per_pixel_prop.startswith('Bpp'), 'PixelSize property should start with "Bpp"'
        assert image_format.startswith('Mono'), 'Only mono images allowed at this point'
        assert not image_format.endswith('p'), 'Packed data not supported at this point'

        while self.camera.IsGrabbing():
            self.camera.RetrieveResult(timeout, ptr_grab_result)

            if not ACCESS_CGrabResultPtr_GrabSucceeded(ptr_grab_result):
                error_desc = (<string>(ACCESS_CGrabResultPtr_GetErrorDescription(ptr_grab_result))).decode()
                raise RuntimeError(error_desc)

            img = &(<IImage&>ptr_grab_result)
            if not img.IsValid():
                raise RuntimeError('Graped IImage is not valid.')

            if img.GetImageSize() % img.GetHeight():
                print('This image buffer is wired. Probably you will see an error soonish.')
                print('\tBytes:', img.GetImageSize())
                print('\tHeight:', img.GetHeight())
                print('\tWidth:', img.GetWidth())
                print('\tGetPaddingX:', img.GetPaddingX())

            assert not img.GetPaddingX(), 'Image padding not supported.'
            # TODO: Check GetOrientation to fix oritentation of image if required.

            img_data = np.frombuffer((<char*>img.GetBuffer())[:img.GetImageSize()], dtype='uint'+bits_per_pixel_prop[3:])

            # TODO: How to handle multi-byte data here?
            img_data = img_data.reshape((img.GetHeight(), -1))
            # img_data = img_data[:img.GetHeight(), :img.GetWidth()]
            yield img_data

    def grab_image(self, unsigned int timeout=5000):
        return next(self.grab_images(1, timeout))

    property properties:
        def __get__(self):
            return _PropertyMap.create(&self.camera.GetNodeMap())


cdef class Factory:
    def __init__(self):
        PylonInitialize()

    def __dealloc__(self):
        PylonTerminate()

    def find_devices(self):
        cdef CTlFactory* tl_factory = &GetInstance()
        cdef DeviceInfoList_t devices

        cdef int nr_devices = tl_factory.EnumerateDevices(devices)

        found_devices = list()

        # Iterate through the discovered devices
        cdef DeviceInfoList_t.iterator it = devices.begin()
        while it != devices.end():
            found_devices.append(DeviceInfo.create(deref(it)))
            inc(it)

        return found_devices

    def create_device(self, DeviceInfo dev_info):
        cdef CTlFactory* tl_factory = &GetInstance()
        return Camera.create(tl_factory.CreateDevice(dev_info.dev_info))