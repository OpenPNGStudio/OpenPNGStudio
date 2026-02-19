/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::writer;

import std;
import std::collections::map;
import sqlite3;

import opng::types, opng::stream;

faultdef SQLITE_FAILED;

struct Writer {
    Stream stream;
    SqliteHandle db;
    usz dirs_start;
    usz[DirType.COUNT] offsets;
}

fn void Writer.free(&self)
{
    self.stream.free();
    sqlite3::close(self.db);
}

fn uint? Writer.add_layer_data(&self, SQLLayerData data)
{
    @pool() {
        SqliteStmt stmt;
        String insert = `
INSERT INTO layer_data (name, x, y, scale_x, scale_y, rotation, tint, timeout, image_id, mask, toggle)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
`;
        insert = insert.trim();
        
        SqliteResult res = sqlite3::prepare_v2(self.db, insert.zstr_tcopy(), -1,
            &stmt, null);

        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_text(stmt, 1, data.name, -1, null);
        if (res != OK) return SQLITE_FAILED~;
        
        res = sqlite3::bind_double(stmt, 2, data.position.x);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_double(stmt, 3, data.position.y);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_double(stmt, 4, data.scale.x);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_double(stmt, 5, data.scale.y);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_double(stmt, 6, data.rotation);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int(stmt, 7, data.tint);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int64(stmt, 8, data.timeout);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int(stmt, 9, data.image_id);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int64(stmt, 10, data.mask);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int(stmt, 11, (int) data.toggle);
        if (res != OK) return SQLITE_FAILED~;
        
        res = sqlite3::step(stmt);
        if (res != DONE) return SQLITE_FAILED~;

        res = sqlite3::finalize(stmt);
        if (res != OK) return SQLITE_FAILED~;

        return (uint) sqlite3::last_insert_rowid(self.db);
    };
}

fn void? Writer.add_layer(&self, SQLLayer layer)
{
    @pool() {
        SqliteStmt stmt;
        String insert = `
INSERT INTO layers (nchildren, data_id)
VALUES (?, ?);
`;
        insert = insert.trim();
        
        SqliteResult res = sqlite3::prepare_v2(self.db, insert.zstr_tcopy(), -1,
            &stmt, null);

        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int64(stmt, 1, layer.nchildren);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int(stmt, 2, layer.data_id);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::step(stmt);
        if (res != DONE) return SQLITE_FAILED~;

        res = sqlite3::finalize(stmt);
        if (res != OK) return SQLITE_FAILED~;
    };
}

fn void? Writer.add_animation(&self, SQLAnimation animation)
{
    @pool() {
        SqliteStmt stmt;
        String insert = `
INSERT INTO animations (type, mask, easing, repeat, layer, data)
VALUES (?, ?, ?, ?, ?, ?);
`;
        insert = insert.trim();
        
        SqliteResult res = sqlite3::prepare_v2(self.db, insert.zstr_tcopy(), -1,
            &stmt, null);

        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int(stmt, 1, animation.type);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int64(stmt, 2, animation.mask);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int(stmt, 3, animation.easing);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_int(stmt, 4, (int) animation.repeat);
        if (res != OK) return SQLITE_FAILED~;
        
        res = sqlite3::bind_int(stmt, 5, animation.layer_id);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::bind_blob(stmt, 6, animation.data, 
            (int) animation.data_size, null);
        if (res != OK) return SQLITE_FAILED~;

        res = sqlite3::step(stmt);
        if (res != DONE) return SQLITE_FAILED~;

        res = sqlite3::finalize(stmt);
        if (res != OK) return SQLITE_FAILED~;
    };
}

fn void? find_dir(Writer *self, DirType type) @local
{
    if (self.offsets[type] == 0) {
        usz largest = 0;
        for (int i = 0; i < DirType.COUNT; i++) {
            largest = max(largest, self.offsets[i]);
        }

        if (largest > 0) {
            largest += types::DIR_SIZE;  /* to offset already written dir */
        } else {
            largest = self.dirs_start;
        }

        self.offsets[type] = largest;
    }

    self.stream.offset(true, self.offsets[type])!;
}

module opng;

import std::io::file;
import sqlite3;

struct WriterConfig {
    ushort version;
    Compression compression;
    Kdf kdf;
    Encryption encryption;
}

fn Writer? write_memory(Allocator alloc, WriterConfig cfg)
{
    Writer w;
    w.stream = (MemoryStream*) calloc(MemoryStream.sizeof);

    init_writer(&w, alloc, cfg)!;

    return w;
}

fn Writer? write_file(Allocator alloc, String path, WriterConfig cfg)
{
    Writer w;
    FileStream *s = calloc(FileStream.sizeof);
    s.file = file::open(path, "w")!;
    w.stream = s;

    init_writer(&w, alloc, cfg)!;

    return w;
}

fn void? init_writer(Writer *self, Allocator alloc, WriterConfig cfg) @local
{
    SqliteResult res = sqlite3::open(":memory:", &self.db);
    if (res != OK) return writer::SQLITE_FAILED~;
    populate_database(self)!;
    
    self.stream.write("OPNG")!;
    self.stream.@write(cfg.version)!;
    self.stream.@write(cfg.compression)!;
    self.stream.@write(cfg.kdf)!;
    self.stream.@write(cfg.encryption)!;

    self.dirs_start = self.stream.offset()!;

    char[DirType.COUNT * types::DIR_SIZE] empty;
    self.stream.write(&empty)!;
}


fn void? populate_database(Writer *self) @local
{
    @pool() {
        ZString err;
        String stmt = `
CREATE TABLE layers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nchildren INTEGER,
    data_id INTEGER
);
`;
        stmt = stmt.trim();
        SqliteResult res = sqlite3::exec(self.db, stmt.zstr_tcopy(), null, 
            null, &err);

        if (res != OK) return;

        stmt = `
CREATE TABLE layer_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    x REAL,
    y REAL,
    scale_x REAL,
    scale_y REAL,
    rotation REAL,
    tint INTEGER,
    timeout INTEGER,
    image_id INTEGER,
    mask INTEGER,
    toggle BOOLEAN
);
`;
        stmt = stmt.trim();
        res = sqlite3::exec(self.db, stmt.zstr_tcopy(), null, 
            null, &err);

        if (res != OK) return;

        stmt = `
CREATE TABLE animations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type INTEGER,
    mask INTEGER,
    easing INTEGER,
    repeat BOOLEAN,
    layer INTEGER,
    data BLOB
);
`;

        stmt = stmt.trim();
        res = sqlite3::exec(self.db, stmt.zstr_tcopy(), null, 
            null, &err);

        if (res != OK) return;
    };
}
