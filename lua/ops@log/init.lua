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

local M = {}

function M.debug(fmt, ...)
    local info = debug.getinfo(2, "Sln")
    local line = info.currentline
    local fn_name = info.name or "lua global scope"

    if info.name ~= nil then
        fn_name = "(lua) " .. info.name
    end

    __OpenPNGStudio_DO_NOT_POKE_console_debug(fn_name, line,
        string.format(fmt, ...))
end

function M.info(fmt, ...)
    local info = debug.getinfo(2, "Sln")
    local line = info.currentline
    local fn_name = info.name or "lua global scope"
    __OpenPNGStudio_DO_NOT_POKE_console_info(fn_name, line,
        string.format(fmt, ...))
end

function M.warn(fmt, ...)
    local info = debug.getinfo(2, "Sln")
    local line = info.currentline
    local fn_name = info.name or "lua global scope"
    __OpenPNGStudio_DO_NOT_POKE_console_warn(fn_name, line,
        string.format(fmt, ...))
end

function M.error(fmt, ...)
    local info = debug.getinfo(2, "Sln")
    local line = info.currentline
    local fn_name = info.name or "lua global scope"
    __OpenPNGStudio_DO_NOT_POKE_console_error(fn_name, line,
        string.format(fmt, ...))
end

return M
