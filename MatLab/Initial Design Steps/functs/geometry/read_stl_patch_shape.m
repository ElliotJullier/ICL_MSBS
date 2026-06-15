function shape = read_stl_patch_shape(stlFile)
%READ_STL_PATCH_SHAPE Read ASCII or binary STL into shape.Faces/Vertices.
%
% Output:
%   shape.Faces    nTri x 3
%   shape.Vertices nVert x 3
%
% Duplicate vertices are merged using exact equality after reading. This is
% normally sufficient for STL triangles that repeat identical coordinate
% values. If a mesh uses near-duplicates, the plot will still work; it will
% just retain more vertices.

stlFile = string(stlFile);

if ~isfile(stlFile)
    error("STL file does not exist: %s", stlFile);
end

if is_ascii_stl(stlFile)
    [F, V] = read_ascii_stl(stlFile);
else
    [F, V] = read_binary_stl(stlFile);
end

shape = struct();
shape.Faces = F;
shape.Vertices = V;
end

function tf = is_ascii_stl(stlFile)
fid = fopen(stlFile, "r");
if fid < 0
    error("Could not open STL file: %s", stlFile);
end
firstBytes = fread(fid, 512, "*char")';
fclose(fid);

txt = string(firstBytes);
tf = startsWith(strtrim(txt), "solid", "IgnoreCase", true) && ...
     contains(txt, "facet", "IgnoreCase", true);
end

function [F, V] = read_ascii_stl(stlFile)
txt = fileread(stlFile);
tokens = regexp(txt, ...
    'vertex\s+([+-]?\d*\.?\d+(?:[eE][+-]?\d+)?)\s+([+-]?\d*\.?\d+(?:[eE][+-]?\d+)?)\s+([+-]?\d*\.?\d+(?:[eE][+-]?\d+)?)', ...
    'tokens');

if isempty(tokens) || mod(numel(tokens), 3) ~= 0
    error("ASCII STL file does not contain complete vertex triplets: %s", stlFile);
end

Vraw = zeros(numel(tokens), 3);
for k = 1:numel(tokens)
    Vraw(k,:) = str2double(tokens{k});
end

Fraw = reshape(1:size(Vraw,1), 3, []).';
[V, ~, ic] = unique(Vraw, "rows", "stable");
F = reshape(ic(Fraw), size(Fraw));
end

function [F, V] = read_binary_stl(stlFile)
fid = fopen(stlFile, "r");
if fid < 0
    error("Could not open STL file: %s", stlFile);
end

cleanupObj = onCleanup(@()fclose(fid)); %#ok<NASGU>

fseek(fid, 80, "bof");
nTri = fread(fid, 1, "uint32=>double");

if isempty(nTri) || nTri < 1
    error("Binary STL file does not contain a valid triangle count: %s", stlFile);
end

Vraw = zeros(nTri*3, 3);

for k = 1:nTri
    fread(fid, 3, "float32"); % normal vector, unused
    vertices = fread(fid, [3 3], "float32=>double").';
    fread(fid, 1, "uint16"); % attribute byte count, unused

    idx = (k-1)*3 + (1:3);
    Vraw(idx,:) = vertices;
end

Fraw = reshape(1:size(Vraw,1), 3, []).';
[V, ~, ic] = unique(Vraw, "rows", "stable");
F = reshape(ic(Fraw), size(Fraw));
end
