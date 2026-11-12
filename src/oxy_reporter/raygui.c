#include <raylib.h>

#define RAYGUI_IMPLEMENTATION
#include <raygui.h>

void init_style(Font font)
{
    GuiSetFont(font);

    GuiSetStyle(DEFAULT, TEXT_SIZE, 18);
    GuiSetStyle(DEFAULT, TEXT_SPACING, 1);

    GuiSetStyle(TEXTBOX, BASE_COLOR_PRESSED, 0);
    GuiSetStyle(TEXTBOX, BORDER_WIDTH, 0);
    GuiSetStyle(TEXTBOX, BORDER_COLOR_PRESSED, (int) 0xFFFFFFFF);
    GuiSetStyle(TEXTBOX, BORDER_COLOR_PRESSED, (int) 0xFFFFFFFF);
    GuiSetStyle(TEXTBOX, TEXT_COLOR_NORMAL, (int) 0xFFFFFFFF);
    GuiSetStyle(TEXTBOX, TEXT_COLOR_FOCUSED, (int) 0xFFFFFFFF);
    GuiSetStyle(TEXTBOX, TEXT_COLOR_PRESSED, (int) 0xFFFFFFFF);
}