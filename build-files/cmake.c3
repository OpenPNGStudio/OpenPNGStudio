module build;

import std::io::path;

struct CMakeTarget (Target) {
    DepList deps;
    String repo;
    StrList flags;
    Path project_root;
    bool configured;
    bool compiled;
    bool built;
    char to_build;
}

fn CMakeTarget *cmake_dep_init(String repo, String[] flags)
{
    CMakeTarget *dep = mem::new(CMakeTarget);
    dep.deps.init(mem);
    dep.built = false;
    dep.configured = false;
    dep.compiled = false;
    dep.to_build = 0;
    dep.repo = repo;
    dep.flags.init_with_array(mem, flags);
    @pool() {
        Path b = build_dir.to_tpath()!!;
        b = b.tappend("deps")!!;
        dep.project_root = b.append(mem, dep.get_name())!!;
    };

    return dep;
}

fn void CMakeTarget.add_dependency(&self, Target dep) @dynamic =>
    self.deps.push(dep);

fn Target? CMakeTarget.get_dependency(&self) @dynamic
{
    if (self.to_build < self.deps.len()) {
        defer self.to_build++;
        return self.deps.get(self.to_build);
    }

    return NO_DEPS?;
}

fn String CMakeTarget.get_name(&self) @dynamic
{
    usz start = self.repo.rindex_of_char('/')!!;
    usz end = self.repo.rindex_of_char('.')!!;
    return self.repo[start + 1..end - 1];
}

fn bool? CMakeTarget.fetch(&self, Path cwd) @dynamic
{
    Path local = cwd.tappend(self.get_name())!!;
    if (path::exists(local)) return true;

    return git.exec("clone", "--depth=1", self.repo, output: true)! == 0;
}

fn bool? CMakeTarget.configure(&self, Path miniroot) @dynamic
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

    @pool() {
        StrList args;
        args.tinit_with_array({"-B", "_build", "-G", "Ninja",
            "-DCMAKE_INSTALL_PREFIX=/", "-DCMAKE_INSTALL_LIBDIR=lib",
            "CMAKE_BUILD_TYPE=Debug"});

        if (repo_name == "zstd") {
            foreach (String arg : {"-S", "build/cmake"}) {
                args.push(arg);
            }
        }

        foreach (flag : self.flags) {
            args.push(flag);
        }

        if (repo_name == "libarchive") {
            Path b_lib = miniroot.tappend("lib")!!;
            Path b_inc = miniroot.tappend("include")!!;
            Path lib = b_lib.tappend("libzstd.a")!!;
            args.push(string::tformat("-DZSTD_INCLUDE_DIR=%s",
                b_inc.as_zstr()));
            args.push(string::tformat("-DZSTD_LIBRARY=%s",
                lib.as_zstr()));
        }

        log_info("Configuring %s", repo_name)!;
        self.configured = true;
        return cmake.exec_array(args.to_tarray(), output: true)! == 0;
    };
}

fn bool? CMakeTarget.build(&self) @dynamic
{
    String repo_name = self.get_name();
    if (self.compiled) {
        log_info("Already built %s", repo_name)!;
        return true;
    }
    path::chdir(self.project_root)!;

    Path build_root = self.project_root.tappend("_build")!;

    path::chdir(build_root)!;
    log_info("Building %s", repo_name)!;
    self.compiled = true;
    return ninja.exec(output: true)! == 0;
}

fn bool? CMakeTarget.install(&self, Path target) @dynamic
{
    String repo_name = self.get_name();
    if (self.built) {
        log_info("Already installed %s", repo_name)!;
        return true;
    }

    path::chdir(self.project_root)!;
    Path build_root = self.project_root.tappend("_build")!;

    path::chdir(build_root)!;
    log_info("Installing %s", repo_name)!;
    self.built = true;
    return ninja.exec("install", output: true)! == 0;
}
