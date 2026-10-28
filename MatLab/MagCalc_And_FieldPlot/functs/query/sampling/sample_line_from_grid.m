function result = sample_line_from_grid(grid,scalarData,q,queryIndex)
%SAMPLE_LINE_FROM_GRID Dimension-aware line interpolation, NaN outside.
result=query_coordinates(grid,q,queryIndex);
F=build_scalar_grid_interpolant(grid,scalarData);
result.data=F(result.Y,result.X,result.Z);
end
