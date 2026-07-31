/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio;

import std::io, std::os::env, std::collections::object, std::encoding::json;
import raylib5::rl;

struct Settings {
    Path conf_file;
    bool transparency;
    /* RGBA */
    union {
        char[4] bg_color;
        uint bg_repr;
    }
    
    ZString mic_name;
    usz mic_trigger;
    int mic_sensitivity;
}

fn void? Settings.init(&self, Context *ctx)
{
    ctx.scene.background = { 0x88, 0x88, 0x88, 0xFF };
    
    if (populate_self(self)!) {
        ctx.scene.toggle_transparency = self.transparency;
        if (self.bg_repr != 0) {
            rl::Color bg;
            bg.r = self.bg_color[0];
            bg.g = self.bg_color[1];
            bg.b = self.bg_color[2];
            bg.a = self.bg_color[3];
            
            ctx.scene.background = bg;
        }
        
        if (self.mic_name != null && self.mic_name != "(null)") {
            foreach (i, n : ctx.microphone.device_names) {
                if (n == self.mic_name) {
                    ctx.microphone.current_device = (int) i;
                    microphone::switch_device(&ctx.microphone,
                        ctx.microphone.devices[i]);
                    break;
                }
            }
        }
        
        if (self.mic_trigger != 0) ctx.microphone.trigger = self.mic_trigger;
        if (self.mic_sensitivity != 0) ctx.microphone.multiplier.store(
            self.mic_sensitivity);
    }
}

fn void Settings.update(&self, Context *ctx)
{
    if (ctx.dirty_settings.scene) {
        self.transparency = ctx.scene.toggle_transparency;
        rl::Color bg = ctx.scene.background;
        
        if (self.transparency) bg = color_from_nk_f(ctx.scene.picker.color);
        
        self.bg_color[0] = bg.r;
        self.bg_color[1] = bg.g;
        self.bg_color[2] = bg.b;
        self.bg_color[3] = bg.a;
    }
    
    if (ctx.dirty_settings.mic) {
        self.mic_name = ctx.microphone.device_names[ctx.microphone
            .current_device];
        self.mic_trigger = ctx.microphone.trigger;
        self.mic_sensitivity = ctx.microphone.multiplier.load();
    }
    
    File cfg = file::open(self.conf_file.str_view(), "w")!!;
    defer (void) cfg.close();
    
    (void) io::fprintfn(&cfg,
`{
    "transparency": %s,
    "bg": %d,
    "mic": "%s",
    "trigger": %d,
    "sensitivity": %d
}`, self.transparency ? "true" : "false", self.bg_repr, self.mic_name,
        self.mic_trigger, self.mic_sensitivity);
}

fn bool? populate_self(Settings *self) @if(env::POSIX) @local => @pool()
{
    String home = env::tget_var("HOME")!;
    if (try String xdg_cfg = env::tget_var("XDG_CONFIG_HOME") && xdg_cfg.len) {
        self.conf_file = path::temp(xdg_cfg)!;
        Path dir = self.conf_file.tappend("OpenPNGStudio")!;
        path::mkdir(dir, true)!;
        self.conf_file = self.conf_file.append(mem, "OpenPNGStudio/"
            "settings.json")!;
    } else {
        self.conf_file = path::temp(home)!;
        Path dir = self.conf_file.tappend(".config/OpenPNGStudio")!;
        path::mkdir(dir, true)!;
        self.conf_file = self.conf_file.append(mem, ".config/OpenPNGStudio/"
            "settings.json")!;
    }
    
    if (try File settings = file::open(self.conf_file.str_view(), "r")) {
        Object *root = json::tparse(&settings)!;
        
        if (try bool t = root.get_bool("transparency")) self.transparency = t;
        if (try uint u = root.get_uint("bg")) self.bg_repr = u;
        if (try String s = root.get_string("mic")) self.mic_name = s
            .zstr_copy(mem);
        if (try usz u = root.get_ulong("trigger")) self.mic_trigger = u;
        if (try int i = root.get_int("sensitivity")) self.mic_sensitivity = i;
        
        return true;
    }
    
    return false;
}
