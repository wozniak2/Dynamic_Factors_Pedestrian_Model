# -*- coding: utf-8 -*-
"""

Script file for simulation and sensitivity analysis of NetLogo Pedestrian Model

"""
from datetime import *
datetime.strptime('0228', '%m%d')
time.strptime('0229', '%m%d')[1:3]


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
         "crowd-intensity",
         "noise-intensity",
         "trip-distance",
         "GIS-distance",
         "route-variability",
         "segment-weight",
    ],
    
    "bounds": [
        [0, 1],
        [0, 1],
        [1, 12],
        [0, 42],
        [40, 200],
        [1, 20],
        [0, 0.7],
        [0.1, 1],
    ],
    
}

# The sampler generates an input array of shape (n(2p+2), p) with rows 
# for each experiment and columns for each input parameter.
# Should be more; 10 is for tests

n = 15
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
netlogo.load_model('C:/Users/wozni/OneDrive/Documents/GitHub/NetLogo_Pedestrian_Model/simAllTypes_SA.nlogo')


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
    counts = netlogo.repeat_report(["simdist", "simtime", "heterogeneity"], 2200)


    results = pd.Series(
        [counts["simdist"].mean(), counts["simtime"].mean(), counts["heterogeneity"].mean()],
        index=["Avg. distances", "Avg. times", "Heterogeneity"],
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


#nrow = len(results.columns)
#ncol = len(problem["names"])

# plot distances

nrow = 2
ncol = 4

fig, ax = plt.subplots(nrow, ncol, sharey = True)
#fig, (ax1, ax2) = plt.subplots(nrow, ncol)
y = results["Avg. distances"]
#z = results["Avg. times"]

for i, ax in enumerate(ax.flatten()):
    x = param_values[:, i]
    sns.regplot(
        x=x,
        y=y,
        ax=ax,
        ci=None,
        color="k",
        scatter_kws={"alpha": 0.2, "s": 4, "color": "gray"},
    )
    pearson = scipy.stats.pearsonr(x, y)
    ax.annotate(
        "r: {:6.3f}".format(pearson[0]),
        xy=(0.15, 0.85),
        xycoords="axes fraction",
        fontsize=17,
    )
    if divmod(i, ncol)[1] > 0:
        ax.get_yaxis().set_visible(False)
    ax.set_xlabel(problem["names"][i])
    ax.set_ylim([0, 1.1 * np.max(y)])
  
fig.set_size_inches(11, 5, forward=True)
fig.subplots_adjust(wspace=0.3, hspace=0.45)

plt.show() 


# plot times

nrow = 2
ncol = 4

fig, ax = plt.subplots(nrow, ncol, sharey = True)
#fig, (ax1, ax2) = plt.subplots(nrow, ncol)
y = results["Avg. times"]
#z = results["Avg. times"]

for i, ax in enumerate(ax.flatten()):
    x = param_values[:, i]
    sns.regplot(
        x=x,
        y=y,
        ax=ax,
        ci=None,
        color="k",
        scatter_kws={"alpha": 0.2, "s": 4, "color": "gray"},
    )
    pearson = scipy.stats.pearsonr(x, y)
    ax.annotate(
        "r: {:6.3f}".format(pearson[0]),
        xy=(0.15, 0.85),
        xycoords="axes fraction",
        fontsize=17,
    )
    if divmod(i, ncol)[1] > 0:
        ax.get_yaxis().set_visible(False)
    ax.set_xlabel(problem["names"][i])
    ax.set_ylim([0, 1.1 * np.max(y)])
  
fig.set_size_inches(11, 5, forward=True)
fig.subplots_adjust(wspace=0.3, hspace=0.45)

plt.show() 


# plot heterogeneity

nrow = 2
ncol = 4

fig, ax = plt.subplots(nrow, ncol, sharey = True)
#fig, (ax1, ax2) = plt.subplots(nrow, ncol)
y = results["Heterogeneity"]
#z = results["Avg. times"]

for i, ax in enumerate(ax.flatten()):
    x = param_values[:, i]
    sns.regplot(
        x=x,
        y=y,
        ax=ax,
        ci=None,
        color="k",
        scatter_kws={"alpha": 0.2, "s": 4, "color": "gray"},
    )
    pearson = scipy.stats.pearsonr(x, y)
    ax.annotate(
        "r: {:6.3f}".format(pearson[0]),
        xy=(0.15, 0.85),
        xycoords="axes fraction",
        fontsize=17,
    )
    if divmod(i, ncol)[1] > 0:
        ax.get_yaxis().set_visible(False)
    ax.set_xlabel(problem["names"][i])
    ax.set_ylim([0, 1.1 * np.max(y)])
  
fig.set_size_inches(11, 5, forward=True)
fig.subplots_adjust(wspace=0.3, hspace=0.45)

plt.show() 



# Combinded plot - for tests only

  
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

fig.set_size_inches(16, 7, forward=True)
fig.subplots_adjust(wspace=0.2, hspace=0.2)

plt.show()


Si = sobol.analyze(
    problem,
    results["Heterogeneity"].values,
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


###############################################
###############################################
###############################################


import itertools
from math import pi

#sobol_indices = Si

def normalize(x, xmin, xmax):
    return (x-xmin + 0.00000001)/(xmax-xmin+ 0.00000001)





def plot_circles(ax, locs, names, max_s, stats, smax, smin, fc, ec, lw, 
                 zorder):
    s = np.asarray([stats[name] for name in names])
    s = 0.01 + max_s * np.sqrt(normalize(s, smin, smax))
    
    fill = True
    for loc, name, si in zip(locs, names, s):
        if fc=='w':
            fill=False
        else:
            ec='none'
            
        x = np.cos(loc)
        y = np.sin(loc)
        
        circle = plt.Circle((x,y), radius=si, ec=ec, fc=fc, transform=ax.transData._b,
                            zorder=zorder, lw=lw, fill=True)
        ax.add_artist(circle)
    
    
    
    
    
## Create filtered_names, filtered_locs

def filter(sobol_indices, names, locs, criterion, threshold):
    if criterion in ['ST', 'S1', 'S2']:
        data = sobol_indices[criterion]
        data = np.abs(data)
        data = data.flatten() # flatten in case of S2
        
        # TODO:: remove nans
        
        filtered = ([(name, locs[i]) for i, name in enumerate(names) if data[i]>threshold])
        filtered_names, filtered_locs = zip(*filtered) 
    
    elif criterion in ['ST_conf', 'S1_conf', 'S2_conf']:
        raise NotImplementedError
    else:
        raise ValueError('unknown value for criterion')

    return filtered_names, filtered_locs



#######
## Main
########
def plot_sobol_indices(sobol_indices, criterion='ST', threshold=0.2):
    
    '''plot sobol indices on a radial plot
    
    Parameters
    ----------
    sobol_indices : dict
                    the return from SAlib
    criterion : {'ST', 'S1', 'S2', 'ST_conf', 'S1_conf', 'S2_conf'}, optional
    threshold : float
                only visualize variables with criterion larger than cutoff
             
    '''
    max_linewidth_s2 = 15#25*1.8
    max_s_radius = 0.18
    
    # prepare data
    # use the absolute values of all the indices
    # sobol_indices = {key:np.abs(stats) for key, stats in sobol_indices.items()}
    
    # dataframe with ST and S1
    sobol_stats = {key:sobol_indices[key] for key in ['ST', 'S1']}
    sobol_stats = pd.DataFrame(sobol_stats, index=problem['names'])

    smax = sobol_stats.max().max()
    smin = sobol_stats.min().min()
 


    # dataframe with s2
    s2 = pd.DataFrame(sobol_indices['S2'], index=problem['names'], 
                      columns=problem['names'])
 #   s2[s2<0.0]=0.000 #Set negative values to 0 (artifact from small sample sizes)
    s2max = s2.max().max()
    s2min = s2.min().min()

    names = problem['names']
    n = len(names)
    ticklocs = np.linspace(0, 2*pi, n+1)
    locs = ticklocs[0:-1]

    filtered_names, filtered_locs = filter(sobol_indices, names, locs,
                                           criterion, threshold)
    
    
####################    
####################    
# setup figure
####################
#####################

    fig = plt.figure()
    ax = fig.add_subplot(111, polar=True)
    ax.grid(False)
    ax.spines['polar'].set_visible(False)
    ax.set_xticks(locs)                         ##  Fixed ##

    ax.set_xticklabels(names, fontsize=21)                     
    ax.set_yticklabels([]) 
    ax.set_ylim(top=1.4)
    legend(ax)

    # plot ST
    plot_circles(ax, filtered_locs, filtered_names, max_s_radius, 
                 sobol_stats['ST'], smax, smin, 'w', 'k', 1, 3)

    # plot S1
    plot_circles(ax, filtered_locs, filtered_names, max_s_radius, 
                 sobol_stats['S1'], smax, smin, 'k', 'k', 1, 4)

    # plot S2
    for name1, name2 in itertools.combinations(zip(filtered_names, filtered_locs), 2):
        name1, loc1 = name1
        name2, loc2 = name2

        weight = s2.loc[name1, name2]
        lw = 0.5+max_linewidth_s2*normalize(weight, s2min, s2max)
 #       lw = 0.5+max_linewidth_s2*scipy.stats.zscore(weight)
        ax.plot([loc1, loc2], [1,1], c='darkgray', lw=lw, zorder=1)

    return fig


from matplotlib.legend_handler import HandlerPatch
class HandlerCircle(HandlerPatch):
    def create_artists(self, legend, orig_handle,
                       xdescent, ydescent, width, height, fontsize, trans):
        center = 0.2 * width - 0.2 * xdescent, 0.2 * height - 0.2 * ydescent
        p = plt.Circle(xy=center, radius=orig_handle.radius)
        self.update_prop(p, orig_handle, legend)
        p.set_transform(trans)
        return [p]

def legend(ax):
    some_identifiers = [plt.Circle((0,0), radius=17, color='k', fill=False, lw=1),
                        plt.Circle((0,0), radius=17, color='k', fill=True),
                        plt.Line2D([0,0.5], [0,0.5], lw=17, color='darkgray')]
    ax.legend(some_identifiers, ['ST', 'S1', 'S2'], fontsize=27,
              loc=(0.95,0.95), borderaxespad=3.5, mode='',
              handler_map={plt.Circle: HandlerCircle()})
    
    
## plot   

#sns.set_style('whitegrid')

fig = plot_sobol_indices(Si, criterion='ST', threshold=0.005)
#plt.title("Heterogeneity", fontsize=35)
fig.set_size_inches(17,15)
plt.show() 








