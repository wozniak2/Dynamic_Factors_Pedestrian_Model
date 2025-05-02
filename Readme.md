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
- <a href="https://github.com/NetLogo/Time-Extension" rel="nofollow">Time extension</a>
- nw https://github.com/NetLogo/Network-Extension
- csv
- table https://github.com/NetLogo/Table-Extension

To run the model you need to download and install NetLogo app: https://ccl.northwestern.edu/netlogo/download.shtml.
</br>
The model file should be places together with data folder.

## **How to run sensitivity analysis on the model** 
