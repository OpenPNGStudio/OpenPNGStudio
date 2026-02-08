/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::console;

import openpngstudio::ui::wm;
import std::collections::linkedlist;
import std::io, std::time;
import std::core::string;

import nk, raylib5::rl;

struct Record {
    LogPriority type;
    String file, fun;
    int line;
    ZString buffer;
}

struct Console (wm::Window, Logger) @local {
    Allocator alloc;
    int id;
    LinkedList{Record} record;
    float max_width;
}

const NLOGS = 128;

Console c @local;

fn void init(Allocator alloc)
{
    c.alloc = alloc;
    c.record.init(alloc);

    log::set_logger(&c);
}

fn void register(WindowManager *wm) => wm.register("Console", &c);

fn void free() => c.record.free();

fn void show(WindowManager *wm) => wm.show(&c);

fn void Console.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);

    nk::layout_row_begin(ctx, nk::STATIC, 30, 4);
    nk::layout_row_push(ctx, 0.20f * win_width);
    nk::label(ctx, "Function", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.10f * win_width);
    nk::label(ctx, "Line", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 0.10f * win_width);
    nk::label(ctx, "Type", nk::TEXT_LEFT);
    nk::layout_row_push(ctx, 100);
    nk::label(ctx, "Message", nk::TEXT_LEFT);
    nk::layout_row_end(ctx);

    float line_width = 0.4 * win_width + self.max_width;

    nk::layout_row_static(ctx, 2, (int) line_width, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);

    LinkedListArrayView{Record} logs = c.record.array_view();

    self.max_width = 0;

    foreach (&iter : logs) {
        nk::layout_row_begin(ctx, nk::STATIC, 30, 4);
        nk::layout_row_push(ctx, 0.20f * win_width);
        nk::label(ctx, (CChar*) iter.fun, nk::TEXT_LEFT);

        @pool() {
            ZString tmp = string::tformat_zstr("%d", iter.line);
            nk::layout_row_push(ctx, 0.10f * win_width);
            nk::label(ctx, (CChar*) tmp, nk::TEXT_LEFT);
        };

        nk::layout_row_push(ctx, 0.10f * win_width);
        switch (iter.type) {
	    case VERBOSE:
            nk::label_colored(ctx, "Debug", nk::TEXT_LEFT,
                nk::rgb(0x0D, 0xBC, 0x79));
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
        case CRITICAL:
            nk::label_colored(ctx, "Debug", nk::TEXT_LEFT,
                nk::rgb(0x0D, 0xBC, 0x79));
        }

        openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
        rl::Vector2 size = rl::measureTextEx(app_ctx.font, iter.buffer, 16, 
            1);

        if (size.x + 16 > self.max_width) self.max_width = size.x + 16;

        nk::layout_row_push(ctx, self.max_width);
        nk::label(ctx, (CChar*) iter.buffer, nk::TEXT_LEFT);

        nk::layout_row_end(ctx);
    }
}

fn void Console.log(&self, LogPriority priority, LogCategory category, 
    LogTag tag, String file, String function, int line, String fmt, 
    any[] args) @dynamic
{
	@stack_mem(256 + 64; Allocator mem)
	{
		DString str;
		str.init(mem, 256);
		str.appendf(fmt, ...args);
		TzDateTime time = datetime::now().to_local();
		io::eprintfn("[%02d:%02d:%02d:%04d] %s:%d [%s] %s", time.hour, 
            time.min, time.sec, (time.usec / 1000), file, line, priority, str);
	};

    if (self.record.len() == NLOGS) {
        if (try Record old = self.record.pop_front()) {
            allocator::free(self.alloc, old.buffer);
        }
    }

    @pool() {
        self.record.push({
            priority,
            file,
            function,
            line,
            string::tformat(fmt, ...args).zstr_copy(self.alloc)
        });
    };
}
