/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::types;

/* Do NOT serialize the types! */

enum Compression : inline char {
    NONE,
    LZF,
    LZ4,
    ZSTD,
    XZ,

    LIMIT, /* used for comparison */
}

enum Kdf : inline char {
    NONE,
    ARGON2ID,

    LIMIT, /* used for comparison */
}

enum Encryption : inline char {
    NONE,
    XCHACHA20_POLY1305,

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
    SQLITE,
    IMAGES,

    COUNT, /* for writer and comparison */
}

struct Dir {
    DirType type;
    usz offset;
    uint nentries;
}

const DIR_SIZE = 13; /* 1 + 8 + 4 */

struct SQLiteDir {
    usz uncompressed_size, size, offset;
}

enum ImageType : inline char {
    STATIC,
    ANIMATED
}

struct ImagesDir {
    ImageType type;
    uint id;
    usz uncompressed_size, size, offset;
}

struct Vec2 {
    float x, y;
}

struct SQLLayer {
    usz nchildren;
    uint data_id;
}

struct SQLLayerData {
    ZString name;
    Vec2 position, scale;
    float rotation;
    uint tint;
    usz timeout;
    uint image_id;
    ulong mask;
    bool toggle;
}

struct SQLAnimation {
    int type;
    ulong mask;
    int easing;
    bool repeat;
    uint layer_id;
    void *data;
    usz data_size;
}
