function result = sample_fundamental_plane_from_grid(grid,scalarData,q,queryIndex)
%SAMPLE_FUNDAMENTAL_PLANE_FROM_GRID Requested offset, never nearest slice.
result=query_coordinates(grid,q,queryIndex);
F=build_scalar_grid_interpolant(grid,scalarData);
result.data=F(result.Y,result.X,result.Z);
end
