/* SPDX-License-Identifier: GPL-3.0-or-later */
#ifdef __linux__
#include <libportal/portal.h>

#include <stdbool.h>
#include <stdio.h>
#include <parent-private.h>
#include <wayland-client.h>
#include <xdg-foreign-unstable-v1-client-protocol.h>

/* extern */
#define GLFW_PLATFORM_WAYLAND       0x00060003
#define GLFW_PLATFORM_X11           0x00060004

int glfwGetPlatform();
struct wl_display *glfwGetWaylandDisplay();

static struct zxdg_exporter_v1 *exporter;

/* utils */
const char *glib_errmsg(GError *err) { return err->message; }

GVariant *glib_make_filters(const char **extensions, size_t len)
{
    GVariantBuilder *a1;
    GVariantBuilder *a2;
    a1 = g_variant_builder_new(G_VARIANT_TYPE("a(us)"));
    a2 = g_variant_builder_new(G_VARIANT_TYPE("a(sa(us))"));
    
    for (int i = 0; i < len; i++) {
        g_variant_builder_add(a1, "(us)", 0, extensions[i]);
    }
    
    g_variant_builder_add(a2, "(s@a(us))", "Filter", g_variant_builder_end(a1));
    
    return g_variant_builder_end(a2);
}

bool is_platform_wayland(void) {
    return glfwGetPlatform() == GLFW_PLATFORM_WAYLAND;
}

bool is_platform_x11(void) {
    return glfwGetPlatform() == GLFW_PLATFORM_X11;
}

/* xdp parent */

static void handle_global(void *data, struct wl_registry *registry,
    uint32_t name, const char *interface, uint32_t version)
{
    if (strcmp(interface, zxdg_exporter_v1_interface.name) == 0) {
        exporter = wl_registry_bind(registry, name, &zxdg_exporter_v1_interface,
            1);
    }
}

static void noop() {}

static const struct wl_registry_listener registry_listener = {
    .global = handle_global,
    .global_remove = noop,
};

static void handle_exported(void *data, struct zxdg_exported_v1 *exported, const char *handle) {
    XdpParent *parent = data;
    
    g_autofree char *handle_str = g_strdup_printf("wayland:%s", handle);
    
    parent->exported_handle = g_strdup(handle);
    parent->callback(parent, handle_str, parent->data);
    zxdg_exported_v1_destroy(exported);
}

static const struct zxdg_exported_v1_listener exported_listener = {
    .handle = handle_exported,
};

static gboolean
_xdp_parent_export_raylib(XdpParent *parent, XdpParentExported callback,
    gpointer data)
{
    if (is_platform_x11()) {
        guint32 xid = *(guint32*) data;
        g_autofree char *handle = g_strdup_printf("x11:%x", xid);
        
        parent->exported_handle = g_strdup(handle);
        callback(parent, handle, data);
        return TRUE;
    } else if (is_platform_wayland()) {
        struct wl_surface *surface = parent->data;
        struct wl_display *dpy = glfwGetWaylandDisplay();
        struct wl_registry *registry = wl_display_get_registry(dpy);
        
        wl_registry_add_listener(registry, &registry_listener, NULL);
        wl_display_roundtrip(dpy);
        if (!exporter) return FALSE;
        
        parent->callback = callback;
        parent->data = data;
        struct zxdg_exported_v1 *exported = zxdg_exporter_v1_export(exporter,
            surface);
        zxdg_exported_v1_add_listener(exported, &exported_listener, parent);
        wl_display_flush(dpy);
        
        return TRUE;
    }
    
    return FALSE;
}

static void _xdp_parent_unexport_raylib(G_GNUC_UNUSED XdpParent *parent)
{
}

XdpParent *xdp_parent_new_raylib(void *window)
{
    XdpParent *parent = g_new0(XdpParent, 1);
    parent->parent_export = _xdp_parent_export_raylib;
    parent->parent_unexport = _xdp_parent_unexport_raylib;
    parent->data = (gpointer) window;
    
    return parent;
}
#endif