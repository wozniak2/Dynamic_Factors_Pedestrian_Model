# -*- coding: utf-8 -*-
"""

Script file for simulation and sensitivity analysis of NetLogo Pedestrian Model

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
    "num_vars": 8,
    "names": [
        "attractor-strength",
        "repeller-strength",
         "crowd-tolerance",
         "noise-intensity",
         "trip-distance",
         "GIS-distance",
         "spontaneousness",
         "discount-rate",
    ],
    
    "bounds": [
        [0, 1],
        [0, 1],
        [1, 10],
        [0, 42],
        [10, 100],
        [0, 10],
        [0, 1],
        [0, 1],
    ],
    
}

# The sampler generates an input array of shape (n(2p+2), p) with rows 
# for each experiment and columns for each input parameter.
# Should be more; 10 is for tests

n = 25
param_values = saltelli.sample(problem, n, calc_second_order=True)

# Start engines (6 cores)
# Run in anaconda shell: ipcluster start -n 6

import ipyparallel

client = ipyparallel.Client()
client.ids

direct_view = client[:]

import os
# Change the current working directory to parent dir
os.chdir('C:/Users/wozni/OneDrive/Documents/GitHub/NetLogo_Pedestrian_Model')

# Push the current working directory of the notebook to a "cwd" variable on the engines that can be accessed later
direct_view.push(dict(cwd=os.getcwd()))

# Push the "problem" variable from the notebook to a corresponding variable on the engines
direct_view.push(dict(problem=problem))

# run in parallell
%%px 

import os
os.chdir(cwd)

import pynetlogo
import pandas as pd

netlogo = pynetlogo.NetLogoLink(gui=False)

# Load the Model
netlogo.load_model('C:/Users/wozni/OneDrive/Documents/GitHub/NetLogo_Pedestrian_Model/simAllTypesMultiple_SA_rev1.nlogo')


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
    # Run for 700 ticks and return the number of walkers at each time step;
    # all agents should find destinations till then
    counts = netlogo.repeat_report(["simdist", "simtime"], 1200)


    results = pd.Series(
        [counts["simdist"].mean(), counts["simtime"].mean()],
        index=["Avg. distances", "Avg. times"],
    )
     
    return results

lview = client.load_balanced_view()
results = pd.DataFrame(lview.map_sync(simulation, param_values))
results.to_csv("./Sobol_parallel.csv")

# results.iloc[1,0].mean()

netlogo.kill_workspace()


import scipy
import numpy as np
import matplotlib.pyplot as plt


nrow = len(results.columns)
ncol = len(problem["names"])

fig, (ax1, ax2) = plt.subplots(nrow, ncol)
y = results["Avg. distances"]
z = results["Avg. times"]

for i, ax1 in enumerate(ax1.flatten()):
    x = param_values[:, i]
    sns.regplot(
        x=x,
        y=y,
        ax=ax1,
        ci=None,
        color="k",
        scatter_kws={"alpha": 0.2, "s": 4, "color": "gray"},
    )
    pearson = scipy.stats.pearsonr(x, y)
    ax1.annotate(
        "r: {:6.3f}".format(pearson[0]),
        xy=(0.15, 0.85),
        xycoords="axes fraction",
        fontsize=13,
    )
    if divmod(i, ncol)[1] > 0:
        ax1.get_yaxis().set_visible(False)
#       ax1.set_xlabel(problem["names"][i])
    ax1.set_ylim([0, 1.1 * np.max(y)])
  
   
for i, ax2 in enumerate(ax2.flatten()):
    x = param_values[:, i]
    sns.regplot(
        x=x,
        y=z,
        ax=ax2,
        ci=None,
        color="k",
        scatter_kws={"alpha": 0.2, "s": 4, "color": "gray"},
    )
    pearson = scipy.stats.pearsonr(x, z)
    ax2.annotate(
        "r: {:6.3f}".format(pearson[0]),
        xy=(0.15, 0.85),
        xycoords="axes fraction",
        fontsize=13,
    )
    if divmod(i, ncol)[1] > 0:
        ax2.get_yaxis().set_visible(False)
    ax2.set_xlabel(problem["names"][i], fontsize=14)
    ax2.set_ylim([0, 1.1 * np.max(z)])

fig.set_size_inches(9, 7, forward=True)
fig.subplots_adjust(wspace=0.2, hspace=0.2)

plt.show()


Si = sobol.analyze(
    problem,
    results["Avg. distances"].values,
    calc_second_order=True,
    print_to_console=False,
)


Si_filter = {k: Si[k] for k in ["ST", "ST_conf", "S1", "S1_conf"]}
Si_df = pd.DataFrame(Si_filter, index=problem["names"])

fig, ax = plt.subplots(1)

indices = Si_df[["S1", "ST"]]
err = Si_df[["S1_conf", "ST_conf"]]

indices.plot.bar(yerr=err.values.T, ax=ax)
fig.set_size_inches(8, 4)

plt.show()
