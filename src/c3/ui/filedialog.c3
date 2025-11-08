/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import libc;
import openpngstudio::ui::window;
import openpngstudio::ui::icons;
import std::core::string;
import std::core::mem;
import std::io;
import std::io::path, std::sort;
import std::collections::list;
import nk;

struct DirectoryEntry {
    Path path;
    bool is_file, is_hidden, is_system;
    nk::Bool selected;
}

struct FileDialog {
    window::Window win;
    Path path;
    List{DirectoryEntry} content;
    usz last_selected;

    char *title;
}

fn FileDialog *new_filedialog() @export("fdialog_init")
{
    FileDialog *fd = calloc(FileDialog.sizeof);
    fd.title = "FileOpenDialog";
    fd.win.show = true;
    fd.last_selected = -1;

    return fd;
}

fn void FileDialog.open_at_home(&self) @export("fdialog_open_at_home")
{
    self.path = path::home_directory(mem)!!;
}

fn void FileDialog.populate(&self) @export("fdialog_populate")
{
    self.content.free();
    @pool() {
        PathList files = path::ls(tmem, self.path)!!;
        self.content.init(mem);

        foreach (file : files) {
            DirectoryEntry ent;
            Path full_path = self.path.tappend(file.str_view())!!;

            ent.path = path::new(mem, file.str_view())!!;
            ent.is_file = !path::is_dir(full_path);
            /* TODO: properly hide files */
            ent.is_hidden = false;
            ent.is_system = false;
            ent.selected = false;
            self.content.push(ent);
        }

        sort::quicksort(&self.content);
    };
}

fn void FileDialog.run(&self, nk::Context *ctx, bool *focused) @export("fdialog_run")
{
    if (self.win.ctx == null) window::window_init(&self.win, ctx, self.title);

    if (window::window_begin(&self.win, nk::WINDOW_TITLE | nk::WINDOW_CLOSABLE |
        nk::WINDOW_MOVABLE | nk::WINDOW_SCALABLE | nk::WINDOW_BORDER |
        nk::WINDOW_NO_SCROLLBAR)) {
        if (self.win.focus) *focused = true;

        draw_titlebar(self, ctx);

        nk::Rect bounds = nk::window_get_content_region(ctx);
        bounds.h -= 35 * 2;
        bounds.h -= ctx.style.window.spacing.y * 2;

        nk::layout_row_dynamic(ctx, bounds.h, 1);
        if (nk::group_begin(ctx, "Files", 0)) {
            bool to_populate = false;
            nk::layout_row_dynamic(ctx, 32, 1);
            nk::style_push_vec2(ctx, &ctx.style.window.group_padding,
                nk::vec2(0, 0));

            foreach (i, &ent : self.content) {
                if (draw_entry(self, ctx, ent)) {
                    if (!ent.is_file && i == self.last_selected) {
                        self.enter(ent.path.str_view())!!;
                        to_populate = true;
                    }
                    
                    self.last_selected = ent.selected ? i : -1;
                }
            }

            if (to_populate) self.populate();

            nk::style_pop_vec2(ctx);
            nk::group_end(ctx);
        }

        draw_footerbar(self, ctx);
    }

    if (self.win.state != HIDE)  window::window_end(&self.win);
}

fn void draw_titlebar(FileDialog *self, nk::Context *ctx) @local
{
    nk::layout_row_template_begin(ctx, 32);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_end(ctx);

    nk::widget_disable_begin(ctx);
    nk::button_image(ctx, icons::get(LEFT));
    nk::button_image(ctx, icons::get(RIGHT));
    nk::widget_disable_end(ctx);

    if (nk::button_image(ctx, icons::get(UP))) {
        if (try self.up()) {}
        self.populate();
    }

    String path_view = self.path.str_view();
    if (path_view.len == 0) path_view = "/";

    nk::edit_string(ctx, nk::EDIT_DEACTIVATED, (CChar*) path_view.ptr,
        (CInt*) &&path_view.len, path_view.len + 1, &nk::filter_default);

    if (nk::button_image(ctx, icons::get(LOOP))) {
        self.populate();
    }
}

fn void draw_footerbar(FileDialog *self, nk::Context *ctx) @local
{
    @pool() {
        nk::layout_row_template_begin(ctx, 32);
        nk::layout_row_template_push_dynamic(ctx);
        nk::layout_row_template_push_static(ctx, 80);
        nk::layout_row_template_push_static(ctx, 80);
        nk::layout_row_template_push_static(ctx, 80);
        nk::layout_row_template_end(ctx);
        String selected = "";

        foreach (ent : self.content) {
            if (ent.selected) {
                selected = selected.tconcat(
                    string::tformat("\"%s\" ", ent.path.str_view())
                );
            }
        }

        /* TODO: handle write */
        nk::edit_string(ctx, nk::EDIT_DEACTIVATED, (CChar*) selected.ptr,
            (CInt*) &&selected.len, selected.len + 1, &nk::filter_default);

        nk::button_label(ctx, "Filters");
        nk::button_label(ctx, "Open");
        nk::button_label(ctx, "Cancel");
    };
}


fn bool draw_entry(FileDialog *self, nk::Context *ctx, DirectoryEntry *ent)
{
    @pool() {
        ZString name = ent.path.str_view().zstr_tcopy();
        if (nk::group_begin(ctx, (CChar*) name, nk::WINDOW_NO_SCROLLBAR)) {
            nk::layout_row_dynamic(ctx, 32, 1);

            nk::Image icon = icons::get(FILE);
            if (!ent.is_file) icon = icons::get(DIR);

            bool res = nk::selectable_image_label(ctx, icon, (CChar*) name,
                nk::TEXT_LEFT, &ent.selected);


            nk::group_end(ctx);
            return res;
        }
    };
    return false;
}

fn void? FileDialog.up(&self)
{
    self.path = self.path.parent()!;
    io::printn(self.path.str_view());
}

fn void? FileDialog.enter(&self, String name)
{
    self.path = self.path.append(mem, name)!;
}

fn bool DirectoryEntry.less(&self, DirectoryEntry b)
{
    if (self.is_file != b.is_file) return !self.is_file;

    String ap, bp;
    ap = self.path.str_view();
    bp = b.path.str_view();

    return libc::strncmp(ap.ptr, bp.ptr, min(ap.len, bp.len)) < 0;
}
