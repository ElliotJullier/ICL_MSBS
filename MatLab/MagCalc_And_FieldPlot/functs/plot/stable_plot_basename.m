function name = stable_plot_basename(figureName,queryFile)
%STABLE_PLOT_BASENAME Plot/study filename without the Q batch counter.
% Remove the counter only from the recognised Q-file suffix. Preserve study,
% quantity/group names and manually chosen figure names, including numbers.
if nargin<2, queryFile=""; end
name=string(figureName); queryFile=string(queryFile);
if strlength(queryFile)>0
    [~,queryBase]=fileparts(queryFile);
else
    match=regexp(char(name),' - (Q_.+)$','tokens','once');
    queryBase=""; if ~isempty(match), queryBase=string(match{1}); end
end
if strlength(queryBase)>0
    suffix=" - "+queryBase;
    if endsWith(name,suffix)
        stableQuery=regexprep(queryBase,'_batch\d+(?=_|$)','');
        name=extractBefore(name,strlength(name)-strlength(suffix)+1)+" - "+stableQuery;
    end
end
name=regexprep(name,"[^A-Za-z0-9_-]","_");
if strlength(name)==0, name="Figure"; end
end
