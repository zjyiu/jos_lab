/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */


	TRAPHANDLER_NOEC(th_divide, T_DIVIDE)
	TRAPHANDLER_NOEC(th_debug, T_DEBUG)
	TRAPHANDLER_NOEC(th_nmi, T_NMI)
	TRAPHANDLER_NOEC(th_brkpt, T_BRKPT)
	TRAPHANDLER_NOEC(th_oflow, T_OFLOW)
	TRAPHANDLER_NOEC(th_bound, T_BOUND)
	TRAPHANDLER_NOEC(th_illop, T_ILLOP)
	TRAPHANDLER_NOEC(th_device, T_DEVICE)
	TRAPHANDLER(th_dblflt, T_DBLFLT)
	TRAPHANDLER_NOEC(th9, 9)
	TRAPHANDLER(th_tss, T_TSS)
	TRAPHANDLER(th_segnp, T_SEGNP)
	TRAPHANDLER(th_stack, T_STACK)
	TRAPHANDLER(th_gpflt, T_GPFLT)
	TRAPHANDLER(th_pgflt, T_PGFLT)
	TRAPHANDLER_NOEC(th_fperr, T_FPERR)

	TRAPHANDLER_NOEC(th32, IRQ_OFFSET)
	TRAPHANDLER_NOEC(th33, IRQ_OFFSET + 1)
	TRAPHANDLER_NOEC(th34, IRQ_OFFSET + 2)
	TRAPHANDLER_NOEC(th35, IRQ_OFFSET + 3)
	TRAPHANDLER_NOEC(th36, IRQ_OFFSET + 4)
	TRAPHANDLER_NOEC(th37, IRQ_OFFSET + 5)
	TRAPHANDLER_NOEC(th38, IRQ_OFFSET + 6)
	TRAPHANDLER_NOEC(th39, IRQ_OFFSET + 7)
	TRAPHANDLER_NOEC(th40, IRQ_OFFSET + 8)
	TRAPHANDLER_NOEC(th41, IRQ_OFFSET + 9)
	TRAPHANDLER_NOEC(th42, IRQ_OFFSET + 10)
	TRAPHANDLER_NOEC(th43, IRQ_OFFSET + 11)
	TRAPHANDLER_NOEC(th44, IRQ_OFFSET + 12)
	TRAPHANDLER_NOEC(th45, IRQ_OFFSET + 13)
	TRAPHANDLER_NOEC(th46, IRQ_OFFSET + 14)
	TRAPHANDLER_NOEC(th47, IRQ_OFFSET + 15)

	TRAPHANDLER_NOEC(th_syscall, T_SYSCALL)

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
    pushl %ds
    pushl %es
    pushal
    movw $GD_KD, %ax
    movw %ax, %ds
    movw %ax, %es
    pushl %esp
    call trap
