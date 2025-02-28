#include <work/scheduler.h>
#include <work/queue.h>
#include <work/work.h>

void work_scheduler_add_work(struct work_scheduler *sched, struct work *work)
{
    work_queue_enqueue(&sched->queue, work);
}

void work_scheduler_run(struct work_scheduler *sched)
{
    size_t count = sched->queue.size;

    while (count--) {
        struct work *w = NULL;
        if ((w = work_queue_front(&sched->queue)) !=  NULL)
            work_evaluate(w, sched->loop);

        work_queue_dequeue(&sched->queue);
    }
}
