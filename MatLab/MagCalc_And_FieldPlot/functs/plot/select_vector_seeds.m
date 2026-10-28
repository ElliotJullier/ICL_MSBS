function indices = select_vector_seeds(record,display)
%SELECT_VECTOR_SEEDS Deterministic lattice or coverage-preserving importance.
valid=find(display.eligible); opts=display.options;
budget=min(opts.MaxArrows,numel(valid));
if budget==0, indices=zeros(0,1); return; end
if string(opts.Seeding)=="uniform", baseline=budget; else, baseline=max(1,floor(opts.UniformFraction*budget)); end
shape=record.sampleShape; shape(end+1:3)=1; active=find(shape>1);
counts=shape;
ratio=min(1,(baseline/prod(counts))^(1/numel(active)));
counts(active)=max(1,floor(counts(active)*ratio));
while prod(counts)>baseline
    [~,j]=max(counts); counts(j)=max(1,counts(j)-1);
end
axes=cell(1,3);
for j=1:3
    if counts(j)==1, axes{j}=round((shape(j)+1)/2); else, axes{j}=unique(round(linspace(1,shape(j),counts(j)))); end
end
[I,J,K]=ndgrid(axes{:}); anchors=sub2ind(shape,I(:),J(:),K(:));
indices=anchors(display.eligible(anchors));
if string(opts.Seeding)=="uniform", return; end
if isempty(indices), indices=valid(round((numel(valid)+1)/2)); end
if string(opts.Seeding)=="magnitude", importance=display.magnitude; else, importance=display.variation; end
finite=sort(importance(valid(isfinite(importance(valid)))));
score=zeros(size(importance));
if ~isempty(finite) && finite(end)>0
    cap=finite(max(1,ceil(.95*numel(finite))));
    if cap<=0, cap=finite(end); end
    score=min(max(importance/cap,0),1); score(~isfinite(score))=0;
end
points=display.positions; nearest=Inf(size(importance));
steps=[];
for axisName=["x","y","z"]
    delta=diff(record.samplingGrid.(axisName)); steps=[steps,delta(delta>0)]; %#ok<AGROW>
end
minimumSeparation=1.5*min(steps);
selected=false(size(importance)); selected(indices)=true;
for j=indices(:).', nearest=min(nearest,sum((points-points(j,:)).^2,2)); end
while numel(indices)<budget
    priority=sqrt(nearest).*(.25+.75*score);
    priority(~display.eligible | selected)=-Inf;
    priority(nearest<minimumSeparation^2)=-Inf;
    [value,next]=max(priority);
    if ~isfinite(value) || value<=0, break; end
    indices(end+1,1)=next; selected(next)=true; %#ok<AGROW>
    nearest=min(nearest,sum((points-points(next,:)).^2,2));
end
end
