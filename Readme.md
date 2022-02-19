## A.	基础代码实现

### Exercise2

​		此处需要实现以下六个函数：

#### env_init

​		该函数旨在初始化envs数组，构建env_free_list，添加的代码如下：

![image-20211023175829953](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023175829953.png)

​		此处需要注意env_free_list应该按照envs数组的索引从小到大排列，所以这里要按照envs数组索引从大到小的顺序放到env_free_list中。由于初始状态所有环境均处于非活动（free）状态，所以将所有环境的状态均设为free。

#### env_setup_vm

​		该函数已被实现，作用是为新环境分配页目录并初始化新环境地址空间的内核部分。

#### region_alloc

​		该函数已被实现，作用是为 用户环境分配物理空间。

#### load_icode

​		该函数已被实现，作用是解析一个ELF文件，将其加载到用户地址空间中。

#### env_create

​		该函数旨在创建一个新的用户环境。

![image-20211023175850542](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023175850542.png)

​		此处先声明一个用户环境，然后用env_alloc函数初始化用户环境，然后用load_icode将ELF文件加载到用户环境中，最后设定用户环境的类型。

#### env_run

​		该函数在用户模式下运行指定的用户环境。

![image-20211023175916560](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023175916560.png)

​		首先要先判断现在是否有用户环境正在运行，如果有，将正在运行的用户环境的运行状态设为ENV_RUNNABLE，即就绪等待状态；然后将指定的用户环境设为当前正在运行的用户环境，并将其运行状态设为正在运行ENV_RUNNING；然后将指定的用户环境的运行次数加一，加载线性地址空间；最后将env_tf里保存的寄存器状态弹出到寄存器中，然后就可以开始运行了。

### Exercise4

​		此处需要实现对操作系统中内部异常的处理，这里不需要实现真正的处理，只需要为每一个异常分配好处理函数。

​		首先先在trapentry.S文件中利用宏定义TRAPHANDLER和TRAPHANDLER_NOEC为每个处理函数分配入口，两者的区别是是否往栈中压入错误码。如果发生异常时cpu会往栈中压入错误码，就利用TRAPHANDLER分配入口；如果发生异常时cpu不会往栈中压入错误码，就利用TRAPHANDLER_NOEC分配入口。而该信息可以在[Chapter 9, Exceptions and Interrupts](https://pdos.csail.mit.edu/6.828/2018/readings/i386/c09.htm)查到。

![image-20211023182549689](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023182549689.png)

​		查看TRAPHANDLER和TRAPHANDLER_NOEC的定义可知，不管是什么异常，最后都会执行_alltraps。代码如下：

![image-20211023183220711](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023183220711.png)

​		基本思路其实就是调用trap函数处理异常。首先我们将寄存器压入栈中，保存寄存器的状态。此处将寄存器压入栈时需要按照Trapframe的结构压栈。其实这里的压栈过程就是env_pop_tf函数弹栈的反过程，查看env_pop_tf函数可知，此处需要先将%ds和%es两个寄存器压入栈中，然后将所有的寄存器压入栈中保存起来。然后给%ds和%es两个寄存器赋值，最后pushl %esp 将指向 Trapframe 的指针作为参数传递给 trap函数并调用trap。

​		然后完善trap_init函数：

![image-20211023185746207](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023185746207.png)

​		首先先声明各个处理函数。

![image-20211023185757865](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023185757865.png)

​		然后利用SETGATE宏定义填写中断描述符表。查看SETGATE的定义，需要传递gate, istrap, sel, off, dpl五个参数。其中gate为中断描述符表的索引入口，即idt[***]；istrap判断是interrupt还是trap；sel为处理程序的代码段选择器，进入内核应为GD_KT；off为代码段中的偏移量，即函数地址；dpl为权限，0为内核态，3为用户态（这里需要将下断点和系统调用设为用户环境也可调用）。由此可根据不同异常设定中断描述符表。

### Exercise5

​		这个很简单，就是当出现page fault时利用trap_dispatch函数调度到page_fault_handler函数。

![image-20211023191726558](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023191726558.png)

### Exercise6

​		这个和上一个类似，就是当程序运行到断点时，利用trap_dispatch函数调度到monitor函数。

![image-20211023200154431](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023200154431.png)

### Exercise7

​		此处需要实现系统调用，系统调用处理函数的入口及idt表在Exercise4中已经完成，此处只需要完善trap_dispatch函数和syscall函数。

​		同样，当发生系统调用时利用trap_dispatch函数调度到syscall函数。

![image-20211023202043521](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023202043521.png)

​		此处需要查看syscall函数的定义，传递相对应的参数，而参数和寄存器之间的对应关系在lib\syscall.c中能够找到。

​		然后是syscall函数的实现：

![image-20211023202902632](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023202902632.png)

​		syscallno参数传递系统调用号，针对不同的系统调用号进行不同的处理，如果系统无用，则返回-E_INVAL。

### Exercise8

​		此处需要修改 libmain()函数，让全局指针thisenv指向envs数组中此环境的结构体Env。

![image-20211023204031496](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023204031496.png)

​		此处使用宏定义ENVX和函数sys_getenvid来获取此环境在envs数组里的索引。

### 最终测试结果

![image-20211023204426040](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023204426040.png)

## B.对Exercise4的优化

​		在Exercise4中，我们可以发现在trap_init函数中有许多重复代码，主要就是长度20行的对SETGATE函数的20次调用，参照xv6里trap.c和vector.S两文件，对本实验中的trapentry.S和trap.c两文件进行优化。

​		注意SETGATE这个宏定义：

~~~c
 SETGATE(gate, istrap, sel, off, dpl)
~~~

​		本次实验中gate均为idt[索引]的形式，其中的索引可以组成一个数组idts；istrap非0即1，可以组成一个数组istraps；sel均为GD_KT，不变即可；off为处理函数，可以参照xv6中的形式促成一个数组vectors；dpl非0即3，可以组成一个数组users，由此可以写出对trap_init的优化：

![image-20211023205650971](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023205650971.png)

​		现在我们需要定义这几个数组，在trapentry.S中进行定义。

​		**idts**

![image-20211023205748688](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023205748688.png)

​		**istraps**

![image-20211023205812082](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023205812082.png)

​		**vectors**

![image-20211023205853033](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023205853033.png)

![image-20211023205908872](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023205908872.png)

​		**users**

![image-20211023205922080](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023205922080.png)

​		最终结果：

![image-20211023210129891](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20211023210129891.png)

## C.问题回答

### 1.Exercise中的问题

#### Exercise4.1

​		**What is the purpose of having an individual handler function for each exception/interrupt? (i.e., if all exceptions/interrupts were delivered to the same handler, what feature that exists in the current implementation could not be provided?)**

​		不同的异常有不同的处理方式，比如本次实验中的是否压入错误代码问题，而本次实验只是简单实现，在实际使用的操作系统中，不同的异常的处理方式区别只会更多，如果全部放到同一个函数中，函数的结构势必会很复杂，在设计时容易出错。而且一旦想要更新改善某个异常的处理函数，牵一发而动全身，很有可能需要调整其他异常处理函数的代码，从而使修改的效率降低。而放到不同函数中，修改时只需要修改特定的异常处理函数即可，需要考虑其他处理函数。

#### Exercise4.2

​		**Did you have to do anything to make the user/softint program behave correctly? The grade script expects it to produce a general protection fault (trap 13), but softint's code says int \$14. Why should this produce interrupt vector 13? What happens if the kernel actually allows softint's int $14 instruction to invoke the kernel's page fault handler (which is interrupt vector 14)?**

​		trap13是general protection fault，说明用户程序企图访问不可访问的地址。trap14是page fault，在设置idt表时，我们将page fault对应的dpl参数设为0，则只有内核才有权限调用page fault处理程序。softint里使用了int $14指令，欲调用page fault处理程序，但是softint是在用户态下运行的，没有权限执行此指令，因此会触发trap13。如果我们将idt表中page fault的dpl参数设为0，则能使softint正确运行。

​		如果用户能执行page fault处理程序，那么用户就能在任何时候调用该程序，有可能造成内存泄露、改写、丢失等一系列危险的情况。

#### Exercise6.3

​		**The break point test case will either generate a break point exception or a general protection fault depending on how you initialized the break point entry in the IDT (i.e., your call to SETGATE from trap_init). Why? How do you need to set it up in order to get the breakpoint exception to work as specified above and what incorrect setup would cause it to trigger a general protection fault?**

​		上一个问题已经说过了，dpl参数设为3就能正常运行，设为0就不能。因为设为0时只有内核才有权限设置断点。除此之外，将sel参数设置为GD_KD也会触发general protection fault,因为GD_KD是内核数据段，而此处显然应该选择内核代码段。

#### Exercise6.4

​		**What do you think is the point of these mechanisms, particularly in light of what the `user/softint` test program does?**

​		重点就是不能让用户随便访问、修改内核数据或代码，用户应该只能访问它有权限访问的内容。因为操作系统是不信任用户的，如果放任用户为所欲为，很有可能会产生影响其他用户程序的运行，影响操作系统的稳定行，信息的泄露等危险情况。

### 2.

​		**请详细说出系统是如何实现从用户态到内核态的转换，什么时候切换，以及详细说出此系统的中断处理流程。**

​		从用户态转换到内核态，首先需要将当前寄存器的状态保存起来，然后将cpu即将执行的内核级函数的参数压入栈和相应寄存器，然后调用内核级函数即可；而从内核态转换到用户态，只需要将保存好的原来的寄存器状态弹到寄存器中，然后使用iret指令回到用户态继续执行。在这过程中，操作系统会利用GDT表中的一个表项来判断当前处于内核态还是用户态。

​		当发生中断、异常和系统调用时会从用户态切换到内核态；而当处理中断、异常和系统调用结束后，系统会从内核态恢复到用户态。

​		当系统发生中断后，系统会将中断的相应信息保存起来，然后进入trapentry.S中寻找并进入相应的入口。进入后，系统首先会压入错误码（如果需要的话）和中断编号，然后执行_alltrap，即保存当前寄存器状态并调用trap函数。trap函数会根据中断的不同类型调度不同的处理函数，处理完后恢复到原来的用户状态（如果能够恢复的话，不能恢复会销毁相应的用户环境）。

### 3.

​		**IDT 和GDT 存储的信息分别是什么？系统是如何初始化它们的？**

​		IDT为中断描述符表，里面保存了各类中断的类型、编号、处理函数、处理权限等信息。系统通过SETGATE宏定义在trap_init函数中对其初始化。

​		GDT表为全局描述符表，一个cpu对应一个。其中保存了当前执行的代码段的基地址及偏移、当前执行的状态（用户态还是内核态）等信息。系统在trap_init函数调用trap_init_percpu函数，然后在trap_init_percpu函数中对GDT表进行初始化。

### 4.

​		**_alltraps 的具体作用是什么？它做的事情在后面哪里用到了？**

​		_alltraps的具体作用为将当前寄存器的状态压入栈中保存起来，将%ds、%es寄存器设为GD_KD，然后将寄存器%esp压入栈中作为参数调用trap函数。

​		当发生中断的时候，系统会通过相应中断的入口压入相应信息到栈上后执行_alltraps。而它保存的寄存器信息在中断处理完后执行env_pop_tf函数时重新弹出到寄存器里。

### 5.

​		**用户环境是什么？此实验使用哪种数据结构来存储这些信息？此数据结构具体形式是什么样子的？**

​		用户环境实际上就是一个用户进程，其中保存了该进程的id、运行次数、寄存器、类型、状态等信息。此实验中采用了一个名为Env的struct结构来储存这些信息。

​		此数据结构的具体形式为：

~~~c
struct Env {
	struct Trapframe env_tf;	// Saved registers
	struct Env *env_link;		// Next free Env
	envid_t env_id;			// Unique environment identifier
	envid_t env_parent_id;		// env_id of this env's parent
	enum EnvType env_type;		// Indicates special system environments
	unsigned env_status;		// Status of the environment
	uint32_t env_runs;		// Number of times environment has run

	// Address space
	pde_t *env_pgdir;		// Kernel virtual address of page dir
};
~~~



