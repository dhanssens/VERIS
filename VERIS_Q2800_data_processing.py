#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
	VERIS Q2800 DATA PROCESSING
	===========================
	ORBit, Ghent University, 2019
	Daan Hanssens

	Data-processing for VERIS Q2800 data.
	Note: ORBit module has to be included in path.
"""

# Import
import matplotlib.pyplot as plt
import ORBit
import pandas as pd
import utm


########################################################
# USER-INPUT
# ----------
#

# VERIS datafile
filename = 'data/VSECmarie.DAT'

# Distance sensor - GPS
sensor_gps_distance = 1.1  # (m)

# GPS antenna height
antenna_height = 1.45  # (m)

# Cell size and buffer for blank
cell_size = .2  # (m)
buffer = 2  # (m)

# Save data?
save_data = True  # True or False

# Coordinate system
change_wgs_to_utm = True


########################################################
# DATA
# ----
#

# Grab data
data = pd.read_csv(filename, sep='\t', header=None, names=['x', 'y', 'eca30', 'eca90', 'z'])

# Drop errors
data = data[~(data['eca30'] <= 0)]
data = data[~(data['eca90'] <= 0)]

# Calculate from WGS to UTM
if change_wgs_to_utm:
    for ii in range(data['x'].count()):
        data['x'].iloc[ii], data['y'].iloc[ii], _, _ = utm.from_latlon(
            data['y'].iloc[ii],
            data['x'].iloc[ii]
        )


########################################################
# SPATIAL CORRECTIONS
# -------------------
#

# Shift data
data.loc[:, ['x', 'y']] = ORBit.Spatial.shift_tractrix(data['x'].values, data['y'].values, sensor_gps_distance, 0, 0)

# Shift height
data.loc[:, ['z']] -= antenna_height

# Save to common
data.to_csv('common.csv')


########################################################
# INTERPOLATION
# -------------
#

# Create blank
blank = ORBit.Initialize.Blank(data['x'].values, data['y'].values, cell_size, buffer)

# Grid data
eca30_grd = ORBit.Spatial.natural_neighbor(data['x'].values, data['y'].values, data['eca30'].values, blank)
eca90_grd = ORBit.Spatial.natural_neighbor(data['x'].values, data['y'].values, data['eca90'].values, blank)


########################################################
# VISUALIZE
# ---------
#

# Visualize ECa 30
plt.figure()
plt.title('ECa 30')
plt.imshow(eca30_grd, origin='lower', extent=blank.extent, cmap='RdBu_r')
plt.xlabel('UTM X (m)'), plt.ylabel('UTM Y (m)')
plt.colorbar().set_label('ECa (mS/m)')
plt.clim(0, 50)
plt.axis('equal')

# Visualize ECa 90
plt.figure()
plt.title('ECa 90')
plt.imshow(eca90_grd, origin='lower', extent=blank.extent, cmap='RdBu_r')
plt.xlabel('UTM X (m)'), plt.ylabel('UTM Y (m)')
plt.colorbar().set_label('ECa (mS/m)')
plt.clim(0, 120)
plt.axis('equal')
ORBit.Other.save_figure('figs/eca90')