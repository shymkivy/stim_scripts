import numpy as np
import time
from PyDAQmx import *

ao = Task()

ao.CreateAOVoltageChan("Dev1/ao0","",0,5, DAQmx_Val_Volts,None)

data = np.zeros((10,), dtype=np.float64)


ao.StartTask()


ao.WriteAnalogF64(int(len(data)/1), 0, -1, DAQmx_Val_GroupByScanNumber, data, None, None)

time.sleep(1)

ao.WriteAnalogF64(int(len(data)/1), 0, -1, DAQmx_Val_GroupByScanNumber, data, None, None)
