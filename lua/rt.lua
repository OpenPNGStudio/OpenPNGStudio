--[[
  This file is part of OpenPNGStudio. 
  Copyright (C) 2024-2025 LowByteFox
  
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local PENDING = 1
local FAILED = 2 
local SUCCESS = 3

local jobs = {}

yield = coroutine.yield
function async(fn)
    local prom = {
        status = PENDING,
        result = nil,
        work = fn,
        coro = nil,
    }

    table.insert(jobs, prom)

    return prom
end

function await(prom)
    while prom.status == PENDING do
        yield()
    end

    return prom.result
end

local function runtime()
    while true do
        for i, job in pairs(jobs) do
            if job.status == PENDING then
                if job.coro == nil then
                    job.coro = coroutine.create(job.work)
                end
                res, val = coroutine.resume(job.coro)
                if res and coroutine.status(job.coro) == "dead" then
                    job.status = SUCCESS
                    job.result = val
                elseif res == false then
                    error("Error handling not implemented!")
                end
            end
        end

        yield()
    end
end

local rt = coroutine.create(runtime)
local scripts = {}

function __OpenPNGStudio_DO_NOT_POKE_rt_spin_once()
    local req = __OpenPNGStudio_DO_NOT_POKE_script_load_req() -- nil or string for script name
    if req ~= nil then
        local script = {
            mod = require(req),
            update_prom = nil
        }

        if script.mod.update ~= nil then
            script.update_prom = async(script.mod.update)
        end

        table.insert(scripts, script)
    end

    coroutine.resume(rt)

    for _, script in pairs(scripts) do
        if script.mod.update ~= nil then
            if script.update_prom.status == SUCCESS then
                -- restart async
                script.update_prom = async(script.mod.update)
            end
        end
    end
end
