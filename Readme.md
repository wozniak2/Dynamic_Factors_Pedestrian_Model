# Dynamic Factors NetLogo Pedestrian Model
The model simulates pedestrian traffic in the city center od Poznan (Poland).
The model is parameterised according to emprical study that identified 5 different types of pedestrians: rational walker, maintainer, landmark, environmental and spontaneous.
Each types is characterised by different behavioural routines that are assocciated with "repellers" and "attractors" that are elements of urban morphology.
Dynamic factors are repellers that are volatile stimuli arising from social or natural environments. The model implement crowd and noise as dynamic factors that can be encounter quite often during everyday walks accross the city.

## **Inside:** 
- **SA** folder with sensitivity analysis scripts (Python) for NetLogo model
- **Data** folder with shapefiles (not all of them are necesssary)
- **simAllTypesMultiple_SA_rev1** NetLogo file

## **How to run the model**
The model was implemented in NetLogo 6.4 which is a multi-agent programmable modeling environment.
The model uses following NetLogo extensions:
- <a href="https://github.com/NetLogo/GIS-Extension" rel="nofollow">GIS extension</a>
- <a href="https://github.com/NetLogo/Network-Extension" rel="nofollow">Network extension</a>
- <a href="https://github.com/NetLogo/CSV-Extension" rel="nofollow">CSV extension</a>
- <a href="https://github.com/NetLogo/Table-Extension" rel="nofollow">Table extension</a>

To run the model you need to download and install NetLogo app: https://ccl.northwestern.edu/netlogo/download.shtml.
</br>
The model file should be places together with data folder.
The model produces trajectories patterns accross 5 types of pedestrians.
Manipulating model parameters allows for introduction of dynamic factors and some other parameters assocciated with route choice behaviour.

## **How to run sensitivity analysis on the model** 
Sensitivity Analyis (SA) is fully driven from Python. You will need Python distribution, e.g. <a href="https://www.anaconda.com/docs/getting-started/miniconda/main" rel="nofollow">Miniconda</a> with <a href="https://github.com/quaquel/pyNetLogo" rel="nofollow">PyNetLogo library</a> to access NetLogo from Python.
Additionally <a href="https://pypi.org/project/SALib/" rel="nofollow">SAlib library</a> that contains Python implementations of commonly used sensitivity analysis methods is required.
