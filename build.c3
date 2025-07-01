module build;

import libc;
import std::core::string, std::io, std::core::env;
import std::os;
import std::os::process;
import std::collections::list;

String cwd;
String build_dir;

extern fn int symlink(char *target, char *path);

fn void main(String[] args)
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

    CMakeDependency[] cmake_deps = {
        { "https://github.com/facebook/zstd.git",           {} },
        /* needs zstd (just to not depend on the distro) */
        { "https://github.com/libarchive/libarchive.git",   {} },
        { "https://github.com/libuv/libuv.git",             {} },
        { "https://github.com/raysan5/raylib.git",          {} },
        { "https://github.com/wolfSSL/wolfssl.git",         {} },
    };

    /* zstd */
    @dep_init(cmake_deps[0], {"-DZSTD_BUILD_SHARED=OFF",
        "-DZSTD_BUILD_PROGRAMS=OFF", "-DZSTD_ENABLE_CXX=OFF"});

    /* libarchive */
    @dep_init(cmake_deps[1], {"-DENABLE_OPENSSL=OFF", "-DENABLE_LIBB2=OFF",
        "-DENABLE_LZ4=OFF", "-DENABLE_LZMA=OFF", "-DENABLE_ZLIB=OFF",
        "-DENABLE_BZip2=OFF", "-DENABLE_LIBXML2=OFF", "-DENABLE_EXPAT=OFF",
        "-DENABLE_WIN32_XMLLITE=OFF", "-DENABLE_PCREPOSIX=OFF",
        "-DENABLE_PCRE2POSIX=OFF", "-DENABLE_LIBGCC=OFF", "-DENABLE_CNG=OFF",
        "-DENABLE_CPIO=OFF", "-DENABLE_CAT=OFF",  "-DENABLE_UNZIP=OFF",
        "-DENABLE_ICONV=OFF", "-DENABLE_TEST=OFF", "-DPKG_CONFIG_EXECUTABLE=",
        "-DBUILD_SHARED_LIBS=OFF"});

    /* libuv */
    @dep_init(cmake_deps[2], {"-DLIBUV_BUILD_SHARED=OFF"});

    /* raylib */
    @dep_init(cmake_deps[3], {"-DBUILD_EXAMPLES=OFF"});

    /* wolfssl */
    @dep_init(cmake_deps[4], {"-DWOLFSSL_DEBUG=ON", "-DWOLFSSL_ED25519=ON",
        "-DWOLFSSL_CURVE25519=ON", "-DWOLFSSL_EXAMPLES=OFF",
        "-DBUILD_SHARED_LIBS=OFF"});

    /* programs */
    CMake cmake = find_program("cmake")!!;
    Program ninja = find_program("ninja")!!;
    Program git = find_program("git")!!;
    Program cp = find_program("cp")!!;

    foreach (dep : cmake_deps) { @pool() { cmake.fetch(git, dep); }; }

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

    /* configure and build deps */
    foreach(dep : cmake_deps) {
        if (dep.repo.contains("libarchive.git")) {
            log_info("LibArchive must be configured after zstd was built!")!!;
            continue;
        }
        @pool() {
            cmake.configure(dep);
            cmake.build(ninja, dep);
        };
    }

    /* install deps, do libarchive in single go */
    foreach(dep : cmake_deps) {
        @pool() {
            if (dep.repo.contains("libarchive.git")) {
                Path b = build_dir.to_tpath()!!;
                b = b.tappend("miniroot")!!;
                Path b_lib = b.tappend("lib")!!;
                Path b_inc = b.tappend("include")!!;
                Path lib = b_lib.tappend("libzstd.a")!!;

                dep.flags.push(string::tformat("-DZSTD_INCLUDE_DIR=%s",
                    b_inc.as_zstr()));
                dep.flags.push(string::tformat("-DZSTD_LIBRARY=%s",
                    lib.as_zstr()));

                cmake.configure(dep);
                cmake.build(ninja, dep);
            }

            cmake.install(ninja, dep);
        };
    }
}

fn void init()
{
    cwd = os::getcwd(mem)!!;
    @pool() {
        Path p = cwd.to_tpath()!!;
        p = p.tappend("build")!!;
        build_dir = p.str_view().copy(mem);
    };

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
alias Program = String;
alias CMake = Program;

macro @dep_init(#dep, #arr) => #dep.flags.init_with_array(mem, #arr);

fn void CMake.fetch(&self, Program git, CMakeDependency dep)
{
    Path b = build_dir.to_tpath()!!;
    b = b.tappend("deps")!!;

    if (try usz start = dep.repo.rindex_of_char('/')) {
        if (try usz end = dep.repo.rindex_of_char('.')) {
            Path local = b.tappend(dep.repo[start + 1..end - 1])!!;
            if (path::exists(local)) return;
        }
    }

    path::chdir(b)!!;
    git.exec("clone", "--depth=1", dep.repo, output: true)!!;
    path::chdir(cwd.to_tpath()!!)!!;
}

fn void CMake.configure(&self, CMakeDependency dep)
{
    Path b = build_dir.to_tpath()!!;
    b = b.tappend("deps")!!;

    usz start = dep.repo.rindex_of_char('/')!!;
    usz end = dep.repo.rindex_of_char('.')!!;
    String repo_name = dep.repo[start + 1..end - 1];
    b = b.tappend(repo_name)!!;

    path::chdir(b)!!;
    @pool() {
        StrList args;
        args.tinit_with_array({"-B", "_build", "-G", "Ninja",
            "-DCMAKE_INSTALL_PREFIX=/", "-DCMAKE_INSTALL_LIBDIR=lib"});
        if (repo_name == "zstd") {
            foreach (String arg : {"-S", "build/cmake"}) {
                args.push(arg);
            }
        }

        foreach (flag : dep.flags) {
            args.push(flag);
        }
        log_info("Configuring %s", repo_name)!!;
        self.exec_array(args.to_tarray(), output: true)!!;
    };
    path::chdir(cwd.to_tpath()!!)!!;
}

fn void CMake.build(&self, Program ninja, CMakeDependency dep)
{
    Path b = build_dir.to_tpath()!!;
    b = b.tappend("deps")!!;

    usz start = dep.repo.rindex_of_char('/')!!;
    usz end = dep.repo.rindex_of_char('.')!!;
    String repo_name = dep.repo[start + 1..end - 1];
    b = b.tappend(repo_name)!!;
    b = b.tappend("_build")!!;

    path::chdir(b)!!;
    log_info("Building %s", repo_name)!!;
    ninja.exec(output: true)!!;
    path::chdir(cwd.to_tpath()!!)!!;
}

fn void CMake.install(&self, Program ninja, CMakeDependency dep)
{
    Path b = build_dir.to_tpath()!!;
    b = b.tappend("deps")!!;

    usz start = dep.repo.rindex_of_char('/')!!;
    usz end = dep.repo.rindex_of_char('.')!!;
    String repo_name = dep.repo[start + 1..end - 1];
    b = b.tappend(repo_name)!!;
    b = b.tappend("_build")!!;

    path::chdir(b)!!;
    log_info("Installing %s", repo_name)!!;
    ninja.exec("install", output: true)!!;
    path::chdir(cwd.to_tpath()!!)!!;
}

struct CMakeDependency {
    String repo;
    StrList flags;
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
