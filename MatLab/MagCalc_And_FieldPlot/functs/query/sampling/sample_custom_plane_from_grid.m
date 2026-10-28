function result = sample_custom_plane_from_grid(grid,scalarData,q,queryIndex)
%SAMPLE_CUSTOM_PLANE_FROM_GRID Arbitrary plane, exact singleton constraints.
result=query_coordinates(grid,q,queryIndex);
F=build_scalar_grid_interpolant(grid,scalarData);
result.data=F(result.Y,result.X,result.Z);
end
