/* SPDX-License-Identifier: GPL-3.0-or-later */

#pragma once
/* TODO: possibly lua API wrappers and utils */

#if 0
#include <lua.h>
#include <ui/line_edit.h>
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

#endif
