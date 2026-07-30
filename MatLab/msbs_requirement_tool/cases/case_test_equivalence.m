function cfg = case_test_equivalence()
%CASE_TEST_EQUIVALENCE Internal compact case used to verify runStudy input forms.
cfg=case_minimal_example();
cfg.meta.case_id="test_equivalence";
cfg.output.enable=false;
cfg.visualisation.enable=false;
end
