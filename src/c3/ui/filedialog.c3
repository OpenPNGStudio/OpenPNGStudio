/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import nk;

struct FileDialog {
    Window win;
}

fn FileDialog *filedialog_init(bool write) @export("filedialog_init")
{
    abort("filedialog_init");
}

/* returns false when in the root of the FS */
fn bool FileDialog.up(&self) @export("filedialog_up")
{
    abort("filedialog_up");
}

fn void FileDialog.enter(&self, char *dir) @export("filedialog_enter")
{
    abort("filedialog_enter");
}

/* returns the length of the selected file */
fn usz FileDialog.selsz(&self) @export("filedialog_selsz")
{
    abort("filedialog_selsz");
}

fn void FileDialog.selected(&self, usz selsz, char *buf) @export("filedialog_selected")
{
    abort("filedialog_selected");
}

fn void FileDialog.cfg(&self, bool write, char *filter, char *title) @export("filedialog_cfg")
{
    abort("filedialog_cfg");
}

fn bool FileDialog.is_selected(&self) @export("filedialog_is_selected")
{
    abort("filedialog_is_selected");
}

fn bool FileDialog.is_open(&self) @export("filedialog_is_open")
{
    abort("filedialog_is_open");
}

fn bool FileDialog.ready_for_write(&self) @export("filedialog_ready_for_write")
{
    abort("filedialog_ready_for_write");
}

fn char *FileDialog.path(&self) @export("filedialog_path")
{
    abort("filedialog_path");
}

fn void FileDialog.write_cleanup(&self) @export("filedialog_write_cleanup")
{
    abort("filedialog_write_cleanup");
}

/* once everything is setup, trigger opening */
fn void FileDialog.show(&self) @export("filedialog_show")
{
    abort("filedialog_show");
}

fn void FileDialog.run(&self, nk::Context *ctx, bool *ui_focused) @export("filedialog_run")
{
    abort("filedialog_run");
}

fn void FileDialog.deinit(&self) @export("filedialog_deinit")
{
    abort("filedialog_deinit");
}

fn void FileDialog.refresh(&self) @export("filedialog_refresh")
{
    abort("filedialog_refresh");
}
