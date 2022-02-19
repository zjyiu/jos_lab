# ​<center>LAB6 文件系统实验报告</center>

## Exercise 1

```c++
if(type==ENV_TYPE_FS)
    e->env_tf.tf_eflags |= FL_IOPL_MASK;
```

​&emsp;&emsp;这里只需要判断创建的环境是否是文件系统环境，如果是，赋予环境IO权限即可。

## Exercise 2

### bc_pgfault
```c++
addr = ROUNDDOWN(addr, PGSIZE);
if ((r = sys_page_alloc(0, addr, PTE_W | PTE_U | PTE_P)) < 0)
    panic("in bc_pgfault, sys_page_alloc: %e", r);
if ((r = ide_read(blockno * BLKSECTS, addr, BLKSECTS)) < 0)
    panic("in bc_pgfault, ide_read: %e", r);
```
​&emsp;&emsp;本函数实现了对缺页故障的处理，需要从磁盘中读入数据。这里首先利用`ROUNDDOWN`获取块的起始地址，因为本实验中块大小和块大小和页大小相同，所以可以直接使用`PGSIZE`。然后用`sys_page_alloc`给块分配一个物理页，然后用`ide_read`将数据从磁盘上读到块中。由此成功将磁盘中的内容读到了内存中。

### flush_block
```c++
addr = ROUNDDOWN(addr, PGSIZE);
int r;
if (!va_is_mapped(addr) || !va_is_dirty(addr))
    return;
if ((r = ide_write(blockno * BLKSECTS, addr, BLKSECTS)) < 0)
    panic("flush_block, ide_write: %e", r);
if ((r = sys_page_map(0, addr, 0, addr, uvpt[PGNUM(addr)] & PTE_SYSCALL)) < 0)
    panic("in flush_block, ide_write: %e", r);
```
​&emsp;&emsp;此函数实现将一个块写进磁盘中。需要注意的是如果这个块在内存中没有被映射过或没有被写过，就不写进磁盘中；否则，先利用`ide_write`将数据写到磁盘中，然后利用`sys_page_map`重置块的`PTE_D`位。

## Exercise 3
```c++
uint32_t blockno;
for (blockno = 0; blockno < super->s_nblocks;blockno++)
    if(block_is_free(blockno)){
        bitmap[blockno / 32] &= ~(1 << (blockno % 32));
        flush_block(diskaddr(2));
        return blockno;
    }
return -E_NO_DISK;
```
​&emsp;&emsp;本函数实现磁盘块的分配，具体而言就是利用`bitmap`找到一个空闲的磁盘块，修改`bitmap`中改磁盘块对应的比特位，然后返回该磁盘块的索引。其中`bitmap`是一个int数组，其一个比特表示一个磁盘块是否被使用，free为1，被使用为0。需要注意的是第二个磁盘块存有`bitmap`，在更新完`bitmap`后要利用`flush_block`更新磁盘中的`bitmap`使其保持一致。

## Exercise 4

### file_block_walk
```c++
uint32_t *indirects;
int indirect_block;
if (filebno > NDIRECT + NINDIRECT)//filebno超出限制
    return -E_INVAL;
if (filebno < NDIRECT)//第filebno块是直接块
    *ppdiskbno = &(f->f_direct[filebno]);
else{//第filebno块是间接块
    if(f->f_indirect){//间接块的索引块存在
        //直接找到filebno对应的块保存到ppdiskno中
        indirects = diskaddr(f->f_indirect);
        *ppdiskbno = &(indirects[filebno - NDIRECT]);
    }else{//间接块的索引块不存在
        if(!alloc)//不分配
            return -E_NOT_FOUND;
        if ((indirect_block = alloc_block()) < 0)
            return -E_NO_DISK;//没有剩余的磁盘块
        //将新创建的块作为间接块的索引块
        f->f_indirect = indirect_block;
        //将索引块写到磁盘中
        flush_block(diskaddr(indirect_block));
        //利用新创建的索引块，将filebno对应的块保存到ppdiskno中
        indirects = diskaddr(indirect_block);
        *ppdiskbno = &(indirects[filebno - NDIRECT]);
    }
}
return 0;//成功，返回0
```
​&emsp;&emsp;此函数的作用是找到参数`f`指向的文件结构中的第`filebno`个块所对应的具体是那个磁盘块，将该磁盘块索引保存到`ppdiskno`中。如果第`filebno`块是间接块，但是间接块的索引块并不存在，就要考虑`alloc`参数：`alloc==true`，则为参数`f`指向的文件结构创建一个间接块的索引块，将第`filebno`个块对应的磁盘块索引保存到`ppdiskno`中（显然这时候`ppdiskno`中存放的是0）；`alloc==false`，则不做分配，直接返回。需要注意的是这里只要参数`f`指向的文件结构中的第`filebno`个块还没有分配，函数执行完后`ppdiskno`中存放的就会是0。

### file_get_block
```c++
if (filebno > NDIRECT + NINDIRECT)//filebno超出限制
    return -E_INVAL;
int r;
uint32_t *ppdiskno;
//利用file_block_walk函数找第`filebno`个块所对应的磁盘块
if ((r = file_block_walk(f, filebno, &ppdiskno, true)) < 0)
    return r;
//第`filebno`个块所对应的磁盘块还没有分配
if (*ppdiskno == 0){
    int block;
    //分配磁盘块，失败返回-E_NO_DISK
    if ((block = alloc_block()) < 0)
        return -E_NO_DISK;
    *ppdiskno = block;//将磁盘块保存到文件结构中
    flush_block(diskaddr(block));//将磁盘块写道磁盘中
}
//将指向第`filebno`个块所对应的磁盘块的指针存到blk中
*blk = diskaddr(*ppdiskno);
return 0;
```
​&emsp;&emsp;此函数的作用为将参数`f`指向的文件结构中的第`filebno`个块的虚拟地址保存到`blk`中。

## Exercise 5
```c++
struct OpenFile *o;
int r;
//获取文件信息，存到o中
if ((r = openfile_lookup(envid, req->req_fileid, &o)) < 0)
    return r;
//从文件中读取客户端请求的大小（req->req_n）到ret->ret_buf中。
if ((r = file_read(o->o_file, ret->ret_buf, req->req_n, o->o_fd->fd_offset)) < 0)
    return r;//失败，返回值为负
//成功，更新文件的查询位置，然后返回读取的数据长度
o->o_fd->fd_offset += r;
return r;
```
​&emsp;&emsp;服务端利用此函数处理读请求，核心是利用`file_read`函数。

## Exercise 6

### server_write
```c++
struct OpenFile *o;
int r;
//获取文件信息，存到o中
if ((r = openfile_lookup(envid, req->req_fileid, &o)) < 0)
    return r;
//往文件里写入客户端请求的大小（req->req_n）的req->req_buf中的数据。
if ((r = file_write(o->o_file, req->req_buf, req->req_n, o->o_fd->fd_offset)) < 0)
    return r;//失败，返回值为负
//成功，更新文件的查询位置，然后返回读取的数据长度
o->o_fd->fd_offset += r;
return r;
```
​&emsp;&emsp;服务端利用此函数处理写请求，和Exercise 5类似，核心是利用`file_write`函数。

### devfile_write
```c++
int r;
fsipcbuf.write.req_fileid = fd->fd_file.id;
fsipcbuf.write.req_n = n;
memmove(fsipcbuf.write.req_buf, buf, n);
return fsipc(FSREQ_WRITE, NULL);
```
​&emsp;&emsp;客户端利用此函数向服务端发起写请求。本质起始就是将文件的`id`、需要写的长度`n`和需要写的数据`buf`封装成报文发送。

## Exercise 9
```c++
if (tf->tf_trapno == IRQ_OFFSET + IRQ_KBD){
    kbd_intr();
    return;
}
if (tf->tf_trapno == IRQ_OFFSET + IRQ_SERIAL){
    serial_intr();
    return;
}
```
​&emsp;&emsp;这里只需要在`trap.c`中分别调用`kbd_intr`和`serial_intr`来处理中断`IRQ_KBD`和`IRQ_SERIAL`即可。

## Exercise 10
```c++
if ((fd = open(t, O_RDONLY)) < 0){
    cprintf("open %s for write: %e", t, fd);
    exit();
}
if (fd != 0){
    dup(fd, 0);
    close(fd);
}
```
​&emsp;&emsp;由于当前shell并不支持IO重定向，所以需要在代码中自己实现IO重定向。代码中利用`open`函数将文件打开到文件描述符`fd`，而`fd`不一定为0。如果`fd`不为零，需要利用`dup`函数将`fd`拷贝到标准输入0，然后关闭`fd`，这样标准输入就会从指定的文件中读取内容了。

## 问题1

​&emsp;&emsp;**回答MIT JOS LAB5 的Question 1。**

​&emsp;&emsp;不需要。IO特权设置保存在`tf_eflags`中，而在环境切换时会将`tf_eflags`压入栈帧保存，切换回该环境时回从栈中恢复`tf_eflags`，从中系统就能判断该环境是否有IO特权。

## 问题2

​&emsp;&emsp;**在fs/bc.c的bc_pgfault函数中，为什么要把 block_is_free 的检查放在读入 block 之后？**

​&emsp;&emsp;系统中`bitmap`这个结构存放于第2个磁盘块，如果说读取`bitmap`的时候发生了缺页故障，显然要将`bitmap`读进内存后检查，因为检查块是否是空闲块就是靠`bitmap`实现的。

## 问题3

​&emsp;&emsp;**请详细描述JOS 中文件存储在磁盘中的结构。在读取或写入文件时，superblock，bitmap以及block cache分别在什么时候被使用，它们分别有什么作用？**

​&emsp;&emsp;描述文件系统中文件的元数据的布局由在`inc/fs.h`中的`File`结构体保存：
```c++
struct File {
	char f_name[MAXNAMELEN];	// filename
	off_t f_size;			// file size in bytes
	uint32_t f_type;		// file type
	// Block pointers.
	// A block is allocated iff its value is != 0.
	uint32_t f_direct[NDIRECT];	// direct blocks
	uint32_t f_indirect;		// indirect block
	// Pad out to 256 bytes; must do arithmetic in case we're compiling
	// fsformat on a 64-bit machine.
	uint8_t f_pad[256 - MAXNAMELEN - 8 - 4*NDIRECT - 4];
} __attribute__((packed));	// required only on some 64-bit machines
```
​&emsp;&emsp;其中`f_direct`数组存放直接块，最多有10个，可以存放40KB的数据。而如果文件大小大于40KB，就需要使用到间接块。`f_indirect`指向间接块的索引块。和其他磁盘块一样，索引块的大小为4KB，其中4B存放一个间接块索引，所以最多能有1024个间接块。因此一个文件最多能使用1034个磁盘块。
```c++
struct Super {
	uint32_t s_magic;		// Magic number: FS_MAGIC
	uint32_t s_nblocks;		// Total number of blocks on disk
	struct File s_root;		// Root directory node
};
```
​&emsp;&emsp;`superblock`存放于第1个磁盘块，其中保存了文件系统的magic签名、磁盘上有多少个块及根目录信息。主要用来检查magic签名是否正确和读写的磁盘块号是否超过磁盘中的磁盘块数目。

​&emsp;&emsp;`bitmap`是一个int数组，其中一个比特对应一个磁盘块，表示该磁盘块是空闲块还是已被使用的磁盘块，在分配和释放磁盘块时会对其进行更新，在检查一个磁盘块是否是空闲块时会访问其中相对应的比特。

​&emsp;&emsp;系统将3G大小的磁盘空间映射到范围是0x10000000（DISKMAP）到0xD0000000（DISKMAP+DISKMAX）的虚拟地址空间，这部分内存就是`block cache`。当文件进行读写操作时，会对`block cache`进行读写，如果发生缺页则从磁盘中加载进来（按需加载）。写文件时，会将`block cache`中的数据修改完后存到磁盘中相应的磁盘块中，以保证文件系统的一致性。

## 问题4

​&emsp;&emsp;**请详细描述一个Regular 进程将120KB的数据写入空文件的整个IPC流程。写入后的文件，在磁盘中是如何存储的？120KB的数据总共经历了几次拷贝？**

​&emsp;&emsp;首先通过`lib/file.c`中的库函数`devfile_write`向文件系统发送写请求。文件系统通过`serve_write`处理这个请求，调用下层的`file_write`完成文件写。其中`file_write`是一块一块读入内存，然后完成写操作的。120KB的文件会被分为30个块，其中10个块是直接块；另外20块是间接块。其中每一块都会进行一次拷贝，所以一共是30次拷贝。

## 问题5

​&emsp;&emsp;**请阅读user/sh.c代码，并使用make run-icode或者make run-icode-nox启动QEMU，然后运行命令：cat lorem |num。请尝试解释shell是如何执行这行命令的，请简述启动的进程以及他们的运行流程，详细说明数据在进程间的传递过程。**

​&emsp;&emsp;首先调用`runcmd`函数执行指令，`runcmd`会调用`gettoken`对输入指令的切分，如果出现pipe，会新建一个子进程来处理，然后在`runit`中执行指令。在`runit`中会为没有以`/`开头的命令添加`/`,然后调用`spawn`来启动程序，对于有pipe的情况而言，父进程和子进程都会调用`spawn`。 `spawn`会把从文件系统加载的程序映像生成一个进程。

​&emsp;&emsp;pipe中不同进程的数据共享是通过文件描述符的重定向实现的。以 `cat lorem |num`为例，在出现pipe的情況时，会调用`pipe`函数生成两个文件描述符作为管道的两端，然后在子进程中将一端重定向到标准输入，在父进程中将一端重定向到标准输出，这样父进程`cat lorem`的输出变为子进程`num`的输入，从而完成了数据的共享。