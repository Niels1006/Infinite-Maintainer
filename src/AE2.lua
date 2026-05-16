local component = require("component")
local ME = component.me_interface

local AE2 = {}

-- Lightweight cache for specific items only.
-- Values: a craftable userdata (hit), or `false` (negative lookup).
local itemCache = {}
local fluidNameCache = {} -- name -> fluid registry name, or false if the craftable has no fluid stack
local cacheTimestamp = 0
local CACHE_DURATION = 600 -- 10 minutes in seconds

-- Function to get or cache a specific craftable item
local function getCraftableForItem(itemName)
    local currentTime = os.time()

    local cached = itemCache[itemName]
    if cached ~= nil and currentTime - cacheTimestamp < CACHE_DURATION then
        if cached == false then return nil end
        return cached
    end

    -- If cache is too old, clear it completely to save memory
    if currentTime - cacheTimestamp >= CACHE_DURATION then
        itemCache = {}
        fluidNameCache = {}
        cacheTimestamp = currentTime
    end

    -- Look for this specific item in craftables
    local craftables = ME.getCraftables({["label"] = itemName})
    if #craftables >= 1 then
        itemCache[itemName] = craftables[1] -- Cache only this one item
        return craftables[1]
    end

    itemCache[itemName] = false -- Cache the negative lookup so misspelled entries don't re-query every cycle
    return nil
end

function AE2.requestItem(name, threshold, count, fluidName)
    local craftable = getCraftableForItem(name)

    if craftable then
        local item = (craftable.getStack or craftable.getItemStack)(craftable)
        if threshold ~= nil then
            local itemInSystem = nil
            
            if fluidName then
                local fluidTag = '{Fluid:' .. fluidName .. '}'
                itemInSystem = ME.getItemInNetwork("ae2fc:fluid_drop", 0, fluidTag)
            else
                if item.name then
                    if item.tag then
                        itemInSystem = ME.getItemInNetwork(item.name, item.damage or 0, item.tag)
                    end
                    
                    -- Fallback: try with just the internal name and damage
                    if itemInSystem == nil then
                        itemInSystem = ME.getItemInNetwork(item.name, item.damage or 0)
                    end
                end
            end
            
            if itemInSystem ~= nil and itemInSystem.size >= threshold then 
                return table.unpack({false, "The amount of " .. (itemInSystem.label or name) .. " (" .. itemInSystem.size .. ") meets or exceeds threshold (" .. threshold .. ")! Aborting request."})
            end
        end
        
        if item.label == name then
            local craft = craftable.request(count)

            while craft.isComputing() == true do
                os.sleep(1)
            end
            if craft.hasFailed() then
                return table.unpack({false, "Failed to request " .. name .. " x " .. count})
            else
                return table.unpack({true, "Requested " .. name .. " x " .. count})
            end
        end
    end
    return table.unpack({false, name .. " is not craftable!"})
end

-- Native fluid maintenance via getFluidInNetwork (GTNH 2.9+).
-- `name` is the fluid craftable label; `fluidName` is the fluid registry name and is
-- auto-detected from the craftable's stack if omitted (pass it only as an override).
function AE2.requestFluid(name, threshold, count, fluidName)
    local craftable = getCraftableForItem(name)

    if craftable then
        if threshold ~= nil then
            if not fluidName then
                local cached = fluidNameCache[name]
                if cached == nil then
                    local stack = (craftable.getStack or craftable.getItemStack)(craftable)
                    cached = (stack and stack.name) or false
                    fluidNameCache[name] = cached
                end
                if cached then fluidName = cached end
            end

            if fluidName then
                local fluidInSystem = ME.getFluidInNetwork(fluidName)
                local amount = fluidInSystem and (fluidInSystem.size or fluidInSystem.amount)
                if amount and amount >= threshold then
                    return table.unpack({false, "The amount of " .. (fluidInSystem.label or name) .. " (" .. amount .. " mB) meets or exceeds threshold (" .. threshold .. " mB)! Aborting request."})
                end
            end
        end

        local craft = craftable.request(count)

        while craft.isComputing() == true do
            os.sleep(1)
        end
        if craft.hasFailed() then
            return table.unpack({false, "Failed to request " .. name .. " x " .. count .. " mB"})
        else
            return table.unpack({true, "Requested " .. name .. " x " .. count .. " mB"})
        end
    end
    return table.unpack({false, name .. " is not craftable!"})
end

function AE2.checkIfCrafting()
    local cpus = ME.getCpus()
    local items = {}
    for k, v in pairs(cpus) do
        local finaloutput = v.cpu.finalOutput()
        if finaloutput ~= nil then
            items[finaloutput.label] = true
        end
    end

    return items
end

-- Returns true if the ME interface exposes the GTNH 2.9+ native fluid API.
function AE2.hasFluidSupport()
    return ME.getFluidInNetwork ~= nil
end

-- Function to manually clear the cache if needed
function AE2.clearCache()
    itemCache = {}
    fluidNameCache = {}
    cacheTimestamp = 0
end

return AE2