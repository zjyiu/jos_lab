/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



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

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */						\

.text
TRAPHANDLER_NOEC(divide_handler,T_DIVIDE)
TRAPHANDLER_NOEC(debug_handler,T_DEBUG)
TRAPHANDLER_NOEC(nmi_handler,T_NMI)
TRAPHANDLER_NOEC(brkpt_handler,T_BRKPT)
TRAPHANDLER_NOEC(oflow_handler,T_OFLOW)
TRAPHANDLER_NOEC(bound_handler,T_BOUND)
TRAPHANDLER_NOEC(illop_handler,T_ILLOP)
TRAPHANDLER_NOEC(device_handler,T_DEVICE)
TRAPHANDLER(dblflt_handler,T_DBLFLT)
TRAPHANDLER(tss_handler,T_TSS)
TRAPHANDLER(segnp_handler,T_SEGNP)
TRAPHANDLER(stack_handler,T_STACK)
TRAPHANDLER(gpflt_handler,T_GPFLT)
TRAPHANDLER(pgflt_handler,T_PGFLT)
TRAPHANDLER_NOEC(fperr_handler,T_FPERR)
TRAPHANDLER(align_handler,T_ALIGN)
TRAPHANDLER_NOEC(mchk_handler,T_MCHK)
TRAPHANDLER_NOEC(simderr_handler,T_SIMDERR)
TRAPHANDLER_NOEC(syscall_handler,T_SYSCALL)
TRAPHANDLER_NOEC(default_handler,T_DEFAULT)

.globl vector0
vector0:
	pushl $0
	pushl $(T_DIVIDE);
	jmp _alltraps
.globl vector1
vector1:
  pushl $0
  pushl $(T_DEBUG)
  jmp _alltraps
.globl vector2
vector2:
  pushl $0
  pushl $(T_NMI)
  jmp _alltraps
.globl vector3
vector3:
  pushl $0
  pushl $(T_BRKPT)
  jmp _alltraps
.globl vector4
vector4:
  pushl $0
  pushl $(T_OFLOW)
  jmp _alltraps
.globl vector5
vector5:
  pushl $0
  pushl $(T_BOUND)
  jmp _alltraps
.globl vector6
vector6:
  pushl $0
  pushl $(T_ILLOP)
  jmp _alltraps
.globl vector7
vector7:
  pushl $0
  pushl $(T_DEVICE)
  jmp _alltraps
.globl vector8
vector8:
  pushl $(T_DBLFLT)
  jmp _alltraps
.globl vector9
vector9:
  pushl $(T_TSS)
  jmp _alltraps
.globl vector10
vector10:
  pushl $(T_SEGNP)
  jmp _alltraps
.globl vector11
vector11:
  pushl $(T_STACK)
  jmp _alltraps
.globl vector12
vector12:
  pushl $(T_GPFLT)
  jmp _alltraps
.globl vector13
vector13:
  pushl $(T_PGFLT)
  jmp _alltraps
.globl vector14
vector14:
  pushl $0
  pushl $(T_FPERR)
  jmp _alltraps
.globl vector15
vector15:
  pushl $(T_ALIGN)
  jmp _alltraps
.globl vector16
vector16:
  pushl $0
  pushl $(T_MCHK)
  jmp _alltraps
.globl vector17
vector17:
  pushl $0
  pushl $(T_SIMDERR)
  jmp _alltraps
.globl vector18
vector18:
  pushl $0
  pushl $(T_SYSCALL)
  jmp _alltraps
.globl vector19
vector19:
  pushl $0
  pushl $(T_DEFAULT)
  jmp _alltraps

.data
.globl vectors
vectors:
  .long vector0
  .long vector1
  .long vector2
  .long vector3
  .long vector4
  .long vector5
  .long vector6
  .long vector7
  .long vector8
  .long vector9
  .long vector10
  .long vector11
  .long vector12
  .long vector13
  .long vector14
  .long vector15
  .long vector16
  .long vector17
  .long vector18
  .long vector19

.data
.globl idts
idts:
	.long T_DIVIDE
	.long T_DEBUG
	.long T_NMI
	.long T_BRKPT
	.long T_OFLOW
	.long T_BOUND
	.long T_ILLOP
	.long T_DEVICE
	.long T_DBLFLT
	.long T_TSS
	.long T_SEGNP
	.long T_STACK
	.long T_GPFLT
	.long T_PGFLT
	.long T_FPERR
	.long T_ALIGN
	.long T_MCHK
	.long T_SIMDERR
	.long T_SYSCALL
	.long T_DEFAULT

.data
.globl istraps
istraps:
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0

.data
.globl users
users:
	.long 0
	.long 0
	.long 0
	.long 3
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 0
	.long 3
	.long 0
/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
pushl %ds
pushl %es
pushal
pushl $GD_KD
popl %ds
pushl $GD_KD
popl %es
pushl %esp
call trap