#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/kprobes.h>
#include <linux/kallsyms.h>
#include <linux/mm_types.h>
#include <linux/sched.h>
#include <linux/types.h> 
#include <linux/pid.h>

#define PID_REDIS   42058

#define NUM_MAX (unsigned long long)18446744073709551610

static struct jprobe jp;
unsigned long long num=0;

/* jprobe init function */ 
static int __handle_mm_fault_son(struct vm_area_struct *vma, unsigned long address,
		unsigned int flags)
{
    struct mm_struct *mm=vma->vm_mm;
    struct task_struct *task = mm->owner; 
//    struct pid *pgrp, *session;
//    
//    pgrp = task_pgrp(task);
//    session = task_pgrp(task);

#ifdef PID_REDIS
    if(task!=NULL && task->pid == PID_REDIS)
	    trace_printk("handle_mm_fault - pid: %10d, vm_start: %20lx, vm_end : %20lx, address : %20lx, cs: %15lx, ce: %15lx  \n", task->pid, vma->vm_start, vma->vm_end, address, mm->start_data, mm->end_data);
#else
//    if(task!=NULL && vma != NULL && pgrp != NULL && session != NULL)
//	    trace_printk("handle_mm_fault - pid: %10d ,pgrp: %10d ,sson: %10d, vm_start: %20lx, vm_end : %20lx, address : %20lx, count : %lld\n", task->pid,pgrp->numbers[0].nr,session->numbers[0].nr, vma->vm_start, vma->vm_end, address, num++); 
    if(task!=NULL && vma != NULL)
	    trace_printk("handle_mm_fault - pid: %10d, vm_start: %20lx, vm_end : %20lx, address : %20lx \n", task->pid, vma->vm_start, vma->vm_end, address);
#endif

	/* need to end with jprobe_return(). */
	jprobe_return();
	return 0;
}

static int __init init_probe_module(void)
{
	int ret;

    /* init jprobe structure */
    jp.kp.symbol_name = "__handle_mm_fault";
    jp.entry = __handle_mm_fault_son;

    /* register jprobe */
	ret = register_jprobe(&jp);
	if (ret < 0) {
		trace_printk(KERN_INFO "register_jprobe failed, returned %d\n", ret);
		return -1;
	}
	trace_printk("%s jprobe registered \n", jp.kp.symbol_name);

	return 0;
}

static void __exit exit_probe_module(void)
{
    /* unregister kprobe */
 	unregister_jprobe(&jp); 
	trace_printk("%s jprobe unregistered \n", jp.kp.symbol_name);
}



module_init(init_probe_module)
module_exit(exit_probe_module)
MODULE_LICENSE("GPL");
