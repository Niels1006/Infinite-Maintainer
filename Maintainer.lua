local ae2 = require("src.AE2")
local cfg = require("config")
local util = require("src.Utility") 

local items = cfg.items
local fluids = cfg.fluids
local sleepInterval = cfg.sleep

if fluids and next(fluids) ~= nil and not ae2.hasFluidSupport() then
    logInfo("WARNING: cfg.fluids is configured but the ME interface does not expose getFluidInNetwork (requires GTNH 2.9+). Fluid entries will be skipped.")
    fluids = nil
end

while true do
    local itemsCrafting = ae2.checkIfCrafting()

    for item, config in pairs(items) do
        if itemsCrafting[item] == true then
            logInfo(item .. " is already being crafted, skipping...")
        else
            local success, answer = ae2.requestItem(item, config[1], config[2], config[3])
            logInfo(answer)
        end

    end

    if fluids then
        for fluid, config in pairs(fluids) do
            if itemsCrafting[fluid] == true then
                logInfo(fluid .. " is already being crafted, skipping...")
            else
                local success, answer = ae2.requestFluid(fluid, config[1], config[2], config[3])
                logInfo(answer)
            end
        end
    end

    os.sleep(sleepInterval)
end