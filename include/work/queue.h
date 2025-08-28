/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once

#include <stddef.h>

struct work_queue {
    struct _work_queue_node *head;
    struct _work_queue_node *tail;
    size_t size;
};

struct _work_queue_node {
    struct _work_queue_node *next;
    struct work *data;
};

void work_queue_cleanup(struct work_queue *queue);
int work_queue_enqueue(struct work_queue *queue, struct work *value);
void work_queue_dequeue(struct work_queue *queue);
struct work *work_queue_front(struct work_queue *queue);
struct work *work_queue_back(struct work_queue *queue);
