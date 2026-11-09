function [selected,summary,ranking] = selectHardware(T,cost,valid,metric)
%SELECTHARDWARE Pick one set per operating group or one over the full study.
% Each time history shares an operating_group across all its phases.
sets=unique(T.magnet_set_id,'stable');
groups=unique(T.operating_group,'stable');
C=inf(numel(sets),numel(groups));
for i=1:numel(sets)
    for g=1:numel(groups)
        in=T.magnet_set_id==sets(i)&T.operating_group==groups(g);
        if any(in)&&all(valid(in)),C(i,g)=max(cost(in));end
    end
end
peak=max(C,[],2);
[fixedValue,iFixed]=localMinimum(peak);
[~,order]=sort(peak);
ranking=table(sets(order),peak(order),(1:numel(sets))', ...
    'VariableNames',{'magnet_set_id','worst_J_T','rank'});
ranking.metric=repmat(metric,height(ranking),1);
groupValue=zeros(size(groups));
groupSet=strings(size(groups));
for g=1:numel(groups)
    [groupValue(g),i]=localMinimum(C(:,g));
    if isfinite(groupValue(g)),groupSet(g)=sets(i);end
end
summary=table(metric,sets(iFixed),fixedValue,max(groupValue),min(groupValue), ...
    nnz(isfinite(peak)),nnz(isfinite(groupValue)),numel(groups), ...
    'VariableNames',{'metric','fixed_winner','fixed_worst_J_T','independent_worst_J_T','easiest_group_J_T', ...
    'feasible_fixed_sets','feasible_operating_groups','operating_groups'});
if ~isfinite(fixedValue),summary.fixed_winner="";end
selected=table();
for mode=["fixed_hardware","independent_group"]
    for g=1:numel(groups)
        id=groupSet(g);
        if mode=="fixed_hardware",id=summary.fixed_winner;end
        if id=="",continue,end
        in=T.operating_group==groups(g)&T.magnet_set_id==id;
        S=T(in,:);
        S.selection_mode=repmat(mode,height(S),1);
        S.selection_metric=repmat(metric,height(S),1);
        S.selected_cost_T=cost(in);
        selected=[selected;S]; %#ok<AGROW>
    end
end
end

function [value,index]=localMinimum(cost)
value=min(cost);
index=1;
if isfinite(value)
    index=find(cost<=value+1e-10*max(value,1e-5),1);
    value=cost(index);
end
end
