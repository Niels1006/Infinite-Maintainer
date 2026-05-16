local cfg = {}

-- EXAMPLE --

-- [item_name] = {threshold, batch_size, fluid_name} -- fluid_name is REQUIRED for fluid drops
-- ["Osmium Dust"] = {nil, 64} -- regular item without threshold
-- ["drop of Molten SpaceTime"] = {1000000, 1, "spacetime"} -- fluid drop with threshold and fluid name

cfg["items"] = {
    ["drop of Molten SpaceTime"] = {nil, 1, "spacetime"},
    ["drop of Molten White Dwarf Matter"] = {nil, 1, "white_dwarf_matter"}
}

-- Native fluid maintenance (GTNH 2.9+ only -- requires the StackApi-aware
-- ME interface). Safe to omit entirely on older versions.
--
-- [fluid_label] = {threshold_mb, batch_mb[, fluid_registry_name]}
-- The third value is an optional override -- the fluid registry name is
-- auto-detected from the craftable's stack, so usually you only need the first two.
-- Pass it explicitly only if auto-detection picks the wrong fluid.
cfg["fluids"] = {
    -- ["Molten SpaceTime"] = {nil, 1000},
}

cfg["sleep"] = 10

return cfg