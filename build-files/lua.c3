module build;

import std::io::path;
import std::core::string;

struct LuaTarget (Target) {
    Path project_root;
    bool configured;
    bool compiled;
    bool built;
}

const String LUA_VERSION = "lua-5.4.8";
const String LUA_URL = "https://lua.org/ftp/lua-5.4.8.tar.gz";

fn LuaTarget *lua_init()
{
    LuaTarget *dep = mem::new(LuaTarget);
    dep.built = false;
    dep.configured = false;
    dep.compiled = false;
    @pool() {
        Path b = build_dir.to_tpath()!!;
        b = b.tappend("deps")!!;
        dep.project_root = b.append(mem, LUA_VERSION)!!;
    };

    return dep;
}

fn void LuaTarget.add_dependency(&self, Target dep) @dynamic => {};
fn Target? LuaTarget.get_dependency(&self) @dynamic => {};
fn String LuaTarget.get_name(&self) @dynamic => "lua";

fn bool? LuaTarget.fetch(&self, Path cwd) @dynamic
{
    Path local = cwd.tappend(self.get_name())!!;
    if (path::exists(local)) return true;

    return curl.exec("-R", "-O", LUA_URL, output: true)! == 0;
}

fn bool? LuaTarget.configure(&self, Path miniroot) @dynamic
{
    String repo_name = self.get_name();
    if (self.configured) {
        log_info("Already configured %s", repo_name)!;
        return true;
    }
    path::chdir(self.project_root.parent())!;

    log_info("Configuring %s", repo_name)!;
    self.configured = true;
    return tar.exec("xvfz", "lua-5.4.8.tar.gz")! == 0;
}

fn bool? LuaTarget.build(&self) @dynamic
{
    String repo_name = self.get_name();
    if (self.compiled) {
        log_info("Already built %s", repo_name)!;
        return true;
    }
    path::chdir(self.project_root)!;

    log_info("Building %s", repo_name)!;
    self.compiled = true;
    return make.exec(output: true)! == 0;
}

fn bool? LuaTarget.install(&self, Path target) @dynamic
{
    String repo_name = self.get_name();
    if (self.built) {
        log_info("Already installed %s", repo_name)!;
        return true;
    }
    path::chdir(self.project_root)!;

    log_info("Installing %s", repo_name)!;
    self.built = true;
    @pool() {
        String loc = string::tformat("INSTALL_TOP=%s", target.str_view());
        return make.exec(loc, "install", output: true)! == 0;
    };
}
