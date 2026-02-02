function areaGrid = coords_to_areaGrid(x, y, z)
[x, y, z] = meshgrid(x, y, z);
x = reshape(x, 1, []);
y = reshape(y, 1, []);
z = reshape(z, 1, []);
areaGrid = [x;y;z];