# **OpenFOAM 3-day school**

- **Date:** Year cycle
- **Place:** OnLine - University of Ljubljana, Faculty of Mechanical Engineering, HPC Lab (LECAD)
- **Author:** Aleksander Sandro GRM (aleksander.grm@fpp.uni-lj.si)

---
## Content

**Day 1 - Introduction**
 - Introduction to PDEs, Introduction to ParaView, OpenFOAM structure
 - Run a simple cavity example

**Day 2 - Basics and Meshing**
 - Meshing in OpenFOAM: [BlockMesh](https://doc.cfd.direct/openfoam/user-guide-v12/blockmesh), [SnappyHexMesh](https://doc.cfd.direct/openfoam/user-guide-v12/snappyhexmesh), [GMSH](https://gmsh.info/)
 - Show how to use blockMesh: work on simple examples
 - Show how to use GMSH: work on simple examples
 - Show how to use snappyHexkMesh: work on simple examples
 - Introduction to *Turbulent flow*
   - Basics of turbulent flow
   - Computation of turbulent mesh resolution
   - Demonstration of advanced *cavity with hole* case (simulation of flow around a tennis ball)
     - BlockMesh and GMS case
     - turbulent flow: steady and transient solution with $k-\omega$ SST turbulent model

**Day 3 - Different case study**
 - Advanced use of OpenFOAM
   - time-dependent boundary condition
   - post-processing tools
 - Demonstration of advanced simulations of fluid flow around NACA00XX profile for different angles of attack
   - BlockMesh and GMS case
   - turbulent flow: steady and transient solution
- Simple mixer
   - introduction to **baffles** (2d surfaces in 3D space)
   - combination of steady-state and transient cases
   - advanced result presentation
- Ship resistance
   - introduction to multiphase simulations
- Propeller analysis
   - introduction to Multi Reference Frame system (MRF)  

**Tools an Literature**
 - description of standard tools: OpenFOAM, Python and HPC
 - relevant literature for the course

---
## Introduction

OpenFOAM basics, three-day school in combination with basics of **HPC Linux** environment. 

---
 
## OpenFOAM code

The current version of sources works for OpenFOAM version 12, downloaded from [openfoam.org](https://openfoam.org).  
