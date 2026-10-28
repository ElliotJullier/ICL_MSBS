function F = build_scalar_grid_interpolant(grid,scalarData,method,extrapolationMethod)
%BUILD_SCALAR_GRID_INTERPOLANT Dimension-aware F(Y,X,Z), NaN outside.
% Singleton axes constrain samples to a plane/line, never a volume.
% Cubic falls back to linear on short/nonuniform axes. Returns a handle.
if nargin<3 || strlength(string(method))==0, method="cubic"; end
if nargin>=4 && string(extrapolationMethod)~="none"
    error("MSBS:Extrapolation","Only extrapolation='none' is supported.");
end
axes={grid.y(:),grid.x(:),grid.z(:)}; counts=cellfun(@numel,axes);
if any([size(scalarData,1),size(scalarData,2),size(scalarData,3)]~=counts) || numel(scalarData)~=prod(counts)
    error("MSBS:GridShape","Field shape must be [Ny,Nx,Nz].");
end
scalarData=reshape(scalarData,counts); active=find(counts>1);
for k=active
    if any(diff(axes{k})<=0), error("MSBS:GridAxis","Axes must increase strictly."); end
end
if string(method)=="cubic"
    uniform=cellfun(@(a) numel(a)<3 || max(abs(diff(a)-mean(diff(a))))<=1e-8*max(abs(diff(a))),axes);
    if any(counts(active)<4) || ~all(uniform(active)), method="linear"; end
end
if isempty(active)
    interpolant=[];
elseif numel(active)==1
    interpolant=griddedInterpolant(axes{active},scalarData(:),char(method),'none');
else
    interpolant=griddedInterpolant(axes(active),reshape(scalarData,counts(active)),char(method),'none');
end
F=@evaluate;
    function values=evaluate(Y,X,Z)
        args={Y,X,Z};
        if ~isequal(size(Y),size(X),size(Z)), error("MSBS:QueryShape","Coordinate shapes must match."); end
        inside=find_points_inside_grid_domain(grid,X,Y,Z); values=NaN(size(X));
        if ~any(inside(:)), return; end
        if isempty(active)
            values(inside)=scalarData(1);
        else
            query=cell(1,numel(active));
            for j=1:numel(active)
                sampled=args{active(j)}(inside);
                % Clamp roundoff at a valid boundary; coverage tolerance is
                % only machine precision, never a physical extrapolation.
                sampled=max(axes{active(j)}(1),min(axes{active(j)}(end),sampled));
                query{j}=sampled(:);
            end
            values(inside)=interpolant(query{:});
        end
    end
end
