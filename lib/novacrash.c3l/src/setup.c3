module novacrash;

import std::io;
import std::core::builtin;
import novacrash::trace;
import novacrash::ui;
import novacrash::options;
import libc;

bool in_panic @local = false;
bool uses_raylib = false;

fn void nova_panic(String msg, String file, String fun, uint line) @if(env::NATIVE_STACKTRACE)
{
    if (in_panic) {
    $if $defined(io::stderr):
        io::eprintn("Double panic!");
        builtin::print_backtrace(msg, 5);
    $endif
        $$trap();
    }
    in_panic = true;
    StackTrace trace;
    trace.init(mem);
    defer trace.free();

    if (!trace.populate()) {
    $if $defined(io::stderr):
        io::eprintn("Unable to populate the stack trace!");
    $endif
        $$trap();
    }

    Ui ui;
    if (catch ui.init(msg, file, fun, line, &trace)) {
        builtin::print_backtrace(msg, 5);
        $$trap();
    }
    if (catch ui::draw(&ui)) $$trap();
    in_panic = false;
    $$trap();
}

fn void nova_panic(String msg, String file, String fun, uint line) @if(!env::NATIVE_STACKTRACE)
{
    if (in_panic) {
    $if $defined(io::stderr):
        io::eprintn("Double panic!");
        builtin::print_backtrace(msg, 5);
    $endif
        $$trap();
    }
    in_panic = true;
    $if $defined(io::stderr):
	io::eprint("\nERROR: '");
	io::eprint(msg);
	io::eprintfn("', in %s (%s:%d)", fun, file, line);
    $endif
    in_panic = false;
    $$trap();
}

fn void nova_sig_segmentation_fault(CInt i) => nova_panic("Out of bounds memory access.", "???", "???", 0);
fn void nova_sig_bus_error(CInt i) => nova_panic("Illegal memory access.", "???", "???", 0);
fn void nova_sig_abort_error(CInt i) => nova_panic("Abort", "???", "???", 0);

fn void setup() @init {
    builtin::panic = &nova_panic;
    
	libc::signal(libc::SIGBUS, &nova_sig_bus_error);
	libc::signal(libc::SIGSEGV, &nova_sig_segmentation_fault);
	libc::signal(libc::SIGABRT, &nova_sig_abort_error);
}
