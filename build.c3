module build;

import libc;
import std::core::string, std::io, std::core::env;
import std::os;
import std::os::process;
import std::collections::list;

/* dirs */
String cwd;
String build_dir;

/* programs */
Program cmake, ninja, git, cp;

extern fn int symlink(char *target, char *path);

fn int main(String[] args)
{
    init();

    String[] sources = src({"main.c", "pathbuf.c", "str.c", "filedialog.c",
        "console.c", "layermgr.c", "editor.c", "line_edit.c", "context.c",
        "gif_config.c", "icon_db.c", "lua_ctx.c", "raygui.c",
        "ui/messagebox.c", "ui/window.c",
        "lua/logger.c",
        "work/work.c", "work/queue.c", "work/scheduler.c",
        "model/model.c", "model/write.c", "model/load.c",
        "layer/layer.c",
        "wrappers/nuklear.c", "wrappers/miniaudio.c",
        "vendor/toml.c"});

    Target[] deps = {
        cmake_dep_init("https://github.com/facebook/zstd.git",
            {"-DZSTD_BUILD_SHARED=OFF", "-DZSTD_BUILD_PROGRAMS=OFF",
            "-DZSTD_ENABLE_CXX=OFF"}),
        /* needs zstd (just to not depend on the distro) */
        cmake_dep_init("https://github.com/libarchive/libarchive.git",
            {"-DENABLE_OPENSSL=OFF", "-DENABLE_LIBB2=OFF",
            "-DENABLE_LZ4=OFF", "-DENABLE_LZMA=OFF", "-DENABLE_ZLIB=OFF",
            "-DENABLE_BZip2=OFF", "-DENABLE_LIBXML2=OFF", "-DENABLE_EXPAT=OFF",
            "-DENABLE_WIN32_XMLLITE=OFF", "-DENABLE_PCREPOSIX=OFF",
            "-DENABLE_PCRE2POSIX=OFF", "-DENABLE_LIBGCC=OFF",
            "-DENABLE_CNG=OFF", "-DENABLE_CPIO=OFF", "-DENABLE_CAT=OFF",
            "-DENABLE_UNZIP=OFF", "-DENABLE_ICONV=OFF", "-DENABLE_TEST=OFF",
            "-DPKG_CONFIG_EXECUTABLE=", "-DBUILD_SHARED_LIBS=OFF"}),
        cmake_dep_init("https://github.com/libuv/libuv.git",
            {"-DLIBUV_BUILD_SHARED=OFF"}),
        cmake_dep_init("https://github.com/raysan5/raylib.git",
            {"-DBUILD_EXAMPLES=OFF"}),
        cmake_dep_init("https://github.com/wolfSSL/wolfssl.git",
            {"-DWOLFSSL_DEBUG=ON", "-DWOLFSSL_ED25519=ON",
            "-DWOLFSSL_CURVE25519=ON", "-DWOLFSSL_EXAMPLES=OFF",
            "-DBUILD_SHARED_LIBS=OFF"}),
    };

    /* libarchive depends on zstd */
    deps[1].add_dependency(deps[0]);

    foreach (dep : deps) {
        @pool() {
            Path b = build_dir.to_tpath()!!;
            b = b.tappend("deps")!!;

            path::chdir(b)!!;
            if (!dep.fetch(b)!!) {
                log_err("Unable to fetch a dependency!")!!;
                return 1;
            }
            path::chdir(cwd.to_tpath()!!)!!;
        };
    }

    @pool() {
        Path cfg = path::tcwd()!!;
        cfg = cfg.tappend("raylib_config.h")!!;

        Path b = build_dir.to_tpath()!!;
        b = b.tappend("deps")!!;
        b = b.tappend("raylib")!!;
        b = b.tappend("src")!!;
        b = b.tappend("config.h")!!;
        cp.exec(cfg.str_view(), b.str_view())!!;
        log_info("Copying over custom raylib config")!!;
    };

    foreach (dep : deps) {
        @pool() {
            Path b = build_dir.to_tpath()!!;
            Path miniroot = b.tappend("miniroot")!!;

            if (!dep.configure(miniroot)!!) {
                log_err("Unable to configure a dependency!")!!;
                return 1;
            }
            path::chdir(cwd.to_tpath()!!)!!;
        };
    }

    foreach (dep : deps) {
        @pool() {
            if (!dep.build()!!) {
                log_err("Unable to build a dependency!")!!;
                return 1;
            }
            path::chdir(cwd.to_tpath()!!)!!;
        };
    }

    foreach (dep : deps) {
        @pool() {
            Path b = build_dir.to_tpath()!!;
            Path miniroot = b.tappend("miniroot")!!;

            if (!dep.install(miniroot)!!) {
                log_err("Unable to configure a dependency!")!!;
                return 1;
            }
            path::chdir(cwd.to_tpath()!!)!!;
        };
    }

    return 0;
}

fn void init()
{
    cwd = os::getcwd(mem)!!;
    @pool() {
        Path p = cwd.to_tpath()!!;
        p = p.tappend("build")!!;
        build_dir = p.str_view().copy(mem);
    };

    /* programs */
    cmake = find_program("cmake")!!;
    ninja = find_program("ninja")!!;
    git = find_program("git")!!;
    cp = find_program("cp")!!;

    /* prepare miniroot */
    @pool() {
        Path b = build_dir.to_tpath()!!;
        path::mkdir(b.tappend("deps")!!, recursive: true)!!;
        b = b.tappend("miniroot")!!;

        Path b_lib = b.tappend("lib")!!;
        Path b_inc = b.tappend("include")!!;

        Path usr = b.tappend("usr")!!;
        Path usr_lib = usr.tappend("lib")!!;
        Path usr_inc = usr.tappend("include")!!;
        path::mkdir(usr_lib, recursive: true)!!;
        path::mkdir(usr_inc, recursive: true)!!;

        libc::setenv("DESTDIR", b.as_zstr(), 1);

        if (!path::exists(b_lib)) symlink(usr_lib.as_zstr(), b_lib.as_zstr());
        if (!path::exists(b_inc)) symlink(usr_inc.as_zstr(), b_inc.as_zstr());
    };
}

alias StrList = List{String};
alias DepList = List{Target};
alias Program = String;

faultdef NO_DEPS;

interface Target {
    fn bool? fetch(Path cwd);
    fn bool? configure(Path miniroot);
    fn bool? build();
    fn bool? install(Path target);

    fn String get_name();
    fn bool is_built();
    fn void add_dependency(Target dep);
    fn Target? get_dependency();
}

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

fn bool CMakeTarget.is_built(&self) @dynamic => self.to_build == 
    self.deps.len() && self.built;

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
            "-DCMAKE_INSTALL_PREFIX=/", "-DCMAKE_INSTALL_LIBDIR=lib"});

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

struct Compiler {
    Program exe;
    StrList cflags;
    StrList ldflags;
}

macro src($arr) {
    $for var $i = 0; $i < $arr.len; $i++:
        $arr[$i] = "src/" +++ $arr[$i];
    $endfor

    return $arr;
}

fn Compiler? make_compiler(String exe) {
    Compiler cmp;
    cmp.exe = find_program(env_fallback("CC", exe))!;
    cmp.cflags.init(mem);
    cmp.ldflags.init(mem);

    return cmp;
}

fn String? Compiler.compile(&self, String file) {
    return NOT_FOUND?;
}

fn Program? find_program(String name) {
$if env::OS_TYPE == WIN32:
$error "This project cannot be built under Windows, cross compile";
$endif
    ZString path = libc::getenv("PATH");
    @pool() {
        String view = path.str_view();
        String[] dirs = view.tsplit(":");
        foreach (dir : dirs) {
            Path maybe = string::tformat("%s/%s", dir, name).to_tpath()!;
            if (io::path::exists(maybe)) {
                log_info("Program %s found (%s)", name, maybe.str_view())!;
                return maybe.str_view().copy(mem);
            }
        }
    };

    log_err("Program %s was not found!", name)!;
    return NOT_FOUND?;
}

fn String env_fallback(ZString env, String fallback) {
    char *e = libc::getenv(env);
    if (e == null) return fallback;
    return ((ZString) e).str_view();
}

fn int? Program.exec(self, String... args, bool output = false) => @pool() {
    String[] cmdline = mem::temp_array(String, args.len + 1);
    cmdline[0] = self;
    cmdline[1..] = args[..];
    SubProcess process = process::create(cmdline, {
        .inherit_stdio = output,
        .inherit_environment = true,
    })!;
    return process.join()!;
}

fn int? Program.exec_array(self, String[] args, bool output = false) => @pool() {
    String[] cmdline = mem::temp_array(String, args.len + 1);
    cmdline[0] = self;
    cmdline[1..] = args[..];
    SubProcess process = process::create(cmdline, {
        .inherit_stdio = output,
        .inherit_environment = true,
    })!;
    return process.join()!;
}

macro log_info(String $fmt, args...) => io::eprintfn("| " +++ $fmt, $vasplat);
macro log_err(String $fmt, args...) => io::eprintfn("! " +++ $fmt, $vasplat);
