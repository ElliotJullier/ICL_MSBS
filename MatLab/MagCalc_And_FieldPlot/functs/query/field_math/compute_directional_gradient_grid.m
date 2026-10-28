function [gradData,dataName] = compute_directional_gradient_grid(grid,scalarData,dataName,gradientDirection)
%COMPUTE_DIRECTIONAL_GRADIENT_GRID d(B_a)/dd with thin-axis diagnostics.
% Suggested samples: max(2,ceil(5*abs(direction cosine))) per contributing
% axis. Warning heuristic only. An unsampled contributing derivative is NaN.
[n,label]=normalise_direction(gradientDirection);
axes={grid.x(:),grid.y(:),grid.z(:)}; dims=[2 1 3];
counts=cellfun(@numel,axes); contributes=abs(n)>1e-12;
required=max(2,ceil(5*abs(n)));
if any(contributes & counts<required)
    warning("MSBS:ShallowGradient", ...
        "Direction %s: xyz counts=[%d %d %d], suggested minimum=[%d %d %d] on contributing axes. Unsampled derivatives return NaN.", ...
        label,counts(1),counts(2),counts(3),required(1),required(2),required(3));
end
dataName="d"+dataName+"/d"+label; gradData=zeros(size(scalarData));
if any(contributes & counts<2), gradData(:)=NaN; return; end
for k=find(contributes)
    order=[dims(k),setdiff(1:3,dims(k),'stable')];
    v=permute(scalarData,order); sz=size(v); v=reshape(v,counts(k),[]);
    a=axes{k}; d=NaN(size(v));
    d(1,:)=(v(2,:)-v(1,:))/(a(2)-a(1));
    d(end,:)=(v(end,:)-v(end-1,:))/(a(end)-a(end-1));
    if numel(a)>2
        h0=a(2:end-1)-a(1:end-2); h1=a(3:end)-a(2:end-1);
        d(2:end-1,:)=-h1./(h0.*(h0+h1)).*v(1:end-2,:) + ...
            (h1-h0)./(h0.*h1).*v(2:end-1,:) + h0./(h1.*(h0+h1)).*v(3:end,:);
    end
    gradData=gradData+n(k)*ipermute(reshape(d,sz),order);
end
end
