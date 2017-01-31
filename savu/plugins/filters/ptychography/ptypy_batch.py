# Copyright 2014 Diamond Light Source Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
.. module:: ptypy_compact
   :platform: Unix
   :synopsis: A plugin to perform ptychography using ptypy

.. moduleauthor:: Aaron Parsons <scientificsoftware@diamond.ac.uk>

"""

import logging
from savu.plugins.utils import register_plugin
from savu.plugins.filters.base_ptycho import BasePtycho
import numpy as np
import ptypy
from ptypy.core import Ptycho
from ptypy import utils as u
from copy import deepcopy as copy

@register_plugin
class PtypyBatch(BasePtycho):
    """
    This plugin performs ptychography using the ptypy package. The same parameter set is used across 
    all slices and is based on the output from a previous reconstruction. 
    :param ptyr_file: The ptyd for a previously successful reconstruction. Default: '/dls/i13-1/data/2016/mt14190-1/processing/tomo_processed/ptycho/dls/i13-1/data/2016/mt14190-1/processing/recons/91372/91372_DM_03002.ptyr'.
    """

    def __init__(self):
        super(PtypyBatch, self).__init__("PtypyBatch")
        
    def pre_process(self):
        self.scan_file = Ptycho.load_run(self.parameters['ptyr_file'],False) # load in the run but without the data
        p = self.scan_file.p
        existing_scan = copy(p.scans[p.scans.keys()[0]])
        del p.scans[p.scans.keys()[0]]# get rid of the old scan since we don't want ot load that.
        p.scans.savu = existing_scan
        p.scans.savu.data.source = 'savu'
        p.scans.savu.data.recipe = u.Param()
        p.ipython_kernel = False
        p.scans.savu.data.dfile = None
        p.scans.savu.data.save = None
        p.io.autoplot.dump = False 
        p.io.autoplot.make_movie = False
        p.io.autoplot.interval = -1
        p.scan.illumination = self.scan_file.probe.storages['S00G00'].data
        p.engines.engine_00.numiter = 1
        self.p = p

    def filter_frames(self, data):
        k=0
        idx = self.get_global_frame_index()[0]
        print "The slice list is:",self.get_current_slice_list()[0][0].start
        print "The full idx is ",str(idx)
        d = data[0]
        # the current frame
        print "the index is:",str(idx[k]) 
        print len(data)
        print (data[0].shape)
        p = self.p
        p.scans.savu.data.recipe.data = d
        ix=idx[k]
        print ix
        positions = self.get_positions()[ix].T
        print "The positions shape is:"+str(positions.shape)
        p.scans.savu.data.recipe.positions = positions
#         self.p.scans.savu.data.recipe = self.r
        P = Ptycho(self.p,level=5)
        object_stack = P.obj.storages['S00G00'].data
        probe_stack = P.probe.storages['S00G00'].data[0]
        sh = probe_stack.shape
        print "the probe shape is:",str(sh)
#         probe_stack = np.reshape(probe_stack,sh[1:]+(sh[0],))
        k+=1
        return [probe_stack, object_stack, positions]#] add fourier error, realspace error

    def setup(self):
        self.scan_file = Ptycho.load_run(self.parameters['ptyr_file'],False)
        self.p = self.scan_file.p
        in_dataset, out_dataset = self.get_datasets()
        in_meta_data = in_dataset[0].meta_data.get_dictionary()
        self.not_tomo = False
        if 'rotation_angle' not in in_meta_data.keys():
            self.not_tomo = True

        BasePtycho.setup(self)

    def get_num_probe_modes(self):
        return 1

    def set_size_object(self, in_d1, positions, pobj):
        sh = self.scan_file.probe.storages['S00G00'].data.shape
        if self.not_tomo:
            self.obj_shape = (1,)+sh[1:]+(sh[0],)
        else:
            self.obj_shape = sh[1:]+(sh[0],)
        print "object shape is" + str(self.obj_shape)
    
    def set_size_probe(self, probe_shape):
        sh = self.scan_file.probe.storages['S00G00'].data.shape
        self.probe_size = (1,)+sh[1:]
        print "probe size is" + str(self.probe_size)

