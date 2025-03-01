#include <toml.h>
#include <archive.h>
#include <archive_entry.h>
#include <console.h>
#include <model/model.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#define TOML_ERR_LEN 128

enum read_state {
    READER_READ_MANIFEST,
    READER_READ_LAYER_INFO,
    READER_READ_LAYER_IMG,
    READER_READ_DONE,
    READER_READ_FAIL,
};

struct layer_info {
    char *name;
    char *buffer;
    size_t index;
    bool is_animated;

    uint8_t *image_buffer;
    size_t image_size;

    struct layer_info *next;
};

struct model_manifest {
    size_t number_of_layers;
    size_t microphone_trigger;
    int microphone_sensitivity;
    int background_color;
    struct layer_info *layers;
};

struct model_reader {
    struct model *model;
    struct model_manifest manifest;
    struct archive *archive;
    struct archive_entry *entry;
    enum read_state state;

    int fd;
    void *mmaped;
    size_t mmaped_size;
};

static void read_archive(struct work *work);
static void after_read(struct work *work);

static int parse_manifest(struct model_reader *rd);
static int manifest_load_layers(struct model_manifest *manifest, toml_table_t *conf);
static struct layer_info *manifest_find_layer(struct model_manifest *manifest, const char *pathname);

void model_load(struct model *model, const char *path)
{
    struct stat s;
    stat(path, &s);

    int fd = open(path, O_RDONLY);
    void *mmaped = mmap(NULL, s.st_size, PROT_READ, MAP_SHARED, fd, 0);
    if (mmaped == MAP_FAILED) {
        perror("mmap");
        abort();
    }

    LOG_I("Preparing to load %s", path);

    struct model_reader *rd = calloc(1, sizeof(struct model_reader));
    rd->model = model;
    rd->archive = archive_read_new();
    rd->fd = fd;
    rd->mmaped = mmaped;
    rd->mmaped_size = s.st_size;

    archive_read_support_filter_zstd(rd->archive);
    archive_read_support_format_tar(rd->archive);
    archive_read_open_memory(rd->archive, mmaped, s.st_size);
    rd->state = READER_READ_MANIFEST;

    struct work *work = work_new(read_archive, after_read, false);
    work_set_context(work, rd);

    work_scheduler_add_work(model->scheduler, work);
}

static void read_archive(struct work *work)
{
    struct model_reader *rd = work->ctx;
    switch (rd->state) {
    case READER_READ_MANIFEST: {
        if ((archive_read_next_header(rd->archive, &rd->entry)) != ARCHIVE_OK) {
            archive_read_free(rd->archive);
            munmap(rd->mmaped, rd->mmaped_size);
            close(rd->fd);
            rd->state = READER_READ_LAYER_INFO;
            return;
        }

        mode_t type = archive_entry_filetype(rd->entry);
        const char *pathname = archive_entry_pathname(rd->entry);

        if (type == AE_IFREG) {
            if (pathname[0] == 'm' && strcmp(pathname, "manifest.toml") == 0) {
                if (parse_manifest(rd))
                    rd->state = READER_READ_FAIL;
                return;
            } else if (pathname[0] == 'l' && strncmp(pathname, "layers/", 7) == 0) {
                struct layer_info *layer = manifest_find_layer(&rd->manifest,
                    pathname);

                if (layer != NULL) {
                    const char *ext = strrchr(pathname, '.') + 1;
                    size_t data_size = archive_entry_size(rd->entry);
                    if (strcmp(ext, "toml") == 0) {
                        layer->buffer = calloc(data_size, sizeof(char));
                        archive_read_data(rd->archive, layer->buffer, data_size);
                    } else {
                        layer->image_size = data_size;
                        layer->image_buffer = calloc(data_size, sizeof(char));
                        archive_read_data(rd->archive, layer->image_buffer, data_size);
                    }
                } else {
                    LOG_E("Unable to find layer %s! Is it defined in the manifest?",
                        pathname);
                    rd->state = READER_READ_FAIL;
                    return;
                }
            } else
                LOG_W("Stray file in the model - %s???", pathname);
        } else if (type == AE_IFDIR) {
            if (strcmp(pathname, "layers/") != 0)
                LOG_W("Stray directory in mode - %s???", pathname);
        }

        archive_read_data_skip(rd->archive);
        break;
    }
    case READER_READ_LAYER_INFO:
    case READER_READ_LAYER_IMG:
    case READER_READ_DONE:
    case READER_READ_FAIL:
        break;
    }
}

static void after_read(struct work *work)
{
    struct model_reader *rd = work->ctx;
}

static int parse_manifest(struct model_reader *rd)
{
    char errbuf[TOML_ERR_LEN];

    LOG_I("Reading model manifest", 0);
    size_t size = archive_entry_size(rd->entry);
    char *config_str = calloc(size, sizeof(char));
    archive_read_data(rd->archive, config_str, size);

    toml_table_t* conf = toml_parse(config_str, errbuf,
                                    TOML_ERR_LEN);
    if (conf == NULL) {
        LOG_E("Unable to parse manifest file: %s!", errbuf);
        return 1;
    }

    toml_table_t *model = toml_table_in(conf, "model");
    if (model == NULL) {
        LOG_E("Unable to find table [model] in manifest: %s!",
              errbuf);
        return 1;
    }

    toml_datum_t layer_count = toml_int_in(model, "layer_count");
    if (!layer_count.ok) {
        LOG_E("Unable to get layer count: %s!", errbuf);
        return 1;
    }
    rd->manifest.number_of_layers = layer_count.u.i;

    toml_table_t *microphone = toml_table_in(conf, "microphone");
    if (microphone == NULL) {
        LOG_E("Unable to find table [microphone] in manifest: %s!",
              errbuf);
        return 1;
    }

    toml_datum_t trigger = toml_int_in(microphone, "trigger");
    if (!trigger.ok) {
        LOG_E("Unable to get microphone activation trigger: %s!",
              errbuf);
        return 1;
    }
    rd->manifest.microphone_trigger = trigger.u.i;

    toml_datum_t sensitivity = toml_int_in(microphone,
                                           "sensitivity");
    if (!sensitivity.ok) {
        LOG_E("Unable to get microphone sensitivity: %s!", errbuf);
        return 1;
    }
    rd->manifest.microphone_sensitivity = sensitivity.u.i;

    toml_table_t *scene = toml_table_in(conf, "scene");
    if (scene == NULL) {
        LOG_E("Unable to find table [scene] in manifest: %s!",
              errbuf);
        return 1;
    }

    toml_datum_t bg_color = toml_int_in(scene, "bg_color");
    if (!bg_color.ok) {
        LOG_E("Unable to get background color: %s!", errbuf);
        return 1;
    }
    rd->manifest.background_color = bg_color.u.i;

    if (manifest_load_layers(&rd->manifest, conf))
        return 1;

    LOG_I("Parsed model manifest successfully!", 0);

    toml_free(conf);
    free(config_str);
    return 0;
}

static int manifest_load_layers(struct model_manifest *manifest, toml_table_t *conf)
{
    char errbuf[TOML_ERR_LEN];
    struct layer_info *lazy = NULL;

    toml_array_t *array = toml_array_in(conf, "layer");
    if (array == NULL) {
        LOG_E("Unable to find array [[layer]] in manifest: %s!", errbuf);
        return 1;
    }

    for (size_t i = 0; i < manifest->number_of_layers; i++) {
        struct layer_info *table = calloc(1, sizeof(struct layer_info));
        toml_table_t *layer = toml_table_at(array, i);
        if (layer == NULL) {
            LOG_E("Unable to get layer info: %s!", errbuf);
            free(table);
            return 1;
        }

        toml_datum_t name = toml_string_in(layer, "name");
        if (!name.ok) {
            LOG_E("Unable to get layer name: %s!", errbuf);
            free(table);
            return 1;
        }
        table->name = name.u.s;

        toml_datum_t index = toml_int_in(layer, "index");
        if (!index.ok) {
            LOG_E("Unable to get layer index: %s!", errbuf);
            free(table);
            return 1;
        }
        table->index = index.u.i;

        toml_datum_t is_animated = toml_bool_in(layer, "is_animated");
        if (!is_animated.ok) {
            LOG_E("Unable to get if layer is animated: %s!", errbuf);
            free(table);
            return 1;
        }
        table->is_animated = is_animated.u.b;

        if (lazy == NULL) {
            manifest->layers = table;
            lazy = table;
        } else {
            lazy->next = table;
            lazy = table;
        }
    }

    return 0;
}

static struct layer_info *manifest_find_layer(struct model_manifest *manifest, const char *pathname)
{
    const char *start = strrchr(pathname, '-') + 1;
    size_t index = atoll(start);

    struct layer_info *lazy = manifest->layers;
    while (lazy) {
        if (lazy->index == index)
            return lazy;

        lazy = lazy->next;
    }

    return NULL;
}
