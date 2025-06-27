#include <assert.h>
#include <model/model.h>

struct c3_serialize_layer {
    char *name;
    int index;
    bool is_animated;
};

struct c3_model {
    uint64_t layer_count;
    size_t microphone_trigger;
    int sensitivity;
    int color;
    struct c3_serialize_layer *layers;
};

extern char *model_serialize_manifest(struct c3_model model);

char *model_generate_manifest(struct model *model)
{
    int sensitivity = atomic_load(&model->editor->mic->multiplier);
    int color = 0;
    color |= model->editor->background_color.r << 16;
    color |= model->editor->background_color.g << 8;
    color |= model->editor->background_color.b;

    struct c3_serialize_layer layers[model->editor->layer_manager.layer_count];
    for (int i = 0; i < model->editor->layer_manager.layer_count; i++) {
        struct layer *layer = model->editor->layer_manager.layers[i];
        layers[i].name = layer->properties.name.buffer;
        layers[i].index = i + 1;
        layers[i].is_animated = layer->properties.is_animated;
    }

    return model_serialize_manifest((struct c3_model) {
            .layer_count = model->editor->layer_manager.layer_count,
            .microphone_trigger = model->editor->microphone_trigger,
            .sensitivity = sensitivity,
            .color = color,
            .layers = layers,
        });
}
