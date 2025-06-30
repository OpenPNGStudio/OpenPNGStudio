module novacrash::options @if(!$feature(CUSTOM_FRONTEND));

import raylib5::rl;

struct Window { 
    ZString title;
    int width, height;
}

struct Theme {
    rl::Color background, foreground, ambient;
    char[] font;
    float spacing, font_size, padding;
}

struct Header {
    ZString[] catch_phrases;
    char[] crash_icon;
    rl::Vector2 icon_size;
    float title_size;
}

struct Options {
    ZString app_name, message;
    Window window;
    Theme theme;
    Header header;
}

module novacrash::options @if($feature(CUSTOM_FRONTEND));

struct Options {
    ZString app_name, message;
}

module novacrash::options;

Options cfg;
