module oxy_reporter::report @if($feature(OXY_REPORTER_STANDALONE));

import oxy_reporter;

fn GuiState draw()
{
    return REPORT_SCREEN;
}