#pragma once

#include <stddef.h>

typedef void* c3typeid_t;
typedef void* c3fault_t;
typedef struct { void* ptr; size_t len; } c3slice_t;
typedef struct { void* ptr; c3typeid_t type; } c3any_t;

typedef c3slice_t c3_string;
