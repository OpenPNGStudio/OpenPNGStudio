#include <lua_ctx.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <console.h>

static int lua_console_debug(lua_State *L);
static int lua_console_info(lua_State *L);
static int lua_console_warn(lua_State *L);
static int lua_console_error(lua_State *L);

void bind_logger_functions(lua_State *L)
{
    lua_register(L, LUA_PRIV_PREFIX "console_debug", lua_console_debug);
    lua_register(L, LUA_PRIV_PREFIX "console_info", lua_console_info);
    lua_register(L, LUA_PRIV_PREFIX "console_warn", lua_console_warn);
    lua_register(L, LUA_PRIV_PREFIX "console_error", lua_console_error);
}

static int lua_console_debug(lua_State *L)
{
    if (lua_gettop(L) != 3)
        return luaL_error(L, "expected exactly 3 arguments");

    const char *fn = lua_tostring(L, 1);
    int line = lua_tointeger(L, 2);
    const char *txt = lua_tostring(L, 3);
    console_debug(fn, line, txt);
    return 0;
}

static int lua_console_info(lua_State *L)
{
    if (lua_gettop(L) != 3)
        return luaL_error(L, "expected exactly 3 arguments");

    const char *fn = lua_tostring(L, 1);
    int line = lua_tointeger(L, 2);
    const char *txt = lua_tostring(L, 3);
    console_info(fn, line, txt);
    return 0;
}

static int lua_console_warn(lua_State *L)
{
    if (lua_gettop(L) != 3)
        return luaL_error(L, "expected exactly 3 arguments");

    const char *fn = lua_tostring(L, 1);
    int line = lua_tointeger(L, 2);
    const char *txt = lua_tostring(L, 3);
    console_warn(fn, line, txt);
    return 0;
}

static int lua_console_error(lua_State *L)
{
    if (lua_gettop(L) != 3)
        return luaL_error(L, "expected exactly 3 arguments");

    const char *fn = lua_tostring(L, 1);
    int line = lua_tointeger(L, 2);
    const char *txt = lua_tostring(L, 3);
    console_error(fn, line, txt);
    return 0;
}
