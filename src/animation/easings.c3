/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation::easings;
import std::math::easing;

alias EasingFn = fn float(float t, float b, float c, float d);

const CChar*[] NAMES = {
    "Linear",
    "Sine In",
    "Sine Out",
    "Sine InOut",
    "Circular In",
    "Circular Out",
    "Circular InOut",
    "Cubic In",
    "Cubic Out",
    "Cubic InOut",
    "Quadractic In",
    "Quadractic Out",
    "Quadractic InOut",
    "Exponential In",
    "Exponential Out",
    "Exponential InOut",
    "Bounce In",
    "Bounce Out",
    "Bounce InOut",
    "Elastic In",
    "Elastic Out",
    "Elastic InOut",
};

const EasingFn[] EASINGS = {
    &easing::linear_none,
    &easing::sine_in,
    &easing::sine_out,
    &easing::sine_inout,
    &easing::circ_in,
    &easing::circ_out,
    &easing::circ_inout,
    &easing::cubic_in,
    &easing::cubic_out,
    &easing::cubic_inout,
    &easing::quad_in,
    &easing::quad_out,
    &easing::quad_inout,
    &easing::expo_in,
    &easing::expo_out,
    &easing::expo_inout,
    &easing::bounce_in,
    &easing::bounce_out,
    &easing::bounce_inout,
    &easing::elastic_in,
    &easing::elastic_out,
    &easing::elastic_inout,
};

<*
 @require id >= 0 && id < EASINGS.len : "Easing ID is out of range!"
*>
fn float ease(int id, float t, float b, float c, float d) => EASINGS[id](t, b, c, d);
