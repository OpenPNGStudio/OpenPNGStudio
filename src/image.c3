/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::image;

import raylib5::rl;
import std::collections::set;
import ev::work;
import std::thread;

import std::hash::fnv32a;
import std::hash::sha256;
import std::io;
import libc;

struct Image {
    usz ref;
    char[] file_content; /* only used for GIFs */
    char[sha256::HASH_SIZE] checksum;

    /* opaque data */
    rl::Image image;
    rl::Texture2D texture;
}

/* request when loading an image */
struct ImageReq {
    ZString path;
    bool ready;
    Work{ImageReq*} work;

    Image *loaded;
    ZString name;
    bool animated;
}

fn uint Image.hash(Image *self)
{
    if (self == null) return 0;

    return fnv32a::hash(&self.checksum);
}

fn bool Image.equals(Image *self, Image *other)
{
    if (self == null || other == null) return false;

    return libc::memcmp(&self.checksum, &other.checksum, 
        sha256::HASH_SIZE) == 0;
}

fn void Image.free(&self)
{
    if (--self.ref == 0) {
        if (self.file_content.len > 0) free(self.file_content.ptr);

        rl::unloadImage(self.image);
        rl::unloadTexture(self.texture);
    }
}

struct Manager {
    HashSet{Image*} images;
    Mutex mutex;
}

fn void Manager.init(&self, Allocator alloc)
{
    self.images.init(alloc);
    self.mutex.init()!!;
}

fn void Manager.free(&self)
{
    self.images.free();
    self.mutex.destroy()!!;
}

fn Image *Manager.get(&self, Image *img)
{
    self.mutex.lock();
    defer self.mutex.unlock();

    if (try Image *res = self.images[img]) {
        res.ref++;
        return res;
    }

    self.images.add(img);
    img.ref++;
    return img;
}


/* stdlib smh */
module std::collections::set <Value>;

<*
 Check if the set contains the given value.

 @param value : "The value to check"
 @return "true if it exists in the set"
*>
fn Value? HashSet.get(&set, Value value) @operator([])
{
	if (!set.count) return NOT_FOUND~;

	uint hash = rehash(value.hash());
	for (Entry *e = set.table[index_for(hash, set.table.len)]; e != null; e = e.next)
	{
		if (e.hash == hash && equals(value, e.value)) return e.value;
	}

	return NOT_FOUND~;
}
