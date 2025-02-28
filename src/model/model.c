#include <assert.h>
#include <archive_entry.h>
#include <stdbool.h>
#include <model/model.h>
#include <archive.h>
#include <stdlib.h>
#include <string.h>
#include <work/work.h>

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

char *model_generate_manifest(struct model *model)
{
    assert(0 && "Not implemented yet!");
}

void model_write(struct model *model, const char *path)
{
    struct model_writer *wr = calloc(1, sizeof(struct model_writer));
    wr->archive = archive_write_new();
    wr->model = model;

    archive_write_add_filter_zstd(wr->archive);
    archive_write_set_format_pax_restricted(wr->archive);
    archive_write_open_filename(wr->archive, path);
    wr->state = WRITER_WRITE_MANIFEST;

    struct work *work = work_new(write_archive, after_write, false);
    work_set_context(work, wr);

    work_scheduler_add_work(&model->ctx->sched, work);
}



static void write_archive(struct work *work)
{
    struct model_writer *wr = work->ctx;
    switch (wr->state) {
    case WRITER_WRITE_MANIFEST:
        write_string_to_archive(wr, "manifest.toml",
            model_generate_manifest(wr->model));
        add_directory_to_archive(wr, "layers");
        wr->state = WRITER_WRITE_LAYER_INFO;
        break;
    case WRITER_WRITE_LAYER_INFO: {
        if (wr->layer_index == wr->model->editor->layer_manager.layer_count) {
            wr->state = WRITER_WRITE_DONE;
            break;
        }
        struct layer *layer = wr->model->editor->layer_manager.layers[wr->layer_index];
        int pathname_len = snprintf(NULL, 0, "layers/%s-%d.toml",
            layer->properties.name.buffer, wr->layer_index + 1);

        char pathname[pathname_len + 1];
        memset(pathname, 0, pathname_len + 1);
        snprintf(pathname, pathname_len + 1, "layers/%s-%d.toml",
            layer->properties.name.buffer, wr->layer_index + 1);

        write_string_to_archive(wr, pathname, layer_stringify(layer));
        wr->state = WRITER_WRITE_LAYER_IMG;
        break;
    }
    case WRITER_WRITE_LAYER_IMG: {
        wr->layer_index++;
        wr->state = WRITER_WRITE_LAYER_INFO;
        break;
    }
    case WRITER_WRITE_DONE:
        break;
    }
}

static void after_write(struct work *work)
{

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
