/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::types;

/* Do NOT serialize the types! */

enum Compression : inline char {
    NONE,
    LZF,

    LIMIT, /* used for comparison */
}

enum Kdf : inline char {
    NONE,
    ARGON2ID,

    LIMIT, /* used for comparison */
}

enum Encryption : inline char {
    NONE,
    CHACHA20_POLY1305,

    LIMIT, /* used for comparison */
}

struct Header {
    char[4] magic;
    ushort version;
    Compression compression_method;
    Kdf password_encryption_method;
    Encryption encryption_method;
}

enum DirType : inline char {
    CONFIGURATION,
    LAYER_INFO,
    IMAGES,
    ANIMATIONS,

    COUNT, /* for writer and comparison */
}

struct Dir {
    DirType type;
    usz offset;
    uint nentries;
}

const DIR_SIZE = 13; /* 1 + 8 + 4 */

struct Configuration {
    usz microphone_trigger;
    uint microphone_sensitivity;
    uint background_color; /* RGBA */
}

struct LayerInfo {
    int x, y;
    float rotation;
    uint timeout;
    bool toggle_mode;
    ulong mask;
    uint image_id, animation_id;
}

enum ImageType : inline char {
    STATIC,
    ANIMATED,

    LIMIT, /* used for comparison */
}

struct Image {
    ImageType type;
    uint id;
    usz uncompressed_size, size;
    usz offset;
}

enum AnimationType : inline char {
    SPINNER,
    SHAKE,
    FADE,

    LIMIT, /* used for comparison */
}

struct Animation {
    AnimationType type;
    uint id;
    char easing;
    ulong mask;
    uint data_size;
}

struct IdPair {
    uint image_id, animation_id;
}
