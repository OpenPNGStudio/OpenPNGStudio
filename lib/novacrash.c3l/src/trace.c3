module novacrash::trace;

import std::os::backtrace;
import std::collections::list;

struct StackTrace {
    Allocator alloc;
    BacktraceList backtrace;
}

fn void StackTrace.init(&self, Allocator alloc)
{
    self.alloc = alloc;
}

fn void StackTrace.free(&self)
{
    self.backtrace.free();
}

fn bool StackTrace.populate(&self) @if(env::NATIVE_STACKTRACE)
{
    void*[256] trace;
    void*[] backtraces = backtrace::capture_current(&trace);
    BacktraceList? list = backtrace::symbolize_backtrace(self.alloc, backtraces);
    if (catch list) return false;
    self.backtrace = list;
    return true;
}
