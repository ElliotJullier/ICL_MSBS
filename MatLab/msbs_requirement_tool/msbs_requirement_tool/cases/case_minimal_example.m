function cfg = case_minimal_example()
%CASE_MINIMAL_EXAMPLE Smallest useful 0.60 m square-tunnel example.

cfg.meta.case_id = "minimal_example";
cfg.meta.description = "10% blockage sphere in a 0.60 m square wind tunnel";

cfg.tunnel.cross_section.type = "rectangular";
cfg.tunnel.cross_section.width_m = 0.60;
cfg.tunnel.cross_section.height_m = 0.60;
cfg.tunnel.speed = msbsreq.rangeSpec(30, [], "absolute");

cfg.geometry.type = "sphere";
cfg.geometry.sizing.mode = "blockage";
cfg.geometry.sizing.blockage_ratio = 0.10;

cfg.magnets.mode = "automatic";
cfg.magnets.automatic.grade = "N52";
cfg.magnets.automatic.linear_shrink_fraction = 0.0;

cfg.aero.CD = msbsreq.rangeSpec(0.50, [], "absolute");
cfg.aero.CL = msbsreq.rangeSpec(0, [], "absolute");
cfg.aero.Cm = msbsreq.rangeSpec(0, [], "absolute");
end
