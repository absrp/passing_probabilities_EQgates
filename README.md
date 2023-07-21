# passing_probabilities_EQgates
A set of scripts to estimate the geometry of earthquake gates and passing probabilities as a function of geometry

<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->


<!-- ABOUT THE PROJECT -->
## About The Project
Earthquake gates act as barriers to rupture propagation, where material properties, rupture dynamics, and the availability and geometry of neighboring faults control the probability of throughgoing rupture. We map step-overs, bends, gaps, splays, and strands from the surface ruptures of 31 strike-slip earthquakes at 1:50,000 scale, classifying each population into breached and unbreached groups. We calculate passing probability as a function of geometry for each group. Step-overs, gaps, and single bends halt ruptures more effectively than double bends, and $<$20\% of the ruptures stopped on straight segments. Based on our modeled probabilities, we estimate event likelihood as the joint passing probabilities of breached gates and straight segments along an event's rupture length. Event likelihood decreases with magnitude, where the size and spacing of earthquake gates along ruptures support a barrier model for controlling earthquake magnitude. Our probabilities may be used to validate barrier breaching frequencies in long-term rupture simulators.


<!-- GETTING STARTED -->
## Getting Started

This repository contains the scripts and data required to reproduce the results in Rodriguez Padilla et al. 202X, and to measure the geometry and passing probabilities of different types of earthquake gates. 

The data for running this analysis are stored in a separate repository that is also open-access (). All figures in the manuscript can be generated using these scripts and data. 

### Prerequisites

The subset of the scripts that measure the geometry of earthquake gates from shapefiles are in Matlab and require the Matlab Mapping Toolbox. Some of the scripts rely on functions downloable from Mathworks. The specific dependencies for each Matlab script to run are listed at the beginning of the corresponding script. The scripts for estimating passing probabilities and event likelihood are available as Python Jupyter Notebooks.


<!-- ROADMAP -->
### Measuring earthquake gate geometry and estimating passing probabilities

- [ ] To measure the geometry of earthquake gates in a shapefile
    - [ ] Run the "measure_EQ_gates" Matlab script (must run in directory containing shapefiles)
    - [ ] This will output a csv file with the characterized gates

- [ ] To estimate passing probabilities
    - [ ] Run the "EQ_gates.ipynb" Jupyter Notebook. Requires the csv containing the gate geometries. 
    - [ ] This will output the figures 3 onwards on the manuscript.

<!-- CONTACT -->
## Contact

Please report suggestions and issues:

[@_absrp](https://twitter.com/_absrp) - arodriguezpadilla@ucdavis.edu

Project Link: [https://github.com/absrp/PFDHA_strikeslip](https://github.com/absrp/PFDHA_strikeslip)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

Manuscript Link: * in review, stay tuned *



