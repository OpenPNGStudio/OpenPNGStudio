#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

#define STB_RECT_PACK_IMPLEMENTATION
#include <stb_rect_pack.h>

struct size {
    size_t w, h;
};

stbi_uc *load_img(char *path, stbrp_rect *rect)
{
    int channels;
    
    stbi_uc *data = stbi_load(path, &rect->w, &rect->h, &channels,
        STBI_rgb_alpha);
    
    return data;
}

struct size pack(struct size aprox, stbrp_rect *arr, size_t len)
{
    stbrp_rect *tmp = calloc(len, sizeof(*tmp));
    
    size_t bw, bh;
    bw = aprox.w;
    bh = aprox.h;
    
    for (;;) {
        stbrp_context ctx = { 0 };
        stbrp_node *nodes = calloc(bw + bh, sizeof(*nodes));
        
        stbrp_init_target(&ctx, bw, bh, nodes, bw + bh);
        
        memcpy(tmp, arr, len * sizeof(*tmp));
        int packed = stbrp_pack_rects(&ctx, tmp, len);
        free(nodes);
        
        if (packed) break;
        
        if (bw <= bh) bw *= 2;
        else bh *= 2;
    }
    
    memcpy(arr, tmp, len * sizeof(*arr));
    
    return (struct size) { bw, bh };
}
