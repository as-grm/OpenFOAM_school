Using snappyHexMesh tool for mesh generation

SnappyHexMesh is a three dimensional tool, empty patches are not allowed.
 - Show case 2D with empty patches
 - Show case 2D with symmetryPlane patches

1. generate background mesh: blockMesh
2. generate domain with hole
  - use snappyHexMeshConfig tool, to generate needed files
  - run snappyHexMesh
  - check mesh and preview results

Show 3D case:
  - inside cross must be smaller
  - add layers in blockMeshDict in "z" direction
  - repeat procedure for snappyHexMesh


Fancy corrections of constant/polyMesh/boundary file symmetryPlane -> empty

 - foamDictionary constant/polyMesh/boundary -keywords
 - foamDictionary constant/polyMesh/boundary -entry entry0 -keywords

 Front:
 - foamDictionary constant/polyMesh/boundary -entry entry0/front -keywords
 - foamDictionary constant/polyMesh/boundary -entry entry0/front/type -value
 - foamDictionary constant/polyMesh/boundary -entry entry0/front/type -set empty

 here are two choices, both works
 - foamDictionary constant/polyMesh/boundary -entry entry0/front/inGroups -set "List<word> 1(empty)"
 - foamDictionary constant/polyMesh/boundary -entry entry0/front/inGroups -remove

 Back:
 - foamDictionary constant/polyMesh/boundary -entry entry0/back/type -set empty
 - foamDictionary constant/polyMesh/boundary -entry entry0/back/inGroups -set "List<word> 1(empty)"
