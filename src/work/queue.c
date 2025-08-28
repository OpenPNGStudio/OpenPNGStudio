/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <work/queue.h>
#include <stdlib.h>
#include <stdbool.h>

static void work_queue_node_deinit(struct _work_queue_node *node, bool remove_all);

void work_queue_deinit(struct work_queue *queue)
{
    work_queue_node_deinit(queue->head, true);
}

int work_queue_enqueue(struct work_queue *queue, struct work *value)
{
    struct _work_queue_node *node = calloc(1, sizeof(struct _work_queue_node));
    if (node == NULL)
        return 1;

    node->data = value;

    if (queue->tail == NULL)
        queue->head = node;
    else
        queue->tail->next = node;

    queue->tail = node;
    queue->size++;

    return 0;
}

void work_queue_dequeue(struct work_queue *queue)
{
    struct _work_queue_node *node = queue->head;
    queue->head = node->next;

    if (queue->head == NULL)
        queue->tail = NULL;

    work_queue_node_deinit(node, false);
    queue->size--;
}

struct work *work_queue_front(struct work_queue *queue)
{
    if (queue->head == NULL)
        return NULL;

    return queue->head->data;
}

struct work *work_queue_back(struct work_queue *queue)
{
    if (queue->tail == NULL)
        return NULL;

    return queue->tail->data;
}

static void work_queue_node_deinit(struct _work_queue_node *node, bool remove_all)
{
    if (remove_all && node->next)
        work_queue_node_deinit(node->next, remove_all);

    free(node);
}
