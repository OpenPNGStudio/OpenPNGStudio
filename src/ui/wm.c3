/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::wm;

import nk;
import std::core::mem, std::collections::list;

enum State @local {
    HIDE,
    SHOW,
    CLOSE,
}

interface Window {
    fn int get_id();
    fn void update() @optional;
    fn void draw(WindowManager *wm, nk::Context *ctx);
    fn void on_close() @optional;
}

struct ManagedWindow {
    nk::Rect geometry;
    ZString title;
    State state;
    bool focus, show;
    float header_height;
    Window win;
}

struct WindowManager {
    List{ManagedWindow} windows;
    ui::Panel *panel;
    bool show_bring_back;
    int id;
}

fn void WindowManager.init(&self, ui::Panel *panel, Allocator alloc)
{
    self.show_bring_back = false;
    self.id = 0;
    self.panel = panel;
    self.windows.init(alloc);
}

fn void WindowManager.free(&self) => self.windows.free();
fn int WindowManager.next_id(&self) => self.id++;

fn void WindowManager.register(&self, ZString title, Window win) =>
    self.windows.push({
        .geometry = nk::rect(0, 0, 0, 0),
        .title = title,
        .state = HIDE,
        .focus = false,
        .show = false,
        .header_height = -1,
        .win = win,
    });

fn void WindowManager.show(&self, Window win)
{
    foreach (&managed : self.windows) {
        if (managed.win.get_id() == win.get_id()) {
            if (managed.show) break;

            managed.show = true;
            managed.state = SHOW;
            break;
        }
    }
}

fn void WindowManager.hide(&self, Window win)
{
    foreach (&managed : self.windows) {
        if (managed.win.get_id() == win.get_id()) {
            managed.show = false;
            managed.state = CLOSE;
            if (&managed.win.on_close) managed.win.on_close();
            break;
        }
    }
}

fn void WindowManager.set_title(&self, Window win, ZString title)
{
    foreach (&managed : self.windows) {
        if (managed.win.get_id() == win.get_id()) {
            managed.title = title;
            break;
        }
    }
}

enum Corner @local {
    UPPER_LEFT,
    UPPER_RIGHT,
    LOWER_LEFT,
    LOWER_RIGHT,
}

fn void WindowManager.update(&self, int width, int height)
{
    bool all_showing = true;

    foreach (&managed : self.windows) {
        /* check if header is not reachable */
        if (all_showing && managed.header_height != -1 && managed.show) {
            Corner c;

            if (managed.geometry.x < width / 2.0f) {
                if (managed.geometry.y < height / 2.0f) { c = UPPER_LEFT; }
                else { c = LOWER_LEFT; }
            } else {
                if (managed.geometry.y < height / 2.0f) { c = UPPER_RIGHT; }
                else { c = LOWER_RIGHT; }
            }

            float corner_x, corner_y;

            switch (c) {
            case UPPER_LEFT:
                corner_x = managed.geometry.x + managed.geometry.w;
                corner_y = managed.geometry.y + managed.header_height;

                if (corner_x <= 0 || corner_y <= 0) all_showing = false;
                break;
            case UPPER_RIGHT:
                corner_x = managed.geometry.x;
                corner_y = managed.geometry.y + managed.header_height;

                if (corner_x >= width || corner_y <= 0) all_showing = false;
                break;
            case LOWER_LEFT:
                corner_x = managed.geometry.x + managed.geometry.w;
                corner_y = managed.geometry.y;

                if (corner_x <= 0 || corner_y >= height) all_showing = false;
                break;
            case LOWER_RIGHT:
                corner_x = managed.geometry.x;
                corner_y = managed.geometry.y;

                if (corner_x >= width || corner_y >= height) {
                    all_showing = false;
                }
                break;
            }
        }

        if (managed.state == SHOW) {
            if (&managed.win.update) managed.win.update();
        }
    }

    self.show_bring_back = !all_showing;
}

fn void WindowManager.ui(&self, nk::Context *ctx, int width, int height)
{
    foreach (&managed : self.windows) {
        managed.focus = false;

        if (managed.geometry.x == 0 && managed.geometry.y == 0 &&
            managed.geometry.w == 0 && managed.geometry.h == 0) {
            float w = width / 100.0f * 80.0f;
            float h = height / 100.0f * 80.0f;
            float x = (width - w) / 2.0f;
            float y = (height - h) / 2.0f;

            managed.geometry = nk::rect(x, y, w, h);
        }

        if (managed.show) {
            if (nk::begin(ctx, (CChar*) managed.title, managed.geometry,
                nk::WINDOW_TITLE | nk::WINDOW_MOVABLE | nk::WINDOW_CLOSABLE | 
                nk::WINDOW_BORDER | nk::WINDOW_MINIMIZABLE |
                nk::WINDOW_SCALABLE | nk::WINDOW_SCROLL_AUTO_HIDE)) {
                nk::Vec2 pos = nk::window_get_position(ctx);
                if (nk::input_is_mouse_hovering_rect(&ctx.input,
                    nk::window_get_bounds(ctx))) {
                    managed.focus = true;
                }

                managed.state = SHOW;

                if (managed.header_height == -1) {
                    if (nk::Panel *panel = nk::window_get_panel(ctx)) {
                        managed.header_height = panel.header_height;
                    }
                }

                nk::Vec2 wprops = nk::window_get_position(ctx);
                managed.geometry.x = wprops.x;
                managed.geometry.y = wprops.y;

                wprops = nk::window_get_size(ctx);
                managed.geometry.w = wprops.x;
                managed.geometry.h = wprops.y;

                managed.win.draw(self, ctx);
            } else {
                managed.focus = false;
                if (managed.state == SHOW) {
                    if (&managed.win.on_close) managed.win.on_close();
                }

                managed.state = CLOSE;
                managed.show = nk::window_is_active(ctx, (CChar*) managed.title);
            }

            if (managed.state != HIDE) nk::end(ctx);
        }
    }
}

// Example dummy window
//
// import std::io;
//
// struct DummyWindow (Window) {
//     int id;
//     int awawawa;
// }
//
// fn void DummyWindow.update(&self) @dynamic
// {
//     io::printfn("update %d", self.awawawa);
// }
//
// fn void DummyWindow.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
// {
//     nk::layout_row_dynamic(ctx, 30, 1);
//     nk::label(ctx, "Label", nk::TEXT_LEFT);
// }
//
// fn void DummyWindow.on_close(&self) @dynamic
// {
//     io::printfn("close %d", self.awawawa);
// }
//
// fn int DummyWindow.get_id(&self) @dynamic => self.id;
