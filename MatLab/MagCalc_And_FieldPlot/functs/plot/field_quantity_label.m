function label = field_quantity_label(dataName)
%FIELD_QUANTITY_LABEL Upright differential d; italic field and coordinates.
name=string(dataName);
parts=regexp(char(name),'^dB(.+)/d(.+)$','tokens','once');
if ~isempty(parts)
    field=string(parts{1}); direction=string(parts{2});
    if startsWith(direction,"["), direction="\ell_{"+direction+"}"; end
    label="$\mathrm{d}B_{"+field+"}/\mathrm{d}"+direction+"$ [T/m]";
elseif startsWith(name,"B")
    label="$B_{"+extractAfter(name,1)+"}$ [T]";
else
    label=name;
end
end
