/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::filedialogs::xdp @if(env::LINUX);

import openpngstudio;
import std::core::log;
import std::net::url;
import ev;
import std::io;
import raylib5::rl;

struct XdpFileDialog (FileDialog) {
    GMainContext *loop;
    XdpPortal *portal;
    XdpParent *parent;
    Idle{XdpFileDialog*} glib_loop;
    GVariant *filters;
    Url[] urls;
    
    bool is_open;
    bool is_ready;
}

fn XdpFileDialog *init()
{
    GError *err;
    XdpPortal *portal = xdp_portal_initable_new(&err);
    if (!portal) {
        log::error("Failed to initialize libportal: %s", glib_errmsg(err));
        return null;
    }
    
    Context *ctx = openpngstudio::get_ctx();
    XdpFileDialog *self = mem::new(XdpFileDialog);
    self.portal = portal;
    self.loop = g_main_context_default();
    self.is_ready = false;
    
    self.glib_loop.init(self, &tick);
    ctx.loop.add(&self.glib_loop);
    
    return self;
}

fn void XdpFileDialog.open(&self, ZString title, bool multiple) @dynamic
{
    if (self.is_open) return;
    if (!self.parent) self.parent = xdp_parent_new_raylib(rl::getWindowHandle());
    
    self.is_open = true;
    xdp_portal_open_file(self.portal, self.parent, title, self.filters, null,
        null, multiple ? MULTIPLE : NONE, null, &on_open, self);
}

fn void XdpFileDialog.save(&self, ZString title) @dynamic
{
    if (self.is_open) return;
    if (!self.parent) self.parent = xdp_parent_new_raylib(rl::getWindowHandle());
    
    self.is_open = true;
    xdp_portal_save_file(self.portal, self.parent, "Save File", "model.opng",
        null, null, self.filters, null, null, NONE, null, &on_save, self);
}

fn void XdpFileDialog.set_filter(&self, ZString[] extensions) @dynamic
{
    self.filters = glib_make_filters(extensions, extensions.len);
}

fn bool XdpFileDialog.ready(&self) @dynamic => self.is_ready;
fn Url[] XdpFileDialog.uris(&self) @dynamic
{
    self.is_open = false;
    self.is_ready = false;
    
    return self.urls;
}

fn void on_open(GObject *src, GAsyncResult *ares, void *data) @local
{
    GError *err;
    XdpFileDialog *self = data;
    GVariant *res = xdp_portal_open_file_finish(self.portal, ares, &err);
    if (err) {
        log::warn("Failed to get result: %s", glib_errmsg(err));
        self.is_open = false;
        return;
    }
    
    shared(self, res);
}

fn void on_save(GObject *src, GAsyncResult *ares, void *data) @local
{
    GError *err;
    XdpFileDialog *self = data;
    GVariant *res = xdp_portal_save_file_finish(self.portal, ares, &err);
    if (err) {
        log::warn("Failed to get result: %s", glib_errmsg(err));
        self.is_open = false;
        return;
    }
    
    shared(self, res);
}

fn void shared(XdpFileDialog *self, GVariant *res) @local
{
    GVariant *uris = g_variant_lookup_value(res, "uris", null);
    usz count = g_variant_n_children(uris);
    
    self.urls = mem::new_array(Url, count);
    for (int i = 0; i < count; i++) {
        GVariant *g_uri = g_variant_get_child_value(uris, i);
        usz len;
        ZString str = g_variant_get_string(g_uri, &len);
        String uri = (String) str[:len];
        self.urls[i] = url::parse(mem, uri)!!;
        
        g_variant_unref(g_uri);
    }
    
    g_variant_unref(uris);
    g_variant_unref(res);
    
    self.is_ready = true;
}

fn ev::Action tick(Idle{XdpFileDialog*} *idle) @local
{
    XdpFileDialog *self = idle.ctx;
    
    g_main_context_iteration(self.loop, false);
    return REARM;
}

/* bindings */
alias GError = void;
alias GMainContext = void;
alias GVariant = void;
alias GVariantType = void;
alias GCancellable = void;
alias GObject = void;
alias GAsyncResult = void;

alias XdpPortal = void;
alias XdpParent = void;

constdef XdpOpenFileFlags {
    NONE = 0,
    MULTIPLE = 1,
    DIRECTORY = 2,
}

constdef XdpSaveFileFlags {
    NONE = 0,
}

alias GAsyncReadyCallback = fn void(GObject *source, GAsyncResult *res,
    void *data);

extern fn ZString glib_errmsg(GError *err);
extern fn GVariant *glib_make_filters(ZString *extensions, usz len);
extern fn XdpParent *xdp_parent_new_raylib(void *window);

extern fn GMainContext *g_main_context_default();
extern fn bool g_main_context_iteration(GMainContext *context, bool may_block);
extern fn GVariant *g_variant_lookup_value(GVariant *dict, ZString key,
    GVariantType *expect);
extern fn usz g_variant_n_children(GVariant *value);
extern fn GVariant *g_variant_get_child_value(GVariant *value, usz idx);
extern fn ZString g_variant_get_string(GVariant *value, usz *len);
extern fn void g_variant_unref(GVariant *value);

extern fn XdpPortal *xdp_portal_initable_new(GError** error);
extern fn void xdp_portal_open_file(XdpPortal* portal, XdpParent* parent,
    ZString title, GVariant* filters, GVariant* current_filter,
    GVariant* choices, XdpOpenFileFlags flags, GCancellable* cancellable,
    GAsyncReadyCallback callback, void *data);
extern fn GVariant* xdp_portal_open_file_finish(XdpPortal* portal,
    GAsyncResult* result, GError** error);
    
extern fn void xdp_portal_save_file(XdpPortal* portal, XdpParent* parent,
    ZString title, ZString current_name, ZString current_folder,
    ZString current_file, GVariant* filters, GVariant* current_filter,
    GVariant* choices, XdpSaveFileFlags flags, GCancellable* cancellable,
    GAsyncReadyCallback callback, void *data
);
extern fn GVariant *xdp_portal_save_file_finish(XdpPortal* portal,
    GAsyncResult* result, GError** error);
