/* SPDX-License-Identifier: GPL-3.0-or-later */
#include <stdbool.h>
#include <stdlib.h>
#include <unuv.h>
#include <uv.h>
#include <work/work.h>

static void on_work(uv_work_t *w);
static void on_work_done(uv_work_t *w, int s);

struct work *work_new(work_fn perform, work_done when_finished, bool run_on_thread)
{
    struct work *w = calloc(1, sizeof(struct work));
    w->perform = perform;
    w->finished = when_finished;
    w->thread_safe = run_on_thread;
    w->req.data = w;

    return w;
}

void work_set_context(struct work *work, void *context)
{
    work->ctx = context;
}

void work_evaluate(struct work *work, un_loop *loop)
{
    if (work->thread_safe) {
        uv_queue_work((uv_loop_t*) loop, &work->req, on_work, on_work_done);
        return;
    }

    work->perform(work);
    work->finished(work);
}

static void on_work(uv_work_t *w)
{
    struct work *work = w->data;
    work->perform(work);
}

static void on_work_done(uv_work_t *w, int _)
{
    struct work *work = w->data;
    work->finished(work);
}
