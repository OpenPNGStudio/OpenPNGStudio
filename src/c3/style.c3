module openpngstudio::ui::style;
import openpngstudio::ui::icons;
import nk;

fn void apply(nk::Context *ctx) @export("opng_style_apply")
{
    nk::Color[nk::COLOR_COUNT] theme;
    theme[nk::COLOR_TEXT] = nk::rgba(0xFF, 0xFF, 0xFF, 0xFF);
    theme[nk::COLOR_WINDOW] = nk::rgba(0x20, 0x20, 0x20, 0xFF);
    theme[nk::COLOR_HEADER] = nk::rgba(0x19, 0x19, 0x19, 0xFF);
    theme[nk::COLOR_BORDER] = nk::rgba(0xD9, 0xD9, 0xD9, 0xFF);
    theme[nk::COLOR_BUTTON] = nk::rgba(0x38, 0x38, 0x38, 0xFF);
    theme[nk::COLOR_BUTTON_HOVER] = nk::rgba(0x30, 0x30, 0x30, 0xFF);
    theme[nk::COLOR_BUTTON_ACTIVE] = nk::rgba(0x2A, 0x2A, 0x2A, 0xFF);
    theme[nk::COLOR_TOGGLE] = nk::rgba(0x38, 0x38, 0x38, 0xFF);
    theme[nk::COLOR_TOGGLE_HOVER] = nk::rgba(0x30, 0x30, 0x30, 0xFF);
    theme[nk::COLOR_TOGGLE_CURSOR] = nk::rgba(0x19, 0x19, 0x19, 0xFF);
    theme[nk::COLOR_SELECT] = nk::rgba(0x0, 0x0, 0x0, 0x00);
    theme[nk::COLOR_SELECT_ACTIVE] = nk::rgba(0x19, 0x19, 0x19, 0xFF);
    theme[nk::COLOR_SLIDER] = nk::rgba(0x19, 0x19, 0x19, 0xFF);
    theme[nk::COLOR_SLIDER_CURSOR] = nk::rgba(0x70, 0x70, 0x70, 0xFF);
    theme[nk::COLOR_SLIDER_CURSOR_HOVER] = nk::rgba(0x60, 0x60, 0x60, 0xFF);
    theme[nk::COLOR_SLIDER_CURSOR_ACTIVE] = nk::rgba(0x50, 0x50, 0x50, 0xFF);
    theme[nk::COLOR_PROPERTY] = nk::rgba(0x19, 0x19, 0x19, 0xFF);
    theme[nk::COLOR_EDIT] = nk::rgba(0x19, 0x19, 0x19, 0xFF);
    theme[nk::COLOR_EDIT_CURSOR] = nk::rgba(0xD9, 0xD9, 0xD9, 0xFF);
    theme[nk::COLOR_COMBO] = nk::rgba(0x38, 0x38, 0x38, 0xFF);
    theme[nk::COLOR_SCROLLBAR] = nk::rgba(0x19, 0x19, 0x19, 0xFF);
    theme[nk::COLOR_SCROLLBAR_CURSOR] = nk::rgba(0x17, 0xA0, 0x86, 0xFF);
    theme[nk::COLOR_SCROLLBAR_CURSOR_HOVER] = nk::rgba(0x17, 0xA0, 0x86, 0xEE);
    theme[nk::COLOR_SCROLLBAR_CURSOR_ACTIVE] = nk::rgba(0x17, 0xA0, 0x86, 0xDD);

    theme[nk::COLOR_CHART] = nk::rgba(50, 58, 61, 255);
    theme[nk::COLOR_CHART_COLOR] = nk::rgba(48, 83, 111, 255);
    theme[nk::COLOR_CHART_COLOR_HIGHLIGHT] = nk::rgba(255, 0, 0, 255);
    theme[nk::COLOR_TAB_HEADER] = nk::rgba(48, 83, 111, 255);
    theme[nk::COLOR_KNOB] = theme[nk::COLOR_SLIDER];
    theme[nk::COLOR_KNOB_CURSOR] = theme[nk::COLOR_SLIDER_CURSOR];
    theme[nk::COLOR_KNOB_CURSOR_HOVER] = theme[nk::COLOR_SLIDER_CURSOR_HOVER];
    theme[nk::COLOR_KNOB_CURSOR_ACTIVE] = theme[nk::COLOR_SLIDER_CURSOR_ACTIVE];

    theme[nk::COLOR_TOOLTIP] = nk::rgba(0x02, 0x78, 0xFF, 0xFF);

    nk::style_from_table(ctx, &theme);

    nk::StyleButton *btn = &ctx.style.button;
    btn.border = 0.0f;
    btn.rounding = 5.0f;
    btn.padding = nk::vec2(0.25f, 0.25f);

    nk::StyleButton *btn2 = &ctx.style.contextual_button;
    btn2.border = 0.0f;
    btn2.rounding = 5.0f;
    btn2.padding = nk::vec2(0.25f, 0.25f);

    nk::StyleButton *btn3 = &ctx.style.menu_button;
    btn3.border = 0.0f;
    btn3.rounding = 5.0f;
    btn3.padding = nk::vec2(0.25f, 0.25f);

    nk::StyleToggle *chk = &ctx.style.checkbox;
    chk.rounding = 5.0f;

    nk::StyleSelectable *sel = &ctx.style.selectable;
    sel.rounding = 5.0f;

    nk::StyleSlider *sld = &ctx.style.slider;
    sld.rounding = 5.0f;

    nk::StyleProgress *prg = &ctx.style.progress;
    prg.rounding = 5.0f;

    nk::StyleProperty *pro = &ctx.style.property;
    pro.border = 0.0f;
    pro.rounding = 5.0f;

    nk::StyleEdit *edt = &ctx.style.edit;
    edt.border = 0.0f;
    edt.rounding = 5.0f;

    nk::StyleScrollbar *sch = &ctx.style.scrollh;
    sch.rounding = 5.0f;
    sch.rounding_cursor = 5.0f;

    nk::StyleScrollbar *scv = &ctx.style.scrollv;
    scv.rounding = 5.0f;
    scv.rounding_cursor = 5.0f;

    nk::StyleCombo *cmb = &ctx.style.combo;
    cmb.border = 0.0f;
    cmb.rounding = 5.0f;

    nk::StyleWindow *win = &ctx.style.window;
    win.menu_border = 0.0f;
    win.group_border = 0.0f;
    win.tooltip_padding = nk::vec2(5.0f, 5.0f);

    nk::StyleWindowHeader *hdr = &win.header;

    hdr.close_button.normal = {
        .type = nk::STYLE_ITEM_IMAGE,
        .data = {
            .image = icons::get(CANCEL),
        },
    };

    hdr.close_button.hover = hdr.close_button.normal;
    hdr.close_button.active = hdr.close_button.normal;
    hdr.close_button.border = 0.0f;

    // hdr.minimize_button.normal = {
    //     .type = nk::STYLE_ITEM_IMAGE,
    //     .data = {
    //         .image = icons::get(MINIMIZE),
    //     },
    // };
    //
    // hdr.minimize_symbol = nk::SYMBOL_UNDERSCORE;
    // hdr.maximize_symbol = nk::SYMBOL_NONE;
    //
    // hdr.minimize_button.hover = hdr.minimize_button.normal;
    // hdr.minimize_button.active = hdr.minimize_button.normal;

    chk.cursor_normal = {
        .type = nk::STYLE_ITEM_IMAGE,
        .data = {
            .image = icons::get(CHECK),
        },
    };

    chk.cursor_hover = chk.cursor_normal;
}
