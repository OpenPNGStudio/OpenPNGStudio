/* NAME */
/* TYPE */
dnl
define(`NODE_NAME', `_'NAME`_node')dnl
define(`_', NAME`_'$1)dnl

#pragma once

#include <stddef.h>

struct NAME {
    struct NODE_NAME *head;
    struct NODE_NAME *tail;
    size_t size;
};

struct NODE_NAME {
    struct NODE_NAME *next;
    TYPE data;
};

void _(cleanup)(struct NAME *queue);
int _(enqueue)(struct NAME *queue, TYPE value);
void _(dequeue)(struct NAME *queue);
TYPE _(front)(struct NAME *queue);
TYPE _(back)(struct NAME *queue);



#include <stdlib.h>
#include <stdbool.h>

static void _(node_deinit)(struct NODE_NAME *node, bool remove_all);

void _(deinit)(struct NAME *queue)
{
    _(node_deinit)(queue->head, true);
}

int _(enqueue)(struct NAME *queue, TYPE value)
{
    struct NODE_NAME *node = calloc(1, sizeof(struct NODE_NAME));
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

void _(dequeue)(struct NAME *queue)
{
    struct NODE_NAME *node = queue->head;
    queue->head = node->next;

    if (queue->head == NULL)
        queue->tail = NULL;

    _(node_deinit)(node, false);
    queue->size--;
}

TYPE _(front)(struct NAME *queue)
{
    if (queue->head == NULL)
        return NULL;

    return &queue->head->data;
}

TYPE _(back)(struct NAME *queue)
{
    if (queue->tail == NULL)
        return NULL;

    return &queue->tail->data;
}

static void _(node_deinit)(struct NODE_NAME *node, bool remove_all)
{
    if (remove_all && node->next)
        _(node_deinit)(node->next, remove_all);

    free(node);
}
