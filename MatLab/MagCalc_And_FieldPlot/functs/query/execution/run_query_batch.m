function [Q,queryFile,caseData] = run_query_batch(caseDefs,label,defaultOp)
%RUN_QUERY_BATCH Formulaic entry point for COMSOL-focused query_main scripts.
% See Documentation/COMSOL_WORKFLOW.md for the case definition contract.
if nargin<2, label="COMSOL"; end
if nargin<3, defaultOp=struct("mode","precomputed"); end
caseData=repmat(struct("dataset",[],"op",[]),1,numel(caseDefs));
cacheFiles=strings(0); cacheOptions={}; cacheData={};
for k=1:numel(caseDefs)
    def=caseDefs(k); model=lower(string(optional(def,"model","comsol_precomputed")));
    if ~any(model==["virtual_field","synthetic_difference"])
        file=string(def.datasetFile);
        options=optional(def,"datasetOptions",{});
        match=[];
        for j=1:numel(cacheFiles)
            if cacheFiles(j)==file && isequaln(cacheOptions{j},options), match=j; break; end
        end
        if isempty(match)
            switch model
                case {"comsol_precomputed","comsol_grid"}
                    dataset=load_comsol_precomputed_dataset(file,options{:});
                case {"matlab_full_biotsavart","simple_biotsavart"}
                    dataset=load_field_dataset(file);
                otherwise
                    error("MSBS:Model","Unknown model: %s",model);
            end
            cacheFiles(end+1)=file; cacheOptions{end+1}=options; cacheData{end+1}=dataset;
        else
            dataset=cacheData{match};
        end
        geometryModel=string(optional(def,"geometryModel",""));
        if strlength(geometryModel)>0
            options=optional(def,"geometryOptions",{});
            dataset.geometry=load_comsol_geometry(geometryModel,options{:});
            dataset.geometryFile="STL/"+geometryModel;
        elseif isfield(def,"geometryFile") && ~isempty(def.geometryFile)
            dataset=attach_geometry_file_to_dataset(dataset,def.geometryFile);
        end
    else
        if model=="synthetic_difference"
            spec=def.difference; indices=[spec.caseA,spec.caseB]; weights=[1,-1]; poses=zeros(2,6);
        else
            spec=def.combination; indices=spec.cases; weights=spec.weights;
            poses=optional(spec,"poses",zeros(numel(indices),6));
        end
        validateattributes(indices,{'numeric'},{'vector','integer','>=',1,'<',k});
        inputs=cell(1,numel(indices)); ops=inputs;
        for j=1:numel(indices)
            inputs{j}=caseData(indices(j)).dataset; ops{j}=caseData(indices(j)).op;
        end
        reference=optional(spec,"referenceGrid",[]);
        dataset=create_virtual_field_dataset(inputs,ops,weights,poses,"ReferenceGrid",reference, ...
            "CaseNames",string({caseDefs(indices).caseName}));
        model="virtual_field";
    end
    request=optional(def,"opRequest",defaultOp);
    if model=="virtual_field", request=struct("mode","precomputed"); end
    op=validate_and_solve_operating_point(dataset,request,model);
    caseData(k).dataset=dataset; caseData(k).op=op;
    caseDefs(k).model=model;
end
Q=cell(1,numel(caseDefs));
for k=1:numel(caseDefs)
    [results,queries]=run_field_queries(caseData(k).dataset,caseData(k).op,optional(caseDefs(k),"queries",{}),caseDefs(k).model);
    Q{k}=pack_query_case(caseData(k).dataset,caseData(k).op,queries,results,caseDefs(k));
end
paths=msbs_paths();
if ~isfolder(paths.queryOutputs), mkdir(paths.queryOutputs); end
[queryFile,batch]=next_Q_filename(paths.queryOutputs,label,"QueryBatch");
for k=1:numel(Q)
    Q{k}.meta.queryFile=string(queryFile); Q{k}.queryFile=string(queryFile); Q{k}.batchNumber=batch;
end
save(queryFile,"Q"); fprintf("Saved query batch: %s\n",queryFile);
end
function value=optional(s,name,default)
if isfield(s,name) && ~isempty(s.(name)), value=s.(name); else, value=default; end
end
