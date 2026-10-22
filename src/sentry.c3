/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::sentry @local;

import std::io;
import std::os;

import libc;

fn void setup(ZString handler_path, ZString db_path, ZString reporter_path) @public
{
    env::set_var("SENTRY_DSN", "");
    env::set_var("SENTRY_DEBUG", "0");

    $if env::POSIX:
    libc::signal(libc::SIGBUS, null);
    $endif
    libc::signal(libc::SIGILL, null);
    libc::signal(libc::SIGSEGV, null);

    Options *opts = options_new();
    options_set_handler_path(opts, handler_path);
    options_set_external_crash_reporter_path(opts, reporter_path);
    options_set_database_path(opts, db_path);
    options_set_debug(opts, false);
    options_set_release(opts, "OpenPNGStudio@" +++ $$PROJECT_VERSION);
    options_set_environment(opts, "production");
    options_set_crash_reporting_mode(opts, MINIDUMP);

    init(opts);
}

fn void end() @public => close();

/* bindings */
alias Options = void;

constdef CrashReportingMode : int {
    MINIDUMP = 0,
    NATIVE = 1,
    NATIVE_WITH_MINIDUMP = 2
}

extern fn Options *options_new() @cname("sentry_options_new");
extern fn void options_set_database_path(Options *self, ZString path)
    @cname("sentry_options_set_database_path");
extern fn void options_set_handler_path(Options *self, ZString path)
    @cname("sentry_options_set_handler_path");
extern fn void options_set_external_crash_reporter_path(Options *self, ZString path)
    @cname("sentry_options_set_external_crash_reporter_path");
extern fn void options_set_debug(Options *self, bool enable)
    @cname("sentry_options_set_debug");
extern fn void options_set_release(Options *self, ZString release)
    @cname("sentry_options_set_release");
extern fn void options_set_environment(Options *self, ZString env)
    @cname("sentry_options_set_environment");
extern fn void options_set_crash_reporting_mode(Options *self, CrashReportingMode mode)
    @cname("sentry_options_set_crash_reporting_mode");

extern fn int init(Options *self) @cname("sentry_init");
extern fn int close() @cname("sentry_close");