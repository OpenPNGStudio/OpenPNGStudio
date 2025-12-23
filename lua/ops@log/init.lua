-- SPDX-License-Identifier: GPL-3.0-or-later

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

    if info.name ~= nil then
        fn_name = "(lua) " .. info.name
    end

    __OpenPNGStudio_DO_NOT_POKE_console_info(fn_name, line,
        string.format(fmt, ...))
end

function M.warn(fmt, ...)
    local info = debug.getinfo(2, "Sln")
    local line = info.currentline
    local fn_name = info.name or "lua global scope"

    if info.name ~= nil then
        fn_name = "(lua) " .. info.name
    end

    __OpenPNGStudio_DO_NOT_POKE_console_warn(fn_name, line,
        string.format(fmt, ...))
end

function M.error(fmt, ...)
    local info = debug.getinfo(2, "Sln")
    local line = info.currentline
    local fn_name = info.name or "lua global scope"

    if info.name ~= nil then
        fn_name = "(lua) " .. info.name
    end

    __OpenPNGStudio_DO_NOT_POKE_console_error(fn_name, line,
        string.format(fmt, ...))
end

return M
