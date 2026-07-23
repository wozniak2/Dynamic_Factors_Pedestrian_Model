# NetLogo Pedestrian Model — Dynamic Factors (Crowd & Noise)

An Agent-Based Model (ABM) of pedestrian route choice in the city centre of Poznań, Poland, built in [NetLogo](https://ccl.northwestern.edu/netlogo/). Agents choose routes between origin–destination pairs based on the urban environment (streets, green spaces, landmarks, POIs) and their individual sensitivity to **dynamic factors** — crowding and noise — two transient, socially/naturally generated stimuli that are usually left out of pedestrian ABMs.

This repository contains the model, code, and sensitivity-analysis pipeline behind:

> Wozniak, M., & Filomena, G. (2026). **Beyond urban form: Introducing dynamic factors in agent-based simulations of pedestrian movement.** *Computers, Environment and Urban Systems, 128*, 102439. https://doi.org/10.1016/j.compenvurbsys.2026.102439 (open access)

If you use this model or code, please cite the paper above.

## What the model does

Agents represent five empirically-derived pedestrian types, each with a distinct profile of sensitivity to **attractors** (tourist/historic places, landmarks, green spaces, amenities/shops, non-signalised crossings) and **repellers** (noise, embankments/walls, construction sites, signalised crossings, crowding):

| Type | Description |
|---|---|
| **Rational** | Minimises distance/path complexity; largely insensitive to urban elements and dynamic factors |
| **Maintainer** | Avoids crowded, noisy areas; favours green spaces, calm and aesthetically pleasing streets |
| **Environmental** | Guided by natural elements, global landmarks, and straight, legible routes |
| **Landmark** | Relies on an accurate cognitive map anchored to global/local landmarks and POIs |
| **Spontaneous** | Exploratory and unpredictable, influenced by personal/symbolic stimuli and on-the-fly detours |

Each agent plans a route in two phases: **prospective planning** (a Dijkstra-based shortest-utility path over the street network, weighted by the agent's attractor/repeller preferences) and **situated planning** (en-route adjustments, e.g. slowing down or detouring around real-time crowding). Crowding is generated dynamically around POIs using Google Popular Times data; noise is represented as street segments exceeding 55 dB.

The model outputs, per agent, the walked route (length, geometry) and, in aggregate, the distribution of pedestrian volumes across the street network — allowing comparison between a **benchmark** configuration (no sensitivity to crowd/noise) and an **experimental** configuration (agents that do respond to dynamic factors).

## Repository contents

| Path | Description |
|---|---|
| [`simAllTypes_clean.nlogo`](simAllTypes_clean.nlogo) | Main NetLogo model: simulates the 5 pedestrian types over the Poznań street network |
| [`simAllTypes_SA.nlogo`](simAllTypes_SA.nlogo) | Variant of the model set up for sensitivity analysis (parameters exposed for external driving via Python) |
| [`SA/sensitivity.py`](SA/sensitivity.py) | Python script driving the sensitivity analysis: Saltelli sampling and Sobol variance-based analysis (via [SALib](https://github.com/SALib/SALib)) run against the NetLogo model through [PyNetLogo](https://github.com/quaquel/pynetlogo), parallelised with `ipyparallel` |
| [`data/`](data) | GIS input layers (shapefiles/geopackages) for the Poznań case study area: buildings, POIs, green spaces, landmarks, noise, crossings, construction sites, walls, trees, tram/transit data, and Google Popular Times crowd data. Not all layers are required to run the base model |

## How to run the model

1. Install [NetLogo 6.4](https://ccl.northwestern.edu/netlogo/download.shtml).
2. Keep `simAllTypes_clean.nlogo` in the same parent folder as the `data/` directory (the model loads GIS layers via relative paths).
3. Open the model in NetLogo and use the interface to set global parameters (crowd intensity, noise propagation, route variability, etc.) and run the simulation.

The model requires the following bundled NetLogo extensions (no separate install needed beyond NetLogo itself):
- [GIS extension](https://github.com/NetLogo/GIS-Extension)
- [Network extension](https://github.com/NetLogo/Network-Extension)
- [CSV extension](https://github.com/NetLogo/CSV-Extension)
- [Table extension](https://github.com/NetLogo/Table-Extension)

Running the model produces walked trajectories for each of the five pedestrian types; varying the global parameters (crowd intensity, noise propagation, route variability, etc.) lets you turn dynamic factors on/off and observe their effect on individual routes and network-wide movement patterns.

## How to run the sensitivity analysis

The sensitivity analysis (`SA/sensitivity.py`) drives `simAllTypes_SA.nlogo` from Python using a Sobol/Saltelli variance-based design over 8 model parameters (attractor/repeller sensitivity, crowd intensity, noise propagation, Euclidean OD distance, node-stimulus distance, route variability, segment cost weight).

Requirements:
- A Python distribution, e.g. [Miniconda](https://www.anaconda.com/docs/getting-started/miniconda/main)
- [PyNetLogo](https://github.com/quaquel/pynetlogo) — connects Python to a running NetLogo instance
- [SALib](https://pypi.org/project/SALib/) — sampling and sensitivity-analysis methods
- `ipyparallel` — parallelises runs across multiple NetLogo instances/cores (start engines first, e.g. `ipcluster start -n 6`)

Update the hardcoded working directory near the top of `SA/sensitivity.py` to your local clone path before running.

## Data availability

The empirical pedestrian typology, GPS trajectories, and analysis scripts referenced in the paper are documented in the paper's [GitHub Repository](https://github.com/wozniak2/NetLogo_Pedestrian_Model) (this repository) and dataset link.

## Related work

- Wozniak, M., Filomena, G., & Wronkowski, A. (2025). What's your type? A taxonomy of pedestrian route choice behaviour in cities. *Transportation Research Part F: Traffic Psychology and Behaviour, 109*, 1257–1274. https://doi.org/10.1016/j.trf.2025.01.012
