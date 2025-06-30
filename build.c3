module build;

import libc;
import std::core::string, std::io, std::core::env;
import std::os;
import std::os::process;

String cwd;
String build_dir;

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

    String[] repos = {
        "https://github.com/libarchive/libarchive.git",
        "https://github.com/libuv/libuv.git",
        "https://github.com/raysan5/raylib.git",
        "https://github.com/wolfSSL/wolfssl.git",
        "https://github.com/facebook/zstd.git",
        };
    String[][] flags = {};

    Program git = find_program("git")!!;

    foreach (i, repo : repos) {
        @pool() {
            Path b = build_dir.to_tpath()!!;
            b = b.tappend("deps")!!;

            if (try usz start = repo.rindex_of_char('/')) {
                if (try usz end = repo.rindex_of_char('.')) {
                    Path local = b.tappend(repo[start + 1..end - 1])!!;
                    if (path::exists(local)) continue;
                        
                }
            }

            path::chdir(b)!!;
            git.exec("clone", "--depth=1", repo, output: true)!!;
            path::chdir(cwd.to_tpath()!!)!!;
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
        
        path::mkdir(b.tappend("lib")!!, recursive: true)!!;
        path::mkdir(b.tappend("include")!!, recursive: true)!!;
    };
}

alias Program = String;

struct Compiler {
    Program exe;
    String[] cflags;
    String[] ldflags;
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
    })!;
    return process.join()!;
}

macro log_info(String $fmt, args...) => io::eprintfn("| " +++ $fmt, $vasplat);
macro log_err(String $fmt, args...) => io::eprintfn("! " +++ $fmt, $vasplat);
