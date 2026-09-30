// Generate cross type geometry and STL mesh

z0 = -0.005;
Point(1)  = {0.055, 0.055, z0};
Point(2)  = {0.055, 0.060, z0};
Point(3)  = {0.045, 0.060, z0};
Point(4)  = {0.045, 0.055, z0};
Point(5)  = {0.040, 0.055, z0};
Point(6)  = {0.040, 0.045, z0};
Point(7)  = {0.045, 0.045, z0};
Point(8)  = {0.045, 0.040, z0};
Point(9)  = {0.055, 0.040, z0};
Point(10) = {0.055, 0.045, z0};
Point(11) = {0.060, 0.045, z0};
Point(12) = {0.060, 0.055, z0};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 5};
Line(5) = {5, 6};
Line(6) = {6, 7};
Line(7) = {7, 8};
Line(8) = {8, 9};
Line(9) = {9, 10};
Line(10) = {10, 11};
Line(11) = {11, 12};
Line(12) = {12, 1};

//Curve Loop(1) = {1,2,3,4,5,6,7,8,9,10,11,12};
Curve Loop(20) = {1 ... 12};
//Physical Line("contour") = {1 ... 12};
Plane Surface(1) = {20};
//Physical Surface("front") = {1};

h = 0.02;
//out[] = Extrude {0,0,h} { Curve{1 ... 12}; };
out[] = Extrude {0,0,h} { Surface{ 1 }; };
