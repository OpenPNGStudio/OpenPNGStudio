/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::console;

import openpngstudio::ui::wm;
import std::collections::linkedlist;
import std::io;
import std::core::string;

import nk;

enum Type {
    DEBUG,
    INFO,
    WARN,
    ERROR
}

struct Record {
    Type type;
    ZString fun;
    usz line;
    ZString buffer;
}

struct Console (wm::Window) @local {
    Allocator alloc;
    int id;
    LinkedList{Record} log;
}

const NLOGS = 128;

Console c @local;

fn void init(WindowManager *wm, Allocator alloc)
{
    c.id = wm.next_id();
    c.alloc = alloc;
    c.log.init(alloc);
    wm.register("Console", &c);
}

fn void free()
{
    c.log.free();
}

fn void show(WindowManager *wm)
{
    wm.show(&c);
}

fn void Console.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 4);
    nk::layout_row_push(ctx, 0.20f);
    nk::label(ctx, "Function", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.10f);
    nk::label(ctx, "Line", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.17f);
    nk::label(ctx, "Type", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.43f);
    nk::label(ctx, "Message", nk::TEXT_LEFT);
    nk::layout_row_end(ctx);

    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);

    LinkedListArrayView{Record} logs = c.log.array_view();

    foreach (&iter : logs) {
        nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 4);
        nk::layout_row_push(ctx, 0.20f);
        nk::label(ctx, (CChar*) iter.fun, nk::TEXT_LEFT);

        @pool() {
            ZString tmp = string::tformat_zstr("%d", iter.line);
            nk::layout_row_push(ctx, 0.10f);
            nk::label(ctx, (CChar*) tmp, nk::TEXT_LEFT);
        };

        switch (iter.type) {
        case DEBUG:
            nk::label_colored(ctx, "Debug", nk::TEXT_LEFT,
                nk::rgb(0x0D, 0xBC, 0x79));
        case INFO:
            nk::label_colored(ctx, "Info", nk::TEXT_LEFT,
                nk::rgb(0x11, 0xA8, 0xCD));
        case WARN:
            nk::label_colored(ctx, "Warning", nk::TEXT_LEFT,
                nk::rgb(0xE5, 0xE5, 0x10));
        case ERROR:
            nk::label_colored(ctx, "Error", nk::TEXT_LEFT,
                nk::rgb(0xCd, 0x31, 0x31));
        }

        nk::layout_row_push(ctx, 0.5f);
        nk::label(ctx, (CChar*) iter.buffer, nk::TEXT_LEFT);

        nk::layout_row_end(ctx);
    }
}

fn int Console.get_id(&self) @dynamic => self.id;

fn void _debug(ZString fun, usz line, ZString fmt, args...)
    @export("console_debug")
{
    io::fprintf(io::stderr(), "%s:%d \e[42;1m\e[37;1m D \e[0m ", fun, line)!!;

    @pool() {
        String tmp = string::tformat(fmt.str_view(), ...args);
        io::fprintn(io::stderr(), tmp)!!;
        if (c.log.len() == NLOGS) c.log.pop_front()!!;

        c.log.push({
            DEBUG,
            fun,
            line,
            tmp.zstr_copy(c.alloc)
        });
    };
}

fn void _info(ZString fun, usz line, ZString fmt, args...)
    @export("console_info")
{
    io::fprintf(io::stderr(), "%s:%d \e[46;1m\e[37;1m I \e[0m ", fun, line)!!;

    @pool() {
        String tmp = string::tformat(fmt.str_view(), ...args);
        io::fprintn(io::stderr(), tmp)!!;
        if (c.log.len() == NLOGS) c.log.pop_front()!!;

        c.log.push({
            INFO,
            fun,
            line,
            tmp.zstr_copy(c.alloc)
        });
    };
}

fn void _warn(ZString fun, usz line, ZString fmt, args...) @export("console_warn")
{
    io::fprintf(io::stderr(), "%s:%d \e[43;1m\e[30;1m W \e[0m ", fun, line)!!;

    @pool() {
        String tmp = string::tformat(fmt.str_view(), ...args);
        io::fprintn(io::stderr(), tmp)!!;
        if (c.log.len() == NLOGS) c.log.pop_front()!!;

        c.log.push({
            WARN,
            fun,
            line,
            tmp.zstr_copy(c.alloc)
        });
    };
}

fn void _error(ZString fun, usz line, ZString fmt, args...) @export("console_error")
{
    io::fprintf(io::stderr(), "%s:%d \e[41;1m\e[30m E \e[0m ", fun, line)!!;

    @pool() {
        String tmp = string::tformat(fmt.str_view(), ...args);
        io::fprintn(io::stderr(), tmp)!!;
        if (c.log.len() == NLOGS) c.log.pop_front()!!;

        c.log.push({
            ERROR,
            fun,
            line,
            tmp.zstr_copy(c.alloc)
        });
    };
}
