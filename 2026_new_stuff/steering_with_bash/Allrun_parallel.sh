#!/bin/bash

tm=$1 # setting turbulent model froma a parameter kEpsilon or kOmegaSST
echo "Using turbulent model $tm!"

# Source tutorial clean functions
source $WM_PROJECT_DIR/bin/tools/RunFunctions

# Generate a mesh
runApplication blockMesh

# Decompose the problem
runApplication decomposePar

# Set proper turbulent model
foamDictionary constant/momentumTransport -entry RAS/model -set $tm

# Initialize solution with potentialFoam
cp -r 0_org 0

# Set to start from 0 to end at 500 with SIMPLE solver
foamDictionary system/controlDict -entry startTime -set 0
foamDictionary system/controlDict -entry endTime -set 500
cp -rf system/fvSolution.simple system/fvSolution

# Initialize with potential foam
runApplication potentialFoam -initialiseUBCs -writep

# Run SIMPLE solver
runParallel foamRun
mv log.foamRun log.foamRun_simple

# Run SIMPLE-C from 500 to 2000
foamDictionary system/controlDict -entry startTime -set 500
foamDictionary system/controlDict -entry endTime -set 2000
cp -rf system/fvSolution.simplec system/fvSolution
runParallel foamRun
mv log.foamRun log.foamRun_simplec

# Join parallel solutions of final result
runApplication reconstructPar -latestTime
