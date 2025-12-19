import numpy as np
import time

try:
    from IO import nidaq as iodaq
except Exception as e:
    print(e)

ao = iodaq.AnalogOutput('Dev1', channels=[0], voltage_range=[0.0, 5.0])

print('starting')
ao.start()

# turn on LED
ao.write(np.array([5]).astype(np.float64))

# wait for recording
time.sleep(800)

# turn off LED
ao.write(np.array([0]).astype(np.float64))

ao.clear()
print('Done')
