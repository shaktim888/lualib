//
//  LSCEngineAdapter.m
//  LuaScriptCore
//
//  Created by admin on 2017/8/3.
//  Copyright © 2017年 hy. All rights reserved.
//

#import "LSCEngineAdapter.h"
#import "lauxlib.h"
#import "lua.h"
#import "luaconf.h"
#import "lualib.h"
#import "lapi.h"

#define TOLUA_REFID_FUNCTION_MAPPING "toluafix_refid_function_mapping"
//#define LUA_REGISTRYINDEX    (-10000)

#if LUA_VERSION_NUM == 501

#import "lext.h"

#endif

#if __cplusplus
extern "C" {
#endif
// socket
#import "luasocket.h"
#import "mime.h"
#import "lua_zlib.h"

static luaL_Reg luax_exts[] = {
    {"socket.core", luaopen_socket_core},
    {"mime.core", luaopen_mime_core},
    {NULL, NULL}
};

void luaopen_lua_extensions(lua_State *L)
{
    // load extensions
    luaL_Reg* lib = luax_exts;
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    for (; lib->func; lib++)
    {
        lua_pushcfunction(L, lib->func);
        lua_setfield(L, -2, lib->name);
    }
    lua_pop(L, 2);

//    luaopen_luasocket_scripts(L);
}

#if __cplusplus
} // extern "C"
#endif

@implementation LSCEngineAdapter

+ (lua_State *)newState
{
    return luaL_newstate();
}

+ (void)close:(lua_State *)state
{
    lua_close(state);
}

+ (int)absIndex:(int)index state:(lua_State *)state
{
    return lua_absindex(state, index);
}

+ (int)gc:(lua_State *)state what:(LSCGCType)what data:(int)data
{
    return lua_gc(state, what, data);
}

+ (void)openLibs:(lua_State *)state
{
    luaL_openlibs(state);
    luaopen_lua_extensions(state);
    luaopen_zlib(state);
}

+ (void)setGlobal:(lua_State *)state name:(const char *)name
{
    lua_setglobal(state, name);
}

+ (void)getGlobal:(lua_State *)state name:(const char *)name
{
    lua_getglobal(state, name);
}

+ (int)getTop:(lua_State *)state
{
    return lua_gettop(state);
}

+ (int)loadString:(lua_State *)state string:(const char *)string
{
    return luaL_loadstring(state, string);
}

+ (int)loadFile:(lua_State *)state path:(const char *)path
{
    return luaL_loadfile(state, path);
}

+ (int)pCall:(lua_State *)state nargs:(int)nargs nresults:(int)nresults errfunc:(int)errfunc
{
    return lua_pcall(state, nargs, nresults, errfunc);
}

+ (void)pop:(lua_State *)state count:(int)count
{
    lua_pop(state, count);
}

+ (BOOL)isNil:(lua_State *)state index:(int)index
{
    return lua_isnil(state, index);
}

+ (BOOL)isTable:(lua_State *)state index:(int)index
{
    return lua_istable(state, index);
}

+ (BOOL)isFunction:(lua_State *)state index:(int)index
{
    return lua_isfunction(state, index);
}

+ (BOOL)isUserdata:(lua_State *)state index:(int)index
{
    return lua_isuserdata(state, index);
}

+ (void)pushNil:(void *)state
{
    lua_pushnil(state);
}

+ (void)pushInteger:(lua_Integer)integer state:(lua_State *)state
{
    lua_pushinteger(state, integer);
}

+ (void)pushNumber:(lua_Number)number state:(lua_State *)state
{
    lua_pushnumber(state, number);
}

+ (void)pushBoolean:(int)boolean state:(lua_State *)state
{
    lua_pushboolean(state, boolean);
}

+ (void)pushLightUserdata:(void *)userdata state:(lua_State *)state
{
    lua_pushlightuserdata(state, userdata);
}

+ (void)pushString:(const char *)string state:(lua_State *)state
{
    lua_pushstring(state, string);
}

+ (void)pushString:(const char *)string len:(size_t)len state:(lua_State *)state
{
    lua_pushlstring(state, string, len);
}

+ (void)pushCFunction:(lua_CFunction)cfunction state:(lua_State *)state
{
    lua_pushcfunction(state, cfunction);
}

+ (void)pushCClosure:(lua_CFunction)cclosure n:(int)n state:(lua_State *)state
{
    lua_pushcclosure(state, cclosure, n);
}

+ (void)pushValue:(int)index state:(lua_State *)state
{
    lua_pushvalue(state, index);
}

+ (int)upvalueIndex:(int)index
{
    return lua_upvalueindex(index);
}

+ (lua_Integer)toInteger:(lua_State *)state index:(int)index
{
    return lua_tointeger(state, index);
}

+ (lua_Number)toNumber:(lua_State *)state index:(int)index
{
    return lua_tonumber(state, index);
}

+ (int)toBoolean:(lua_State *)state index:(int)index
{
    return lua_toboolean(state, index);
}

+ (const void *)toPointer:(lua_State *)state index:(int)index
{
    return lua_topointer(state, index);
}

+ (void *)toUserdata:(lua_State *)state index:(int)index
{
    return lua_touserdata(state, index);
}

+ (const char *)toString:(lua_State *)state index:(int)index
{
    return lua_tostring(state, index);
}

+ (const char *)toString:(lua_State *)state index:(int)index len:(size_t *)len
{
    return lua_tolstring(state, index, len);
}

+ (void)newTable:(lua_State *)state
{
    lua_newtable(state);
}

+ (void *)newUserdata:(lua_State *)state size:(size_t)size
{
    return lua_newuserdata(state, size);
}

+ (int)newMetatable:(lua_State *)state name:(const char *)name
{
    return luaL_newmetatable(state, name);
}

+ (void)getField:(lua_State *)state index:(int)index name:(const char *)name
{
    lua_getfield(state, index, name);
}

+ (void)setField:(lua_State *)state index:(int)index name:(const char *)name
{
    lua_setfield(state, index, name);
}

+ (void)getMetatable:(lua_State *)state name:(const char *)name
{
    luaL_getmetatable(state, name);
}

+ (int)getMetatable:(lua_State *)state index:(int)index
{
    return lua_getmetatable(state, index);
}

+ (int)setMetatable:(lua_State *)state index:(int)index
{
    return lua_setmetatable(state, index);
}

+ (void)rawSetI:(lua_State *)state index:(int)index n:(int)n
{
    lua_rawseti(state, index, n);
}

+ (void)rawSet:(lua_State *)state index:(int)index
{
    lua_rawset(state, index);
}

+ (void)rawGet:(lua_State *)state index:(int)index
{
    lua_rawget(state, index);
}

+ (int)type:(lua_State *)state index:(int)index
{
    return lua_type(state, index);
}

+ (int)next:(lua_State *)state index:(int)index
{
    return lua_next(state, index);
}

+ (void)insert:(lua_State *)state index:(int)index
{
    lua_insert(state, index);
}

+ (void)remove:(lua_State *)state index:(int)index
{
    lua_remove(state, index);
}

+ (const char *)checkString:(lua_State *)state index:(int)index
{
    return luaL_checkstring(state, index);
}

+ (int)error:(lua_State *)state message:(const char *)message
{
    return luaL_error(state, message);
}

+ (lua_State *)newThread:(lua_State *)state
{
    return lua_newthread(state);
}

+ (int)resumeThread:(lua_State *)state
    fromThreadState:(lua_State *)fromThreadState
           argCount:(int)argCount
{
    return lua_resume(state, fromThreadState, argCount);
}

+ (int)yielyThread:(lua_State *)state
       resultCount:(int)resultCount
{
    return lua_yield(state, resultCount);
}

+ (int)rawRunProtected:(lua_State *)state
                  func:(Pfunc)func
              userdata:(void *)userdata
{
    return luaD_rawrunprotected(state, func, userdata);
}

+ (void)setHook:(lua_State *)state
           hook:(lua_Hook)hook
           mask:(int)mask
          count:(int)count
{
    lua_sethook(state, hook, mask, count);
}
//
//+(int)lua_ref_function : (lua_State*) L lo: (int) lo def : (int) def {
//    static int s_function_ref_id = 0;
//
//    s_function_ref_id++;
//
//    lua_pushstring(L, TOLUA_REFID_FUNCTION_MAPPING);
//    lua_rawget(L, LUA_REGISTRYINDEX);                           /* stack: fun ... refid_fun */
//    lua_pushinteger(L, s_function_ref_id);                      /* stack: fun ... refid_fun refid */
//    lua_pushvalue(L, lo);                                       /* stack: fun ... refid_fun refid fun */
//
//    lua_rawset(L, -3);                  /* refid_fun[refid] = fun, stack: fun ... refid_ptr */
//    lua_pop(L, 1);                                              /* stack: fun ... */
//
//    return s_function_ref_id;
//}
//
//+ (void) lua_get_function_by_refid: (lua_State*) L refid: (int) refid
//{
//    lua_pushstring(L, TOLUA_REFID_FUNCTION_MAPPING);
//    lua_rawget(L, LUA_REGISTRYINDEX);                           /* stack: ... refid_fun */
//    lua_pushinteger(L, refid);                                  /* stack: ... refid_fun refid */
//    lua_rawget(L, -2);                                          /* stack: ... refid_fun fun */
//    lua_remove(L, -2);                                          /* stack: ... fun */
//}
//
//+(void) lua_remove_function_by_refid: (lua_State*) L refid: (int) refid
//{
//    lua_pushstring(L, TOLUA_REFID_FUNCTION_MAPPING);
//    lua_rawget(L, LUA_REGISTRYINDEX);                           /* stack: ... refid_fun */
//    lua_pushinteger(L, refid);                                  /* stack: ... refid_fun refid */
//    lua_pushnil(L);                                             /* stack: ... refid_fun refid nil */
//    lua_rawset(L, -3);                  /* refid_fun[refid] = fun, stack: ... refid_ptr */
//    lua_pop(L, 1);                                              /* stack: ... */
//
//    // luaL_unref(L, LUA_REGISTRYINDEX, refid);
//}
//
//+(int) executeFunction: (lua_State*) _state numArgs : (int) numArgs
//{
//    static int _callFromLua = 0;
//    int functionIndex = -(numArgs + 1);
//    if (!lua_isfunction(_state, functionIndex))
//    {
//        lua_pop(_state, numArgs + 1); // remove function and arguments
//        return 0;
//    }
//
//    int traceback = 0;
//    lua_getglobal(_state, "__G__TRACKBACK__");                         /* L: ... func arg1 arg2 ... G */
//    if (!lua_isfunction(_state, -1))
//    {
//        lua_pop(_state, 1);                                            /* L: ... func arg1 arg2 ... */
//    }
//    else
//    {
//        lua_insert(_state, functionIndex - 1);                         /* L: ... G func arg1 arg2 ... */
//        traceback = functionIndex - 1;
//    }
//
//    int error = 0;
//    ++_callFromLua;
//    error = lua_pcall(_state, numArgs, 1, traceback);                  /* L: ... [G] ret */
//    --_callFromLua;
//    if (error)
//    {
//        if (traceback == 0)
//        {
//            printf("[LUA ERROR] %s", lua_tostring(_state, - 1));        /* L: ... error */
//            lua_pop(_state, 1); // remove error message from stack
//        }
//        else                                                            /* L: ... G error */
//        {
//            lua_pop(_state, 2); // remove __G__TRACKBACK__ and error message from stack
//        }
//        return 0;
//    }
//
//    // get return value
//    int ret = 0;
//    if (lua_isnumber(_state, -1))
//    {
//        ret = (int)lua_tointeger(_state, -1);
//    }
//    else if (lua_isboolean(_state, -1))
//    {
//        ret = (int)lua_toboolean(_state, -1);
//    }
//    // remove return value from stack
//    lua_pop(_state, 1);                                                /* L: ... [G] */
//
//    if (traceback)
//    {
//        lua_pop(_state, 1); // remove __G__TRACKBACK__ from stack      /* L: ... */
//    }
//
//    return ret;
//}
//
//
//+(int) pushFunctionByHandler: (lua_State*) L nHandler: (int) nHandler numArgs: (int) numArgs
//{
//    [self lua_get_function_by_refid:L refid:nHandler];                  /* L: ... func */
//    if (!lua_isfunction(L, -1))
//    {
//        printf("[LUA ERROR] function refid '%d' does not reference a Lua function", nHandler);
//        lua_pop(L, 1);
//        return 0;
//    }
//    if (numArgs > 0)
//    {
//        lua_insert(L, -(numArgs + 1));                        /* L: ... func arg1 arg2 ... */
//    }
//    int ret = [self executeFunction:L numArgs:numArgs];
//    lua_settop(L, 0);
//    return ret;
//}

@end
