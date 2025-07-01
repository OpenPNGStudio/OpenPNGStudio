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
Program cmake, ninja, git, cp, make, curl, tar, sh;

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
        lua_init(),
        unuv_init(),
    };

    /* libarchive depends on zstd */
    deps[1].add_dependency(deps[0]);
    /* libunuv depends on libuv */
    deps[6].add_dependency(deps[2]);

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
    make = find_program("make")!!;
    curl = find_program("curl")!!;
    tar = find_program("tar")!!;
    sh = find_program("sh")!!;

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
        libc::setenv("LIBUV_INCLUDE", b_inc.as_zstr(), 1);

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
    fn void add_dependency(Target dep);
    fn Target? get_dependency();
}

macro src($arr) {
    $for var $i = 0; $i < $arr.len; $i++:
        $arr[$i] = "src/" +++ $arr[$i];
    $endfor

    return $arr;
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
