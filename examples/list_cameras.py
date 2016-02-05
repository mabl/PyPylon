import pypylon
import matplotlib.pyplot as plt


print('Build against pylon library version:', pypylon.pylon_version.version)

available_cameras = pypylon.factory.find_devices()
print('Available cameras are ', available_cameras)

# Grep the first one and create a camera for it
cam = pypylon.factory.create_device(available_cameras[0])

# We can still get information of the camera back
# print(cam.device_info)

# Open camera and grep some images
cam.open()
for image in cam.grap_images(1):
    plt.imshow(image)
    plt.show()
