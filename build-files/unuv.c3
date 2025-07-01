module build;

import libc;
import std::io::path;
import std::core::string;

struct UnuvTarget (Target) {
    DepList deps;
    Path project_root;
    bool configured;
    bool compiled;
    bool built;
    char to_build;
}

const String URL @local = "https://codeberg.org/LowByteFox/libunuv.git";

fn UnuvTarget *unuv_init()
{
    UnuvTarget *dep = mem::new(UnuvTarget);
    dep.deps.init(mem);
    dep.built = false;
    dep.configured = false;
    dep.compiled = false;
    dep.to_build = 0;
    @pool() {
        Path b = build_dir.to_tpath()!!;
        b = b.tappend("deps")!!;
        dep.project_root = b.append(mem, "libunuv")!!;
    };

    return dep;
}

fn void UnuvTarget.add_dependency(&self, Target dep) @dynamic =>
    self.deps.push(dep);

fn Target? UnuvTarget.get_dependency(&self) @dynamic
{
    if (self.to_build < self.deps.len()) {
        defer self.to_build++;
        return self.deps.get(self.to_build);
    }

    return NO_DEPS?;
}

fn String UnuvTarget.get_name(&self) @dynamic => "libunuv";

fn bool? UnuvTarget.fetch(&self, Path cwd) @dynamic
{
    Path local = cwd.tappend(self.get_name())!!;
    if (path::exists(local)) return true;

    return git.exec("clone", "--depth=1", URL, output: true)! == 0;
}

fn bool? UnuvTarget.configure(&self, Path miniroot) @dynamic
{
    String repo_name = self.get_name();
    if (self.configured) {
        log_info("Already configured %s", repo_name)!;
        return true;
    }

    while (try Target dep = self.get_dependency()) {
        @pool() {
            if (!dep.configure(miniroot)!!) {
                log_err("Unable to configure a dependency!")!!;
                return false;
            }

            if (!dep.build()!!) {
                log_err("Unable to build a dependency!")!!;
                return false;
            }

            if (!dep.install(miniroot)!!) {
                log_err("Unable to install a dependency!")!!;
                return false;
            }
        };
    }
    path::chdir(self.project_root)!;

    log_info("Configuring %s", repo_name)!;
    self.configured = true;

    return sh.exec("-c", "\"./configure\"")! == 0;
}

fn bool? UnuvTarget.build(&self) @dynamic
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

fn bool? UnuvTarget.install(&self, Path target) @dynamic
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
        String loc = string::tformat("DESTDIR=%s", target.str_view());
        return make.exec(loc, "install", output: true)! == 0;
    };
}
