/*
 * This file is part of OpenPNGStudio. 
 * Copyright (C) 2024-2025 LowByteFox
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma once
/* TODO: possibly lua API wrappers and utils */

#include <lua.h>
#include <line_edit.h>
#include <stdbool.h>

struct lua_script {
    struct line_edit name;

    size_t buffer_size;
    char *buffer;
    bool is_mmapped;
};

struct script_mgr {
    size_t script_count;
    struct lua_script *scripts;

    const char *to_import;
};

#define LUA_PRIV_PREFIX "__OpenPNGStudio_DO_NOT_POKE_"

void expand_import_path(lua_State *L, const char *path);
int lua_script_loader(lua_State *L);
int lua_script_load_req(lua_State *L);
void bind_logger_functions(lua_State *L);

void script_manager_add_script(struct script_mgr *mgr, struct lua_script
    *script);
