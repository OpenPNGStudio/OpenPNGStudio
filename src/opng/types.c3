/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::types;

/* Do NOT serialize the types! */

enum Compression : inline char {
    NONE,
    LZF,
}

enum Kdf : inline char {
    NONE,
    ARGON2ID,
}

enum Encryption : inline char {
    NONE,
    CHACHA20_POLY1305
}

struct Header {
    char[4] magic;
    ushort version;
    Compression compression_method;
    Kdf password_encryption_method;
    Encryption encryption;
}

enum DirType : inline char {
    CONFIGURATION,
    LAYER_INFO,
    IMAGES,
    ANIMATIONS,

    COUNT,
}

struct Dir {
    DirType type;
    usz offset;
    uint nentries;
}

struct Configuration {
    usz microphone_trigger;
    uint microphone_sensitivity;
    uint background_color; /* RGBA */
}

struct LayerInfo {
    int x, y;
    uint timeout;
    bool toggle_mode;
    ulong mask;
    uint image_id, animation_id;
}

enum ImageType : char {
    STATIC,
    ANIMATED,
}

struct Images {
    ImageType type;
    uint id;
    usz uncompressed_size, size;
    usz offset;
}

enum AnimationType : char {
    SPINNER,
    SHAKE,
    FADE,
}

struct Animations {
    AnimationType type;
    uint id;
    char easing;
    ulong mask;
    uint data_size;
}


struct IdPair {
    uint image_id, animation_id;
}
