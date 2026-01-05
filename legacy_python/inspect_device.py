import tidevice
from tidevice._device import Device

print("Methods in Device:")
for m in dir(Device):
    if not m.startswith("_"):
        print(m)
