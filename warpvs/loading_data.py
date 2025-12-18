# -*- coding: utf-8 -*-
"""
Created on Fri Dec  5 13:22:33 2025

@author: ys2605
"""

import pickle as pkl

#%%

fpath = 'C:/data/visual_display_log/'
fname = '251205114733-DriftingGratingCircle-MTest-Name-000-notTriggered-complete.pkl'


with open(fpath + fname, 'rb') as file:
    loaded_data = pkl.load(file)
    
    
