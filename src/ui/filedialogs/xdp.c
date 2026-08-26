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

#endif
