# -*- coding: utf-8 -*-
"""
Created on Fri Nov  8 18:01:04 2024

@author: wozni
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_style("white")
sns.set_context("talk")

import pynetlogo

# Import the sampling and analysis modules for a Sobol variance-based
# sensitivity analysis
from SALib.sample import saltelli
from SALib.analyze import sobol

problem = {
    "num_vars": 6,
    "names": [
        "random-seed",
        "grass-regrowth-time",
        "sheep-gain-from-food",
        "wolf-gain-from-food",
        "sheep-reproduce",
        "wolf-reproduce",
    ],
    "bounds": [
        [1, 100000],
        [20.0, 40.0],
        [2.0, 8.0],
        [16.0, 32.0],
        [2.0, 8.0],
        [2.0, 8.0],
    ],
}


n = 10
param_values = saltelli.sample(problem, n, calc_second_order=True)

# ipcluster start -n 4

import ipyparallel

client = ipyparallel.Client()
client.ids

direct_view = client[:]

import os

# Push the current working directory of the notebook to a "cwd" variable on the engines that can be accessed later
direct_view.push(dict(cwd=os.getcwd()))

# Push the "problem" variable from the notebook to a corresponding variable on the engines
direct_view.push(dict(problem=problem))

%%px 

import os
os.chdir(cwd)

import pynetlogo
import pandas as pd

netlogo = pynetlogo.NetLogoLink(gui=True)
netlogo.load_model('C:/Program Files/NetLogo 6.4.0/models/Sample Models/Biology/Wolf Sheep Predation_v6.nlogo')

def simulation(experiment):

    # Set the input parameters
    for i, name in enumerate(problem["names"]):
        if name == "random-seed":
            # The NetLogo random seed requires a different syntax
            netlogo.command("random-seed {}".format(experiment[i]))
        else:
            # Otherwise, assume the input parameters are global variables
            netlogo.command("set {0} {1}".format(name, experiment[i]))

    netlogo.command("setup")
    # Run for 100 ticks and return the number of sheep and wolf agents at each time step
    counts = netlogo.repeat_report(["count sheep", "count wolves"], 100)

    results = pd.Series(
        [counts["count sheep"].mean(), counts["count wolves"].mean()],
        index=["Avg. sheep", "Avg. wolves"],
   )

#    results = [counts["count sheep"].values.mean()]

    return results

#type(results[:, "Avg.sheep"])
#results.iloc[:, 0].mean()
#results

lview = client.load_balanced_view()

results = pd.DataFrame(lview.map_sync(simulation, param_values))
netlogo.kill_workspace()
