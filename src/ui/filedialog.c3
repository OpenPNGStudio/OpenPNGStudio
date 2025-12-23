/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import libc;
import openpngstudio::ui::wm;
import openpngstudio::ui::icons;
import openpngstudio::ui::messagebox;
import openpngstudio::ui::line_edit;
import std::core::string;
import std::core::mem;
import std::io;
import std::io::path, std::sort, std::time;
import std::collections::list;
import nk;
import std::os::win32;

enum FileDialogState : const int {
    CLOSED,
    BROWSING,
    READ_READY,
    WRITE_READY
}

enum FileDialogEvent : const int {
    ENTER,
    LEAVE
}

struct FileDialogJournalEntry {
    FileDialogEvent event;
    String file;
}

struct FileDialogJournal {
    List{FileDialogJournalEntry} journal;
    usz index, limit;
    bool locked;
}

struct DirectoryEntry {
    Path path;
    bool is_file, is_hidden, is_system;
    nk::Bool selected;
}

struct FileDialog (wm::Window) {
    Path path;
    List{DirectoryEntry} content;
    List{String} filter;
    isz last_selected;
    bool show_hidden, show_system;
    Time time_to_click;
    List{ZString} selected;
    FileDialogState state;
    bool open_for_reading, single_file_mode, contextual_open;
    LineEdit search_filter, write_file_name;
    MessageBox msgbox;
    int id;

    FileDialogJournal history;
}

fn void FileDialog.init(&self, int id, Allocator alloc)
{
    self.last_selected = -1;
    self.path = path::home_directory(alloc)!!;
    self.history.journal.init(alloc);
    self.id = id;
}

fn void FileDialog.populate(&self)
{
    self.content.free();
    @pool() {
        PathList? files = path::ls(tmem, self.path);

        self.content.init(mem);

        if (catch excuse = files) {
            if (excuse == io::CANNOT_READ_DIR){ 
                self.msgbox = messagebox::error("Error", "Permissions Denied!");
            }
            return;
        }

        foreach (file : files) {
            DirectoryEntry ent;
            Path full_path = self.path.tappend(file.str_view())!!;

            ent.path = path::new(mem, file.str_view())!!;
            ent.is_file = !path::is_dir(full_path);
            ent.selected = false;
            os_extra(&ent)!!;

            if (ent.is_file && !matches(self, file.str_view())) continue;
            self.content.push(ent);
        }

        sort::quicksort(&self.content);
    };
}

fn void? os_extra(DirectoryEntry *ent) @local
{
    $if env::POSIX:
        if (String b = ent.path.basename()) {
            ent.is_hidden = b[0] == '.';
            ent.is_system = false;
        }
    $else
        Win32_FILE_ATTRIBUTE_DATA data;
        String s = ent.path.str_view();
        @pool() {
            win32::getFileAttributesExW(s.to_temp_wstring()!,
                Win32_GET_FILEEX_INFO_LEVELS.STANDARD, &data);
            ent.is_hidden = data.dwFileAttributes &
                win32::FILE_ATTRIBUTE_HIDDEN ? true : false;
            ent.is_system = data.dwFileAttributes &
                win32::FILE_ATTRIBUTE_SYSTEM ? true : false;
        };
    $endif
}

fn bool matches(FileDialog *self, String file) @local
{
    if (self.filter.len() == 0) return true;

    foreach (fil : self.filter) {
        if (file.ends_with(fil)) return true;
    }

    return false;
}

fn void FileDialog.update(&self) @dynamic
{
    self.state = BROWSING;
}

fn void FileDialog.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    messagebox::run(&self.msgbox, ctx);

    draw_titlebar(self, ctx);

    nk::Rect bounds = nk::window_get_content_region(ctx);
    bounds.h -= 35 * 2;
    bounds.h -= ctx.style.window.spacing.y * 2.77;

    usz selected = 0;

    nk::layout_row_dynamic(ctx, bounds.h, 1);
    bounds = nk::widget_bounds(ctx);
    if (nk::group_begin(ctx, "Files", 0)) {
        draw_contextual(self, ctx, bounds);
        bool to_populate = false;
        nk::layout_row_dynamic(ctx, 32, 1);
        nk::style_push_vec2(ctx, &ctx.style.window.group_padding,
            nk::vec2(0, 0));

        foreach (i, &ent : self.content) {
            if (ent.is_hidden && !self.show_hidden) continue;
            if (ent.is_system && !self.show_system) continue;
            if LEN: (self.search_filter.buffer != null) {
                String s = (String)
                    self.search_filter.buffer[:self.search_filter.len];

                if (s.len == 0) break LEN; 
                if (!ent.path.str_view().contains(s)) continue;
            }

            if (draw_entry(self, ctx, ent)) {
                if (!ent.is_file) {
                    Time now = time::now();

                    if (i == self.last_selected &&
                        now < self.time_to_click) {
                        self.enter(ent.path.str_view())!!;
                        to_populate = true;
                    } else {
                        self.time_to_click = now + 350 * time::MS;
                    }
                }

                if (self.single_file_mode && self.last_selected != -1) {
                    DirectoryEntry *prev = self.content.get_ref(
                        self.last_selected);
                    prev.selected = false;
                }
                
                self.last_selected = ent.selected ? i : -1;
            }

            if (ent.selected) selected++;
        }

        if (self.single_file_mode) selected = min(selected, 1);

        if (to_populate) self.populate();

        nk::style_pop_vec2(ctx);
        nk::group_end(ctx);
    }

    draw_footerbar(self, ctx, selected);
}

fn void FileDialog.on_close(&self) @dynamic
{
    self.last_selected = -1;
    self.state = CLOSED;
}

fn int FileDialog.get_id(&self) @dynamic => self.id;

fn void draw_titlebar(FileDialog *self, nk::Context *ctx) @local
{
    nk::layout_row_template_begin(ctx, 32);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 32);
    nk::layout_row_template_end(ctx);

    if (!self.history.can_prev()) nk::widget_disable_begin(ctx);
    if (nk::button_image(ctx, icons::get(LEFT))) {
        self.history.prev(self);
        self.populate();
    }
    if (!self.history.can_prev()) nk::widget_disable_end(ctx);
    if (!self.history.can_next()) nk::widget_disable_begin(ctx);
    if (nk::button_image(ctx, icons::get(RIGHT))) {
        self.history.next(self);
        self.populate();
    }
    if (!self.history.can_next()) nk::widget_disable_end(ctx);

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

fn void draw_contextual(FileDialog *self, nk::Context *ctx, nk::Rect bounds)
    @local
{
    self.contextual_open = self.msgbox.res != -1;

    if (nk::contextual_begin(ctx, 0, nk::vec2(128, 128), bounds)) {
        do BEGIN:
        {
            if (!self.contextual_open) {
                nk::contextual_close(ctx);
                break BEGIN;
            }

            nk::layout_row_dynamic(ctx, 30, 1);

            if (nk::contextual_item_label(ctx, "Search", nk::TEXT_LEFT)) {
                self.search_filter.cleanup = true;
                self.msgbox = messagebox::custom("Search", &on_search, 
                    &self.search_filter);
            }

            nk::checkbox_label(ctx, "Show Hidden Files", &self.show_hidden);
            $if env::WIN32:
            nk::checkbox_label(ctx, "Show System Files", &self.show_system);
            $endif
        };
        nk::contextual_end(ctx);
    }

}

fn int on_search(nk::Context *ctx, MessageBox *box) @local
{
    LineEdit *line = box.userdata;

    nk::layout_row_dynamic(ctx, 30, 1);
    nk::label(ctx, "Search Term: ", nk::TEXT_LEFT);
    line_edit::line_edit_draw(line, ctx);

    nk::Rect bounds = nk::window_get_content_region(ctx);

    bounds.h -= 30 * 4;

    nk::layout_row_dynamic(ctx, bounds.h, 1);
    nk::spacer(ctx);
    nk::layout_row_template_begin(ctx, 32);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 64);
    nk::layout_row_template_end(ctx);

    nk::spacer(ctx);
    if (nk::button_label(ctx, "Ok")) return 0;

    return -1;
}

fn void draw_footerbar(FileDialog *self, nk::Context *ctx, usz count) @local
{
    @pool() {
        bool has_dir = false;
        nk::layout_row_template_begin(ctx, 32);
        nk::layout_row_template_push_dynamic(ctx);

        if (self.filter.len() > 0) {
            nk::layout_row_template_push_static(ctx, 96);
        }

        nk::layout_row_template_push_static(ctx, 80);
        nk::layout_row_template_push_static(ctx, 80);
        nk::layout_row_template_end(ctx);
        String selected = "";

        foreach (ent : self.content) {
            if (ent.selected) {
                if (count == 1) {
                    selected = ent.path.str_view();
                    has_dir = !ent.is_file;
                    break;
                }

                if (!ent.is_file) has_dir = true;

                selected = selected.tconcat(
                    string::tformat("\"%s\" ", ent.path.str_view())
                );
            }
        }

        if (self.open_for_reading) {
            nk::edit_string(ctx, nk::EDIT_DEACTIVATED, (CChar*) selected.ptr,
                (CInt*) &&selected.len, selected.len + 1, &nk::filter_default);
        } else {
            if (count == 1) {
                self.write_file_name.buffer = selected.copy(mem);
                self.write_file_name.len = selected.len;
                self.write_file_name.cleanup = false;
            }
            line_edit::line_edit_draw(&self.write_file_name, ctx);
        }

        if (self.filter.len() > 0) {
            if (nk::combo_begin_label(ctx, "Filters", nk::vec2(96, 64))) {
                nk::layout_row_dynamic(ctx, 30, 1);
                @pool() {
                    foreach (fil : self.filter) {
                        nk::label(ctx, (CChar*) fil.zstr_tcopy(), nk::TEXT_LEFT);
                    }
                };
                nk::combo_end(ctx);
            }
        }

        if OUT: (nk::button_label(ctx, self.open_for_reading ? "Open" : "Save")) {
            if (!has_dir) {
                if (self.open_for_reading) {
                    if (count > 0) {
                        handle_open(self);
                    } else {
                        self.msgbox = messagebox::warn("Warning", "No file was"
                            " selected");
                        break OUT;
                    }
                } else {
                    handle_write(self);
                }
                self.state = READ_READY;
            } else {
                self.msgbox = messagebox::warn("Warning", "A directory was"
                    " selected");
            }
        }

        if (nk::button_label(ctx, "Cancel")) {
            self.state = CLOSED;
        }
    };
}

fn void handle_write(FileDialog *self) @local
{
    self.selected.free();
    self.selected.init(mem);

    @pool() {
        String s = (String)
            self.write_file_name.buffer[:self.write_file_name.len];
        Path full_path = self.path.tappend(s)!!;
        self.selected.push(full_path.str_view().zstr_copy(mem));
    };
}

fn void handle_open(FileDialog *self) @local
{
    self.selected.free();
    self.selected.init(mem);

    foreach (ent : self.content) {
        @pool() {
            if (ent.selected) {
                Path full_path = self.path.tappend(ent.path.str_view())!!;
                self.selected.push(full_path.str_view().zstr_copy(mem));
            }
        };
    }
}

fn bool draw_entry(FileDialog *self, nk::Context *ctx, DirectoryEntry *ent) @local
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
    self.history.register(LEAVE, self.path.basename());

    self.path = self.path.parent()!;
    self.search_filter.cleanup = true;
    line_edit::line_edit_cleanup(&self.search_filter);
}

fn void? FileDialog.enter(&self, String name)
{
    self.path = self.path.append(mem, name)!;
    self.search_filter.cleanup = true;
    line_edit::line_edit_cleanup(&self.search_filter);

    self.history.register(ENTER, name);
}

fn void? FileDialog.free(&self)
{
    self.filter.free();
    self.selected.free();
}

fn void FileDialog.show(&self, WindowManager *wm)
{
    wm.show(self);
}

fn void FileDialog.open_file(&self)
{
    self.open_for_reading = true;
    self.single_file_mode = true;
    self.state = CLOSED;
}

fn void FileDialog.open_files(&self)
{
    self.open_for_reading = true;
    self.single_file_mode = false;
    self.state = CLOSED;
}

fn void FileDialog.write_file(&self)
{
    self.open_for_reading = false;
    self.single_file_mode = true;
    self.state = CLOSED;
    self.write_file_name.cleanup = true;
    line_edit::line_edit_cleanup(&self.write_file_name);
}

fn List{ZString} FileDialog.get_selection(&self)
{
    return self.selected;
}

fn void FileDialog.set_title(&self, WindowManager *wm, ZString title)
{
    wm.set_title(self, title);
}

fn void FileDialog.set_filter(&self, ZString filter)
{ 
    self.filter.free();
    self.filter.init(mem);

    if (filter == null) return;

    String s = filter.str_view();
    Splitter sp = s.tokenize(";");

    while (try String tok = sp.next()) {
        self.filter.push(tok);
    }
}

fn FileDialogState FileDialog.get_state(&self)
{
    return self.state;
}

fn void FileDialog.reset(&self)
{
    self.state = CLOSED;
}

fn bool DirectoryEntry.less(&self, DirectoryEntry b)
{
    if (self.is_file != b.is_file) return !self.is_file;

    String ap, bp;
    ap = self.path.str_view();
    bp = b.path.str_view();

    return libc::strncmp(ap.ptr, bp.ptr, min(ap.len, bp.len)) < 0;
}

fn bool FileDialogJournal.can_next(&self) => self.index < self.limit;
fn bool FileDialogJournal.can_prev(&self) => self.index > 0;

fn void FileDialogJournal.register(&self, FileDialogEvent ev, String file)
{
    if (self.locked) return;
    self.locked = true;
    defer self.locked = false;

    if (self.index <= self.limit) {
        if (self.index == self.limit) {
            if (self.limit == self.journal.len()) {
                self.journal.push({
                    .event = ev,
                    .file = file
                });
                self.index++;
            } else {
                self.journal[self.index++] = {
                    .event = ev,
                    .file = file
                };
            }
        } else {
            self.journal[self.index++] = {
                .event = ev,
                .file = file
            };
        }
    }
    self.limit = self.index;
}

fn void FileDialogJournal.next(&self, FileDialog *dialog)
{
    if (self.locked) return;
    self.locked = true;
    defer self.locked = false;

    if (self.index < self.limit) {
        FileDialogJournalEntry *ent = self.journal.get_ref(self.index++);
        if (ent.event == ENTER) {
            dialog.enter(ent.file)!!;
        } else {
            if (try dialog.up()) {}
        }
    }
}

fn void FileDialogJournal.prev(&self, FileDialog *dialog)
{
    if (self.locked) return;
    self.locked = true;
    defer self.locked = false;

    if (self.index > 0) {
        FileDialogJournalEntry *ent = self.journal.get_ref(--self.index);
        if (ent.event == LEAVE) {
            dialog.enter(ent.file)!!;
        } else {
            dialog.up()!!;
        }
    }
}
