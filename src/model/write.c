/* SPDX-License-Identifier: GPL-3.0-or-later */
#include "console.h"
#include <model/model.h>
#include <archive_entry.h>
#include <stdbool.h>
#include <archive.h>
#include <stdlib.h>
#include <string.h>
#include <work/work.h>
#include <layer/layer.h>

enum write_state {
    WRITER_WRITE_MANIFEST,
    WRITER_WRITE_LAYER_INFO,
    WRITER_WRITE_LAYER_IMG,
    WRITER_WRITE_DONE,
};

struct model_writer {
    struct model *model;
    struct archive *archive;
    struct archive_entry *entry;
    enum write_state state;
    int layer_index;
};

static void write_archive(struct work *work);
static void after_write(struct work *work);
static void write_string_to_archive(struct model_writer *writer, const char *pathname, char *str);
static void write_buffer_to_archive(struct model_writer *writer, const char *pathname, uint8_t *buffer, int size);
static void add_directory_to_archive(struct model_writer *writer, const char *dirname);

void model_write(struct model *model, const char *path)
{
    struct model_writer *wr = calloc(1, sizeof(struct model_writer));
    wr->archive = archive_write_new();
    wr->model = model;

    LOG_I("Preparing to write %s", path);

    archive_write_add_filter_zstd(wr->archive);
    archive_write_set_format_pax_restricted(wr->archive);
    archive_write_open_filename(wr->archive, path);
    wr->state = WRITER_WRITE_MANIFEST;

    struct work *work = work_new(write_archive, after_write, false);
    work_set_context(work, wr);

    work_scheduler_add_work(model->scheduler, work);
}

static void write_archive(struct work *work)
{
    struct model_writer *wr = work->ctx;
    switch (wr->state) {
    case WRITER_WRITE_MANIFEST:
        LOG_I("Writing Manifest", 0);
        write_string_to_archive(wr, "manifest.toml",
            model_generate_manifest(wr->model));
        add_directory_to_archive(wr, "layers");
        break;
    case WRITER_WRITE_LAYER_INFO: {
        if (wr->layer_index == wr->model->editor->layer_manager.layer_count) {
            wr->state = WRITER_WRITE_DONE;
            break;
        }
        LOG_I("Writing layer %s",
            wr->model->editor->layer_manager.layers[wr->layer_index]
            ->properties.name.buffer);
        struct layer *layer = wr->model->editor->layer_manager.layers[wr->layer_index];
        int pathname_len = snprintf(NULL, 0, "layers/%s-%d.toml",
            layer->properties.name.buffer, wr->layer_index + 1);

        char pathname[pathname_len + 1];
        memset(pathname, 0, pathname_len + 1);
        snprintf(pathname, pathname_len + 1, "layers/%s-%d.toml",
            layer->properties.name.buffer, wr->layer_index + 1);

        write_string_to_archive(wr, pathname, layer_stringify(layer));
        break;
    }
    case WRITER_WRITE_LAYER_IMG: {
        LOG_I("Wrinting Layer Image", 0);
        struct layer *layer = wr->model->editor->layer_manager.layers[wr->layer_index];
        struct animated_layer *animated_layer = NULL;

        if (layer->properties.is_animated) {
            animated_layer = layer_get_animated(layer);
            int length = snprintf(NULL, 0, "layers/%s-%d.gif",
                layer->properties.name.buffer, wr->layer_index + 1);
            char pathname[length + 1];
            memset(pathname, 0, length + 1);
            snprintf(pathname, length + 1, "layers/%s-%d.gif", layer->properties.name.buffer,
                wr->layer_index + 1);
            write_buffer_to_archive(wr, pathname, animated_layer->properties.gif_file_content,
                animated_layer->properties.gif_file_size);
        } else {
            int length = snprintf(NULL, 0, "layers/%s-%d.png",
                layer->properties.name.buffer, wr->layer_index + 1);
            char pathname[length + 1];
            memset(pathname, 0, length + 1);
            snprintf(pathname, length + 1, "layers/%s-%d.png", layer->properties.name.buffer,
                wr->layer_index + 1);

            int filesize = 0;
            uint8_t *exported = ExportImageToMemory(layer->properties.image, ".png", &filesize);
            write_buffer_to_archive(wr, pathname, exported, filesize);
            free(exported);
        }
        break;
    }
    case WRITER_WRITE_DONE:
        break;
    }
    /* TODO: Implement script saving */
}

static void after_write(struct work *work)
{
    struct model_writer *wr = work->ctx;
    switch (wr->state) {
    case WRITER_WRITE_MANIFEST:
        wr->state = WRITER_WRITE_LAYER_INFO;
        break;
    case WRITER_WRITE_LAYER_INFO:
        wr->state = WRITER_WRITE_LAYER_IMG;
        break;
    case WRITER_WRITE_LAYER_IMG:
        wr->layer_index++;
        wr->state = WRITER_WRITE_LAYER_INFO;
        break;
    case WRITER_WRITE_DONE:
        archive_write_close(wr->archive);
        archive_write_free(wr->archive);
        LOG_I("Model has been saved!", 0);
        free(wr);
        return;
    }

    /* re-schedule */
    work_scheduler_add_work(wr->model->scheduler, work);
}

static void write_string_to_archive(struct model_writer *writer, const char *pathname, char *str)
{
    int length = strlen(str);
    write_buffer_to_archive(writer, pathname, (uint8_t*) str, length + 1);
    free(str);
}

static void write_buffer_to_archive(struct model_writer *writer, const char *pathname, uint8_t *buffer, int size)
{
    writer->entry = archive_entry_new();
    archive_entry_set_pathname(writer->entry, pathname);
    archive_entry_set_size(writer->entry, size);
    archive_entry_set_filetype(writer->entry, AE_IFREG);
    archive_entry_set_perm(writer->entry, 0644);
    archive_write_header(writer->archive, writer->entry);
    archive_write_data(writer->archive, buffer, size);
    archive_entry_free(writer->entry);
}

static void add_directory_to_archive(struct model_writer *writer, const char *dirname)
{
    writer->entry = archive_entry_new();
    archive_entry_set_pathname(writer->entry, dirname);
    archive_entry_set_filetype(writer->entry, AE_IFDIR);
    archive_entry_set_perm(writer->entry, 0755);
    archive_write_header(writer->archive, writer->entry);
    archive_entry_free(writer->entry);
}
