
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	000a6517          	auipc	a0,0xa6
ffffffffc020004e:	1f650513          	addi	a0,a0,502 # ffffffffc02a6240 <buf>
ffffffffc0200052:	000aa617          	auipc	a2,0xaa
ffffffffc0200056:	69260613          	addi	a2,a2,1682 # ffffffffc02aa6e4 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	730050ef          	jal	ra,ffffffffc0205792 <memset>
    dtb_init();
ffffffffc0200066:	598000ef          	jal	ra,ffffffffc02005fe <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	522000ef          	jal	ra,ffffffffc020058c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	75258593          	addi	a1,a1,1874 # ffffffffc02057c0 <etext+0x4>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	76a50513          	addi	a0,a0,1898 # ffffffffc02057e0 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	19a000ef          	jal	ra,ffffffffc020021c <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6e4020ef          	jal	ra,ffffffffc020276a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	131000ef          	jal	ra,ffffffffc02009ba <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	12f000ef          	jal	ra,ffffffffc02009bc <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	18f030ef          	jal	ra,ffffffffc0203a20 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	64f040ef          	jal	ra,ffffffffc0204ee4 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	4a0000ef          	jal	ra,ffffffffc020053a <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	111000ef          	jal	ra,ffffffffc02009ae <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7db040ef          	jal	ra,ffffffffc020507c <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00005517          	auipc	a0,0x5
ffffffffc02000c0:	72c50513          	addi	a0,a0,1836 # ffffffffc02057e8 <etext+0x2c>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	000a6b97          	auipc	s7,0xa6
ffffffffc02000d6:	16eb8b93          	addi	s7,s7,366 # ffffffffc02a6240 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	12e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	11e000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	10c000ef          	jal	ra,ffffffffc020020c <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	000a6517          	auipc	a0,0xa6
ffffffffc0200132:	11250513          	addi	a0,a0,274 # ffffffffc02a6240 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	42c000ef          	jal	ra,ffffffffc020058e <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	1e6050ef          	jal	ra,ffffffffc020536e <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	1b0050ef          	jal	ra,ffffffffc020536e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a6d1                	j	ffffffffc020058e <cons_putc>

ffffffffc02001cc <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001cc:	1101                	addi	sp,sp,-32
ffffffffc02001ce:	e822                	sd	s0,16(sp)
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e426                	sd	s1,8(sp)
ffffffffc02001d4:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d6:	00054503          	lbu	a0,0(a0)
ffffffffc02001da:	c51d                	beqz	a0,ffffffffc0200208 <cputs+0x3c>
ffffffffc02001dc:	0405                	addi	s0,s0,1
ffffffffc02001de:	4485                	li	s1,1
ffffffffc02001e0:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001e2:	3ac000ef          	jal	ra,ffffffffc020058e <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e6:	00044503          	lbu	a0,0(s0)
ffffffffc02001ea:	008487bb          	addw	a5,s1,s0
ffffffffc02001ee:	0405                	addi	s0,s0,1
ffffffffc02001f0:	f96d                	bnez	a0,ffffffffc02001e2 <cputs+0x16>
    (*cnt)++;
ffffffffc02001f2:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f6:	4529                	li	a0,10
ffffffffc02001f8:	396000ef          	jal	ra,ffffffffc020058e <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fc:	60e2                	ld	ra,24(sp)
ffffffffc02001fe:	8522                	mv	a0,s0
ffffffffc0200200:	6442                	ld	s0,16(sp)
ffffffffc0200202:	64a2                	ld	s1,8(sp)
ffffffffc0200204:	6105                	addi	sp,sp,32
ffffffffc0200206:	8082                	ret
    while ((c = *str++) != '\0')
ffffffffc0200208:	4405                	li	s0,1
ffffffffc020020a:	b7f5                	j	ffffffffc02001f6 <cputs+0x2a>

ffffffffc020020c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020020c:	1141                	addi	sp,sp,-16
ffffffffc020020e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200210:	3b2000ef          	jal	ra,ffffffffc02005c2 <cons_getc>
ffffffffc0200214:	dd75                	beqz	a0,ffffffffc0200210 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200216:	60a2                	ld	ra,8(sp)
ffffffffc0200218:	0141                	addi	sp,sp,16
ffffffffc020021a:	8082                	ret

ffffffffc020021c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc020021c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020021e:	00005517          	auipc	a0,0x5
ffffffffc0200222:	5d250513          	addi	a0,a0,1490 # ffffffffc02057f0 <etext+0x34>
{
ffffffffc0200226:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	f6dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020022c:	00000597          	auipc	a1,0x0
ffffffffc0200230:	e1e58593          	addi	a1,a1,-482 # ffffffffc020004a <kern_init>
ffffffffc0200234:	00005517          	auipc	a0,0x5
ffffffffc0200238:	5dc50513          	addi	a0,a0,1500 # ffffffffc0205810 <etext+0x54>
ffffffffc020023c:	f59ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200240:	00005597          	auipc	a1,0x5
ffffffffc0200244:	57c58593          	addi	a1,a1,1404 # ffffffffc02057bc <etext>
ffffffffc0200248:	00005517          	auipc	a0,0x5
ffffffffc020024c:	5e850513          	addi	a0,a0,1512 # ffffffffc0205830 <etext+0x74>
ffffffffc0200250:	f45ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200254:	000a6597          	auipc	a1,0xa6
ffffffffc0200258:	fec58593          	addi	a1,a1,-20 # ffffffffc02a6240 <buf>
ffffffffc020025c:	00005517          	auipc	a0,0x5
ffffffffc0200260:	5f450513          	addi	a0,a0,1524 # ffffffffc0205850 <etext+0x94>
ffffffffc0200264:	f31ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200268:	000aa597          	auipc	a1,0xaa
ffffffffc020026c:	47c58593          	addi	a1,a1,1148 # ffffffffc02aa6e4 <end>
ffffffffc0200270:	00005517          	auipc	a0,0x5
ffffffffc0200274:	60050513          	addi	a0,a0,1536 # ffffffffc0205870 <etext+0xb4>
ffffffffc0200278:	f1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020027c:	000ab597          	auipc	a1,0xab
ffffffffc0200280:	86758593          	addi	a1,a1,-1945 # ffffffffc02aaae3 <end+0x3ff>
ffffffffc0200284:	00000797          	auipc	a5,0x0
ffffffffc0200288:	dc678793          	addi	a5,a5,-570 # ffffffffc020004a <kern_init>
ffffffffc020028c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200294:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200296:	3ff5f593          	andi	a1,a1,1023
ffffffffc020029a:	95be                	add	a1,a1,a5
ffffffffc020029c:	85a9                	srai	a1,a1,0xa
ffffffffc020029e:	00005517          	auipc	a0,0x5
ffffffffc02002a2:	5f250513          	addi	a0,a0,1522 # ffffffffc0205890 <etext+0xd4>
}
ffffffffc02002a6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a8:	b5f5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002aa <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002aa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002ac:	00005617          	auipc	a2,0x5
ffffffffc02002b0:	61460613          	addi	a2,a2,1556 # ffffffffc02058c0 <etext+0x104>
ffffffffc02002b4:	04f00593          	li	a1,79
ffffffffc02002b8:	00005517          	auipc	a0,0x5
ffffffffc02002bc:	62050513          	addi	a0,a0,1568 # ffffffffc02058d8 <etext+0x11c>
{
ffffffffc02002c0:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002c2:	1cc000ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02002c6 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002c6:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c8:	00005617          	auipc	a2,0x5
ffffffffc02002cc:	62860613          	addi	a2,a2,1576 # ffffffffc02058f0 <etext+0x134>
ffffffffc02002d0:	00005597          	auipc	a1,0x5
ffffffffc02002d4:	64058593          	addi	a1,a1,1600 # ffffffffc0205910 <etext+0x154>
ffffffffc02002d8:	00005517          	auipc	a0,0x5
ffffffffc02002dc:	64050513          	addi	a0,a0,1600 # ffffffffc0205918 <etext+0x15c>
{
ffffffffc02002e0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e2:	eb3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002e6:	00005617          	auipc	a2,0x5
ffffffffc02002ea:	64260613          	addi	a2,a2,1602 # ffffffffc0205928 <etext+0x16c>
ffffffffc02002ee:	00005597          	auipc	a1,0x5
ffffffffc02002f2:	66258593          	addi	a1,a1,1634 # ffffffffc0205950 <etext+0x194>
ffffffffc02002f6:	00005517          	auipc	a0,0x5
ffffffffc02002fa:	62250513          	addi	a0,a0,1570 # ffffffffc0205918 <etext+0x15c>
ffffffffc02002fe:	e97ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200302:	00005617          	auipc	a2,0x5
ffffffffc0200306:	65e60613          	addi	a2,a2,1630 # ffffffffc0205960 <etext+0x1a4>
ffffffffc020030a:	00005597          	auipc	a1,0x5
ffffffffc020030e:	67658593          	addi	a1,a1,1654 # ffffffffc0205980 <etext+0x1c4>
ffffffffc0200312:	00005517          	auipc	a0,0x5
ffffffffc0200316:	60650513          	addi	a0,a0,1542 # ffffffffc0205918 <etext+0x15c>
ffffffffc020031a:	e7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc020031e:	60a2                	ld	ra,8(sp)
ffffffffc0200320:	4501                	li	a0,0
ffffffffc0200322:	0141                	addi	sp,sp,16
ffffffffc0200324:	8082                	ret

ffffffffc0200326 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200326:	1141                	addi	sp,sp,-16
ffffffffc0200328:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020032a:	ef3ff0ef          	jal	ra,ffffffffc020021c <print_kerninfo>
    return 0;
}
ffffffffc020032e:	60a2                	ld	ra,8(sp)
ffffffffc0200330:	4501                	li	a0,0
ffffffffc0200332:	0141                	addi	sp,sp,16
ffffffffc0200334:	8082                	ret

ffffffffc0200336 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200336:	1141                	addi	sp,sp,-16
ffffffffc0200338:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020033a:	f71ff0ef          	jal	ra,ffffffffc02002aa <print_stackframe>
    return 0;
}
ffffffffc020033e:	60a2                	ld	ra,8(sp)
ffffffffc0200340:	4501                	li	a0,0
ffffffffc0200342:	0141                	addi	sp,sp,16
ffffffffc0200344:	8082                	ret

ffffffffc0200346 <kmonitor>:
{
ffffffffc0200346:	7115                	addi	sp,sp,-224
ffffffffc0200348:	ed5e                	sd	s7,152(sp)
ffffffffc020034a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020034c:	00005517          	auipc	a0,0x5
ffffffffc0200350:	64450513          	addi	a0,a0,1604 # ffffffffc0205990 <etext+0x1d4>
{
ffffffffc0200354:	ed86                	sd	ra,216(sp)
ffffffffc0200356:	e9a2                	sd	s0,208(sp)
ffffffffc0200358:	e5a6                	sd	s1,200(sp)
ffffffffc020035a:	e1ca                	sd	s2,192(sp)
ffffffffc020035c:	fd4e                	sd	s3,184(sp)
ffffffffc020035e:	f952                	sd	s4,176(sp)
ffffffffc0200360:	f556                	sd	s5,168(sp)
ffffffffc0200362:	f15a                	sd	s6,160(sp)
ffffffffc0200364:	e962                	sd	s8,144(sp)
ffffffffc0200366:	e566                	sd	s9,136(sp)
ffffffffc0200368:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020036a:	e2bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036e:	00005517          	auipc	a0,0x5
ffffffffc0200372:	64a50513          	addi	a0,a0,1610 # ffffffffc02059b8 <etext+0x1fc>
ffffffffc0200376:	e1fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc020037a:	000b8563          	beqz	s7,ffffffffc0200384 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037e:	855e                	mv	a0,s7
ffffffffc0200380:	025000ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
ffffffffc0200384:	00005c17          	auipc	s8,0x5
ffffffffc0200388:	6a4c0c13          	addi	s8,s8,1700 # ffffffffc0205a28 <commands>
        if ((buf = readline("K> ")) != NULL)
ffffffffc020038c:	00005917          	auipc	s2,0x5
ffffffffc0200390:	65490913          	addi	s2,s2,1620 # ffffffffc02059e0 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200394:	00005497          	auipc	s1,0x5
ffffffffc0200398:	65448493          	addi	s1,s1,1620 # ffffffffc02059e8 <etext+0x22c>
        if (argc == MAXARGS - 1)
ffffffffc020039c:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039e:	00005b17          	auipc	s6,0x5
ffffffffc02003a2:	652b0b13          	addi	s6,s6,1618 # ffffffffc02059f0 <etext+0x234>
        argv[argc++] = buf;
ffffffffc02003a6:	00005a17          	auipc	s4,0x5
ffffffffc02003aa:	56aa0a13          	addi	s4,s4,1386 # ffffffffc0205910 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003ae:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL)
ffffffffc02003b0:	854a                	mv	a0,s2
ffffffffc02003b2:	cf5ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc02003b6:	842a                	mv	s0,a0
ffffffffc02003b8:	dd65                	beqz	a0,ffffffffc02003b0 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ba:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003be:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003c0:	e1bd                	bnez	a1,ffffffffc0200426 <kmonitor+0xe0>
    if (argc == 0)
ffffffffc02003c2:	fe0c87e3          	beqz	s9,ffffffffc02003b0 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003c6:	6582                	ld	a1,0(sp)
ffffffffc02003c8:	00005d17          	auipc	s10,0x5
ffffffffc02003cc:	660d0d13          	addi	s10,s10,1632 # ffffffffc0205a28 <commands>
        argv[argc++] = buf;
ffffffffc02003d0:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003d2:	4401                	li	s0,0
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003d6:	362050ef          	jal	ra,ffffffffc0205738 <strcmp>
ffffffffc02003da:	c919                	beqz	a0,ffffffffc02003f0 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003dc:	2405                	addiw	s0,s0,1
ffffffffc02003de:	0b540063          	beq	s0,s5,ffffffffc020047e <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003e2:	000d3503          	ld	a0,0(s10)
ffffffffc02003e6:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc02003ea:	34e050ef          	jal	ra,ffffffffc0205738 <strcmp>
ffffffffc02003ee:	f57d                	bnez	a0,ffffffffc02003dc <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003f0:	00141793          	slli	a5,s0,0x1
ffffffffc02003f4:	97a2                	add	a5,a5,s0
ffffffffc02003f6:	078e                	slli	a5,a5,0x3
ffffffffc02003f8:	97e2                	add	a5,a5,s8
ffffffffc02003fa:	6b9c                	ld	a5,16(a5)
ffffffffc02003fc:	865e                	mv	a2,s7
ffffffffc02003fe:	002c                	addi	a1,sp,8
ffffffffc0200400:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200404:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200406:	fa0555e3          	bgez	a0,ffffffffc02003b0 <kmonitor+0x6a>
}
ffffffffc020040a:	60ee                	ld	ra,216(sp)
ffffffffc020040c:	644e                	ld	s0,208(sp)
ffffffffc020040e:	64ae                	ld	s1,200(sp)
ffffffffc0200410:	690e                	ld	s2,192(sp)
ffffffffc0200412:	79ea                	ld	s3,184(sp)
ffffffffc0200414:	7a4a                	ld	s4,176(sp)
ffffffffc0200416:	7aaa                	ld	s5,168(sp)
ffffffffc0200418:	7b0a                	ld	s6,160(sp)
ffffffffc020041a:	6bea                	ld	s7,152(sp)
ffffffffc020041c:	6c4a                	ld	s8,144(sp)
ffffffffc020041e:	6caa                	ld	s9,136(sp)
ffffffffc0200420:	6d0a                	ld	s10,128(sp)
ffffffffc0200422:	612d                	addi	sp,sp,224
ffffffffc0200424:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200426:	8526                	mv	a0,s1
ffffffffc0200428:	354050ef          	jal	ra,ffffffffc020577c <strchr>
ffffffffc020042c:	c901                	beqz	a0,ffffffffc020043c <kmonitor+0xf6>
ffffffffc020042e:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc0200432:	00040023          	sb	zero,0(s0)
ffffffffc0200436:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200438:	d5c9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc020043a:	b7f5                	j	ffffffffc0200426 <kmonitor+0xe0>
        if (*buf == '\0')
ffffffffc020043c:	00044783          	lbu	a5,0(s0)
ffffffffc0200440:	d3c9                	beqz	a5,ffffffffc02003c2 <kmonitor+0x7c>
        if (argc == MAXARGS - 1)
ffffffffc0200442:	033c8963          	beq	s9,s3,ffffffffc0200474 <kmonitor+0x12e>
        argv[argc++] = buf;
ffffffffc0200446:	003c9793          	slli	a5,s9,0x3
ffffffffc020044a:	0118                	addi	a4,sp,128
ffffffffc020044c:	97ba                	add	a5,a5,a4
ffffffffc020044e:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200452:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc0200456:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200458:	e591                	bnez	a1,ffffffffc0200464 <kmonitor+0x11e>
ffffffffc020045a:	b7b5                	j	ffffffffc02003c6 <kmonitor+0x80>
ffffffffc020045c:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc0200460:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc0200462:	d1a5                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200464:	8526                	mv	a0,s1
ffffffffc0200466:	316050ef          	jal	ra,ffffffffc020577c <strchr>
ffffffffc020046a:	d96d                	beqz	a0,ffffffffc020045c <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020046c:	00044583          	lbu	a1,0(s0)
ffffffffc0200470:	d9a9                	beqz	a1,ffffffffc02003c2 <kmonitor+0x7c>
ffffffffc0200472:	bf55                	j	ffffffffc0200426 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200474:	45c1                	li	a1,16
ffffffffc0200476:	855a                	mv	a0,s6
ffffffffc0200478:	d1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc020047c:	b7e9                	j	ffffffffc0200446 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020047e:	6582                	ld	a1,0(sp)
ffffffffc0200480:	00005517          	auipc	a0,0x5
ffffffffc0200484:	59050513          	addi	a0,a0,1424 # ffffffffc0205a10 <etext+0x254>
ffffffffc0200488:	d0dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc020048c:	b715                	j	ffffffffc02003b0 <kmonitor+0x6a>

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc020048e:	000aa317          	auipc	t1,0xaa
ffffffffc0200492:	1da30313          	addi	t1,t1,474 # ffffffffc02aa668 <is_panic>
ffffffffc0200496:	00033e03          	ld	t3,0(t1)
{
ffffffffc020049a:	715d                	addi	sp,sp,-80
ffffffffc020049c:	ec06                	sd	ra,24(sp)
ffffffffc020049e:	e822                	sd	s0,16(sp)
ffffffffc02004a0:	f436                	sd	a3,40(sp)
ffffffffc02004a2:	f83a                	sd	a4,48(sp)
ffffffffc02004a4:	fc3e                	sd	a5,56(sp)
ffffffffc02004a6:	e0c2                	sd	a6,64(sp)
ffffffffc02004a8:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc02004aa:	020e1a63          	bnez	t3,ffffffffc02004de <__panic+0x50>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004ae:	4785                	li	a5,1
ffffffffc02004b0:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	8432                	mv	s0,a2
ffffffffc02004b6:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b8:	862e                	mv	a2,a1
ffffffffc02004ba:	85aa                	mv	a1,a0
ffffffffc02004bc:	00005517          	auipc	a0,0x5
ffffffffc02004c0:	5b450513          	addi	a0,a0,1460 # ffffffffc0205a70 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	ccfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	ca7ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	67e50513          	addi	a0,a0,1662 # ffffffffc0206b50 <default_pmm_manager+0x578>
ffffffffc02004da:	cbbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004de:	4501                	li	a0,0
ffffffffc02004e0:	4581                	li	a1,0
ffffffffc02004e2:	4601                	li	a2,0
ffffffffc02004e4:	48a1                	li	a7,8
ffffffffc02004e6:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ea:	4ca000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004ee:	4501                	li	a0,0
ffffffffc02004f0:	e57ff0ef          	jal	ra,ffffffffc0200346 <kmonitor>
    while (1)
ffffffffc02004f4:	bfed                	j	ffffffffc02004ee <__panic+0x60>

ffffffffc02004f6 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004f6:	715d                	addi	sp,sp,-80
ffffffffc02004f8:	832e                	mv	t1,a1
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fc:	85aa                	mv	a1,a0
{
ffffffffc02004fe:	8432                	mv	s0,a2
ffffffffc0200500:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc0200504:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	00005517          	auipc	a0,0x5
ffffffffc020050a:	58a50513          	addi	a0,a0,1418 # ffffffffc0205a90 <commands+0x68>
{
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	e0c2                	sd	a6,64(sp)
ffffffffc0200516:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200518:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051a:	c7bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020051e:	65a2                	ld	a1,8(sp)
ffffffffc0200520:	8522                	mv	a0,s0
ffffffffc0200522:	c53ff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc0200526:	00006517          	auipc	a0,0x6
ffffffffc020052a:	62a50513          	addi	a0,a0,1578 # ffffffffc0206b50 <default_pmm_manager+0x578>
ffffffffc020052e:	c67ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc0200532:	60e2                	ld	ra,24(sp)
ffffffffc0200534:	6442                	ld	s0,16(sp)
ffffffffc0200536:	6161                	addi	sp,sp,80
ffffffffc0200538:	8082                	ret

ffffffffc020053a <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020053a:	67e1                	lui	a5,0x18
ffffffffc020053c:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd588>
ffffffffc0200540:	000aa717          	auipc	a4,0xaa
ffffffffc0200544:	12f73c23          	sd	a5,312(a4) # ffffffffc02aa678 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200548:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020054c:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020054e:	953e                	add	a0,a0,a5
ffffffffc0200550:	4601                	li	a2,0
ffffffffc0200552:	4881                	li	a7,0
ffffffffc0200554:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200558:	02000793          	li	a5,32
ffffffffc020055c:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200560:	00005517          	auipc	a0,0x5
ffffffffc0200564:	55050513          	addi	a0,a0,1360 # ffffffffc0205ab0 <commands+0x88>
    ticks = 0;
ffffffffc0200568:	000aa797          	auipc	a5,0xaa
ffffffffc020056c:	1007b423          	sd	zero,264(a5) # ffffffffc02aa670 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200570:	b115                	j	ffffffffc0200194 <cprintf>

ffffffffc0200572 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200572:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200576:	000aa797          	auipc	a5,0xaa
ffffffffc020057a:	1027b783          	ld	a5,258(a5) # ffffffffc02aa678 <timebase>
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4581                	li	a1,0
ffffffffc0200582:	4601                	li	a2,0
ffffffffc0200584:	4881                	li	a7,0
ffffffffc0200586:	00000073          	ecall
ffffffffc020058a:	8082                	ret

ffffffffc020058c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020058c:	8082                	ret

ffffffffc020058e <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020058e:	100027f3          	csrr	a5,sstatus
ffffffffc0200592:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200594:	0ff57513          	zext.b	a0,a0
ffffffffc0200598:	e799                	bnez	a5,ffffffffc02005a6 <cons_putc+0x18>
ffffffffc020059a:	4581                	li	a1,0
ffffffffc020059c:	4601                	li	a2,0
ffffffffc020059e:	4885                	li	a7,1
ffffffffc02005a0:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc02005a4:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a6:	1101                	addi	sp,sp,-32
ffffffffc02005a8:	ec06                	sd	ra,24(sp)
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ac:	408000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005b0:	6522                	ld	a0,8(sp)
ffffffffc02005b2:	4581                	li	a1,0
ffffffffc02005b4:	4601                	li	a2,0
ffffffffc02005b6:	4885                	li	a7,1
ffffffffc02005b8:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005bc:	60e2                	ld	ra,24(sp)
ffffffffc02005be:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005c0:	a6fd                	j	ffffffffc02009ae <intr_enable>

ffffffffc02005c2 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005c2:	100027f3          	csrr	a5,sstatus
ffffffffc02005c6:	8b89                	andi	a5,a5,2
ffffffffc02005c8:	eb89                	bnez	a5,ffffffffc02005da <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005ca:	4501                	li	a0,0
ffffffffc02005cc:	4581                	li	a1,0
ffffffffc02005ce:	4601                	li	a2,0
ffffffffc02005d0:	4889                	li	a7,2
ffffffffc02005d2:	00000073          	ecall
ffffffffc02005d6:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d8:	8082                	ret
int cons_getc(void) {
ffffffffc02005da:	1101                	addi	sp,sp,-32
ffffffffc02005dc:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005de:	3d6000ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02005e2:	4501                	li	a0,0
ffffffffc02005e4:	4581                	li	a1,0
ffffffffc02005e6:	4601                	li	a2,0
ffffffffc02005e8:	4889                	li	a7,2
ffffffffc02005ea:	00000073          	ecall
ffffffffc02005ee:	2501                	sext.w	a0,a0
ffffffffc02005f0:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f2:	3bc000ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc02005f6:	60e2                	ld	ra,24(sp)
ffffffffc02005f8:	6522                	ld	a0,8(sp)
ffffffffc02005fa:	6105                	addi	sp,sp,32
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005fe:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200600:	00005517          	auipc	a0,0x5
ffffffffc0200604:	4d050513          	addi	a0,a0,1232 # ffffffffc0205ad0 <commands+0xa8>
void dtb_init(void) {
ffffffffc0200608:	fc86                	sd	ra,120(sp)
ffffffffc020060a:	f8a2                	sd	s0,112(sp)
ffffffffc020060c:	e8d2                	sd	s4,80(sp)
ffffffffc020060e:	f4a6                	sd	s1,104(sp)
ffffffffc0200610:	f0ca                	sd	s2,96(sp)
ffffffffc0200612:	ecce                	sd	s3,88(sp)
ffffffffc0200614:	e4d6                	sd	s5,72(sp)
ffffffffc0200616:	e0da                	sd	s6,64(sp)
ffffffffc0200618:	fc5e                	sd	s7,56(sp)
ffffffffc020061a:	f862                	sd	s8,48(sp)
ffffffffc020061c:	f466                	sd	s9,40(sp)
ffffffffc020061e:	f06a                	sd	s10,32(sp)
ffffffffc0200620:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200622:	b73ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200626:	0000b597          	auipc	a1,0xb
ffffffffc020062a:	9da5b583          	ld	a1,-1574(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	4b250513          	addi	a0,a0,1202 # ffffffffc0205ae0 <commands+0xb8>
ffffffffc0200636:	b5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020063a:	0000b417          	auipc	s0,0xb
ffffffffc020063e:	9ce40413          	addi	s0,s0,-1586 # ffffffffc020b008 <boot_dtb>
ffffffffc0200642:	600c                	ld	a1,0(s0)
ffffffffc0200644:	00005517          	auipc	a0,0x5
ffffffffc0200648:	4ac50513          	addi	a0,a0,1196 # ffffffffc0205af0 <commands+0xc8>
ffffffffc020064c:	b49ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200650:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200654:	00005517          	auipc	a0,0x5
ffffffffc0200658:	4b450513          	addi	a0,a0,1204 # ffffffffc0205b08 <commands+0xe0>
    if (boot_dtb == 0) {
ffffffffc020065c:	120a0463          	beqz	s4,ffffffffc0200784 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200660:	57f5                	li	a5,-3
ffffffffc0200662:	07fa                	slli	a5,a5,0x1e
ffffffffc0200664:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200668:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066a:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020066e:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200670:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200674:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067c:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200680:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200686:	8ec9                	or	a3,a3,a0
ffffffffc0200688:	0087979b          	slliw	a5,a5,0x8
ffffffffc020068c:	1b7d                	addi	s6,s6,-1
ffffffffc020068e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200692:	8dd5                	or	a1,a1,a3
ffffffffc0200694:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200696:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020069c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe35809>
ffffffffc02006a0:	10f59163          	bne	a1,a5,ffffffffc02007a2 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02006a4:	471c                	lw	a5,8(a4)
ffffffffc02006a6:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02006a8:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006ae:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02006b2:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ce:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d2:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d4:	01146433          	or	s0,s0,a7
ffffffffc02006d8:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006dc:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006e0:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e2:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e6:	8c49                	or	s0,s0,a0
ffffffffc02006e8:	0166f6b3          	and	a3,a3,s6
ffffffffc02006ec:	00ca6a33          	or	s4,s4,a2
ffffffffc02006f0:	0167f7b3          	and	a5,a5,s6
ffffffffc02006f4:	8c55                	or	s0,s0,a3
ffffffffc02006f6:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fa:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02006fc:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02006fe:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200700:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200704:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200706:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200708:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020070c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070e:	00005917          	auipc	s2,0x5
ffffffffc0200712:	44a90913          	addi	s2,s2,1098 # ffffffffc0205b58 <commands+0x130>
ffffffffc0200716:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200718:	4d91                	li	s11,4
ffffffffc020071a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020071c:	00005497          	auipc	s1,0x5
ffffffffc0200720:	43448493          	addi	s1,s1,1076 # ffffffffc0205b50 <commands+0x128>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200724:	000a2703          	lw	a4,0(s4)
ffffffffc0200728:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072c:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200730:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200734:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200738:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073c:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200740:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200742:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200746:	0087171b          	slliw	a4,a4,0x8
ffffffffc020074a:	8fd5                	or	a5,a5,a3
ffffffffc020074c:	00eb7733          	and	a4,s6,a4
ffffffffc0200750:	8fd9                	or	a5,a5,a4
ffffffffc0200752:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200754:	09778c63          	beq	a5,s7,ffffffffc02007ec <dtb_init+0x1ee>
ffffffffc0200758:	00fbea63          	bltu	s7,a5,ffffffffc020076c <dtb_init+0x16e>
ffffffffc020075c:	07a78663          	beq	a5,s10,ffffffffc02007c8 <dtb_init+0x1ca>
ffffffffc0200760:	4709                	li	a4,2
ffffffffc0200762:	00e79763          	bne	a5,a4,ffffffffc0200770 <dtb_init+0x172>
ffffffffc0200766:	4c81                	li	s9,0
ffffffffc0200768:	8a56                	mv	s4,s5
ffffffffc020076a:	bf6d                	j	ffffffffc0200724 <dtb_init+0x126>
ffffffffc020076c:	ffb78ee3          	beq	a5,s11,ffffffffc0200768 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200770:	00005517          	auipc	a0,0x5
ffffffffc0200774:	46050513          	addi	a0,a0,1120 # ffffffffc0205bd0 <commands+0x1a8>
ffffffffc0200778:	a1dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020077c:	00005517          	auipc	a0,0x5
ffffffffc0200780:	48c50513          	addi	a0,a0,1164 # ffffffffc0205c08 <commands+0x1e0>
}
ffffffffc0200784:	7446                	ld	s0,112(sp)
ffffffffc0200786:	70e6                	ld	ra,120(sp)
ffffffffc0200788:	74a6                	ld	s1,104(sp)
ffffffffc020078a:	7906                	ld	s2,96(sp)
ffffffffc020078c:	69e6                	ld	s3,88(sp)
ffffffffc020078e:	6a46                	ld	s4,80(sp)
ffffffffc0200790:	6aa6                	ld	s5,72(sp)
ffffffffc0200792:	6b06                	ld	s6,64(sp)
ffffffffc0200794:	7be2                	ld	s7,56(sp)
ffffffffc0200796:	7c42                	ld	s8,48(sp)
ffffffffc0200798:	7ca2                	ld	s9,40(sp)
ffffffffc020079a:	7d02                	ld	s10,32(sp)
ffffffffc020079c:	6de2                	ld	s11,24(sp)
ffffffffc020079e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02007a0:	bad5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc02007a2:	7446                	ld	s0,112(sp)
ffffffffc02007a4:	70e6                	ld	ra,120(sp)
ffffffffc02007a6:	74a6                	ld	s1,104(sp)
ffffffffc02007a8:	7906                	ld	s2,96(sp)
ffffffffc02007aa:	69e6                	ld	s3,88(sp)
ffffffffc02007ac:	6a46                	ld	s4,80(sp)
ffffffffc02007ae:	6aa6                	ld	s5,72(sp)
ffffffffc02007b0:	6b06                	ld	s6,64(sp)
ffffffffc02007b2:	7be2                	ld	s7,56(sp)
ffffffffc02007b4:	7c42                	ld	s8,48(sp)
ffffffffc02007b6:	7ca2                	ld	s9,40(sp)
ffffffffc02007b8:	7d02                	ld	s10,32(sp)
ffffffffc02007ba:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	36c50513          	addi	a0,a0,876 # ffffffffc0205b28 <commands+0x100>
}
ffffffffc02007c4:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02007c6:	b2f9                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc02007c8:	8556                	mv	a0,s5
ffffffffc02007ca:	727040ef          	jal	ra,ffffffffc02056f0 <strlen>
ffffffffc02007ce:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d0:	4619                	li	a2,6
ffffffffc02007d2:	85a6                	mv	a1,s1
ffffffffc02007d4:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02007d6:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02007d8:	77f040ef          	jal	ra,ffffffffc0205756 <strncmp>
ffffffffc02007dc:	e111                	bnez	a0,ffffffffc02007e0 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc02007de:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02007e0:	0a91                	addi	s5,s5,4
ffffffffc02007e2:	9ad2                	add	s5,s5,s4
ffffffffc02007e4:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007e8:	8a56                	mv	s4,s5
ffffffffc02007ea:	bf2d                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007ec:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007f0:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007f4:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02007f8:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200800:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200804:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200808:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200810:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200814:	00eaeab3          	or	s5,s5,a4
ffffffffc0200818:	00fb77b3          	and	a5,s6,a5
ffffffffc020081c:	00faeab3          	or	s5,s5,a5
ffffffffc0200820:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200822:	000c9c63          	bnez	s9,ffffffffc020083a <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200826:	1a82                	slli	s5,s5,0x20
ffffffffc0200828:	00368793          	addi	a5,a3,3
ffffffffc020082c:	020ada93          	srli	s5,s5,0x20
ffffffffc0200830:	9abe                	add	s5,s5,a5
ffffffffc0200832:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200836:	8a56                	mv	s4,s5
ffffffffc0200838:	b5f5                	j	ffffffffc0200724 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020083a:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020083e:	85ca                	mv	a1,s2
ffffffffc0200840:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0187971b          	slliw	a4,a5,0x18
ffffffffc020084e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200852:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200856:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200858:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200860:	8d59                	or	a0,a0,a4
ffffffffc0200862:	00fb77b3          	and	a5,s6,a5
ffffffffc0200866:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200868:	1502                	slli	a0,a0,0x20
ffffffffc020086a:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020086c:	9522                	add	a0,a0,s0
ffffffffc020086e:	6cb040ef          	jal	ra,ffffffffc0205738 <strcmp>
ffffffffc0200872:	66a2                	ld	a3,8(sp)
ffffffffc0200874:	f94d                	bnez	a0,ffffffffc0200826 <dtb_init+0x228>
ffffffffc0200876:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200826 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020087a:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020087e:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200882:	00005517          	auipc	a0,0x5
ffffffffc0200886:	2de50513          	addi	a0,a0,734 # ffffffffc0205b60 <commands+0x138>
           fdt32_to_cpu(x >> 32);
ffffffffc020088a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020088e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200892:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020089a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	0187d693          	srli	a3,a5,0x18
ffffffffc02008aa:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02008ae:	0087579b          	srliw	a5,a4,0x8
ffffffffc02008b2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008b6:	0106561b          	srliw	a2,a2,0x10
ffffffffc02008ba:	010f6f33          	or	t5,t5,a6
ffffffffc02008be:	0187529b          	srliw	t0,a4,0x18
ffffffffc02008c2:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008c6:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008ca:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ce:	0186f6b3          	and	a3,a3,s8
ffffffffc02008d2:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02008d6:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008da:	0107581b          	srliw	a6,a4,0x10
ffffffffc02008de:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008e2:	8361                	srli	a4,a4,0x18
ffffffffc02008e4:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008e8:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02008ec:	01e6e6b3          	or	a3,a3,t5
ffffffffc02008f0:	00cb7633          	and	a2,s6,a2
ffffffffc02008f4:	0088181b          	slliw	a6,a6,0x8
ffffffffc02008f8:	0085959b          	slliw	a1,a1,0x8
ffffffffc02008fc:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200900:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200904:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200908:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020090c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200910:	011b78b3          	and	a7,s6,a7
ffffffffc0200914:	005eeeb3          	or	t4,t4,t0
ffffffffc0200918:	00c6e733          	or	a4,a3,a2
ffffffffc020091c:	006c6c33          	or	s8,s8,t1
ffffffffc0200920:	010b76b3          	and	a3,s6,a6
ffffffffc0200924:	00bb7b33          	and	s6,s6,a1
ffffffffc0200928:	01d7e7b3          	or	a5,a5,t4
ffffffffc020092c:	016c6b33          	or	s6,s8,s6
ffffffffc0200930:	01146433          	or	s0,s0,a7
ffffffffc0200934:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200936:	1702                	slli	a4,a4,0x20
ffffffffc0200938:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093a:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020093c:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020093e:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200940:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200944:	0167eb33          	or	s6,a5,s6
ffffffffc0200948:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020094a:	84bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020094e:	85a2                	mv	a1,s0
ffffffffc0200950:	00005517          	auipc	a0,0x5
ffffffffc0200954:	23050513          	addi	a0,a0,560 # ffffffffc0205b80 <commands+0x158>
ffffffffc0200958:	83dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020095c:	014b5613          	srli	a2,s6,0x14
ffffffffc0200960:	85da                	mv	a1,s6
ffffffffc0200962:	00005517          	auipc	a0,0x5
ffffffffc0200966:	23650513          	addi	a0,a0,566 # ffffffffc0205b98 <commands+0x170>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020096e:	008b05b3          	add	a1,s6,s0
ffffffffc0200972:	15fd                	addi	a1,a1,-1
ffffffffc0200974:	00005517          	auipc	a0,0x5
ffffffffc0200978:	24450513          	addi	a0,a0,580 # ffffffffc0205bb8 <commands+0x190>
ffffffffc020097c:	819ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200980:	00005517          	auipc	a0,0x5
ffffffffc0200984:	28850513          	addi	a0,a0,648 # ffffffffc0205c08 <commands+0x1e0>
        memory_base = mem_base;
ffffffffc0200988:	000aa797          	auipc	a5,0xaa
ffffffffc020098c:	ce87bc23          	sd	s0,-776(a5) # ffffffffc02aa680 <memory_base>
        memory_size = mem_size;
ffffffffc0200990:	000aa797          	auipc	a5,0xaa
ffffffffc0200994:	cf67bc23          	sd	s6,-776(a5) # ffffffffc02aa688 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200998:	b3f5                	j	ffffffffc0200784 <dtb_init+0x186>

ffffffffc020099a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020099a:	000aa517          	auipc	a0,0xaa
ffffffffc020099e:	ce653503          	ld	a0,-794(a0) # ffffffffc02aa680 <memory_base>
ffffffffc02009a2:	8082                	ret

ffffffffc02009a4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009a4:	000aa517          	auipc	a0,0xaa
ffffffffc02009a8:	ce453503          	ld	a0,-796(a0) # ffffffffc02aa688 <memory_size>
ffffffffc02009ac:	8082                	ret

ffffffffc02009ae <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009ae:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009b2:	8082                	ret

ffffffffc02009b4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009b4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02009b8:	8082                	ret

ffffffffc02009ba <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02009ba:	8082                	ret

ffffffffc02009bc <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02009bc:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02009c0:	00000797          	auipc	a5,0x0
ffffffffc02009c4:	4d878793          	addi	a5,a5,1240 # ffffffffc0200e98 <__alltraps>
ffffffffc02009c8:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc02009cc:	000407b7          	lui	a5,0x40
ffffffffc02009d0:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc02009d4:	8082                	ret

ffffffffc02009d6 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009d6:	610c                	ld	a1,0(a0)
{
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e022                	sd	s0,0(sp)
ffffffffc02009dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009de:	00005517          	auipc	a0,0x5
ffffffffc02009e2:	24250513          	addi	a0,a0,578 # ffffffffc0205c20 <commands+0x1f8>
{
ffffffffc02009e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009ec:	640c                	ld	a1,8(s0)
ffffffffc02009ee:	00005517          	auipc	a0,0x5
ffffffffc02009f2:	24a50513          	addi	a0,a0,586 # ffffffffc0205c38 <commands+0x210>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009fa:	680c                	ld	a1,16(s0)
ffffffffc02009fc:	00005517          	auipc	a0,0x5
ffffffffc0200a00:	25450513          	addi	a0,a0,596 # ffffffffc0205c50 <commands+0x228>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a08:	6c0c                	ld	a1,24(s0)
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	25e50513          	addi	a0,a0,606 # ffffffffc0205c68 <commands+0x240>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a16:	700c                	ld	a1,32(s0)
ffffffffc0200a18:	00005517          	auipc	a0,0x5
ffffffffc0200a1c:	26850513          	addi	a0,a0,616 # ffffffffc0205c80 <commands+0x258>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a24:	740c                	ld	a1,40(s0)
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	27250513          	addi	a0,a0,626 # ffffffffc0205c98 <commands+0x270>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a32:	780c                	ld	a1,48(s0)
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	27c50513          	addi	a0,a0,636 # ffffffffc0205cb0 <commands+0x288>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a40:	7c0c                	ld	a1,56(s0)
ffffffffc0200a42:	00005517          	auipc	a0,0x5
ffffffffc0200a46:	28650513          	addi	a0,a0,646 # ffffffffc0205cc8 <commands+0x2a0>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a4e:	602c                	ld	a1,64(s0)
ffffffffc0200a50:	00005517          	auipc	a0,0x5
ffffffffc0200a54:	29050513          	addi	a0,a0,656 # ffffffffc0205ce0 <commands+0x2b8>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a5c:	642c                	ld	a1,72(s0)
ffffffffc0200a5e:	00005517          	auipc	a0,0x5
ffffffffc0200a62:	29a50513          	addi	a0,a0,666 # ffffffffc0205cf8 <commands+0x2d0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a6a:	682c                	ld	a1,80(s0)
ffffffffc0200a6c:	00005517          	auipc	a0,0x5
ffffffffc0200a70:	2a450513          	addi	a0,a0,676 # ffffffffc0205d10 <commands+0x2e8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a78:	6c2c                	ld	a1,88(s0)
ffffffffc0200a7a:	00005517          	auipc	a0,0x5
ffffffffc0200a7e:	2ae50513          	addi	a0,a0,686 # ffffffffc0205d28 <commands+0x300>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a86:	702c                	ld	a1,96(s0)
ffffffffc0200a88:	00005517          	auipc	a0,0x5
ffffffffc0200a8c:	2b850513          	addi	a0,a0,696 # ffffffffc0205d40 <commands+0x318>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a94:	742c                	ld	a1,104(s0)
ffffffffc0200a96:	00005517          	auipc	a0,0x5
ffffffffc0200a9a:	2c250513          	addi	a0,a0,706 # ffffffffc0205d58 <commands+0x330>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aa2:	782c                	ld	a1,112(s0)
ffffffffc0200aa4:	00005517          	auipc	a0,0x5
ffffffffc0200aa8:	2cc50513          	addi	a0,a0,716 # ffffffffc0205d70 <commands+0x348>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200ab0:	7c2c                	ld	a1,120(s0)
ffffffffc0200ab2:	00005517          	auipc	a0,0x5
ffffffffc0200ab6:	2d650513          	addi	a0,a0,726 # ffffffffc0205d88 <commands+0x360>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200abe:	604c                	ld	a1,128(s0)
ffffffffc0200ac0:	00005517          	auipc	a0,0x5
ffffffffc0200ac4:	2e050513          	addi	a0,a0,736 # ffffffffc0205da0 <commands+0x378>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200acc:	644c                	ld	a1,136(s0)
ffffffffc0200ace:	00005517          	auipc	a0,0x5
ffffffffc0200ad2:	2ea50513          	addi	a0,a0,746 # ffffffffc0205db8 <commands+0x390>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200ada:	684c                	ld	a1,144(s0)
ffffffffc0200adc:	00005517          	auipc	a0,0x5
ffffffffc0200ae0:	2f450513          	addi	a0,a0,756 # ffffffffc0205dd0 <commands+0x3a8>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200ae8:	6c4c                	ld	a1,152(s0)
ffffffffc0200aea:	00005517          	auipc	a0,0x5
ffffffffc0200aee:	2fe50513          	addi	a0,a0,766 # ffffffffc0205de8 <commands+0x3c0>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200af6:	704c                	ld	a1,160(s0)
ffffffffc0200af8:	00005517          	auipc	a0,0x5
ffffffffc0200afc:	30850513          	addi	a0,a0,776 # ffffffffc0205e00 <commands+0x3d8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b04:	744c                	ld	a1,168(s0)
ffffffffc0200b06:	00005517          	auipc	a0,0x5
ffffffffc0200b0a:	31250513          	addi	a0,a0,786 # ffffffffc0205e18 <commands+0x3f0>
ffffffffc0200b0e:	e86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b12:	784c                	ld	a1,176(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	31c50513          	addi	a0,a0,796 # ffffffffc0205e30 <commands+0x408>
ffffffffc0200b1c:	e78ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b20:	7c4c                	ld	a1,184(s0)
ffffffffc0200b22:	00005517          	auipc	a0,0x5
ffffffffc0200b26:	32650513          	addi	a0,a0,806 # ffffffffc0205e48 <commands+0x420>
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b2e:	606c                	ld	a1,192(s0)
ffffffffc0200b30:	00005517          	auipc	a0,0x5
ffffffffc0200b34:	33050513          	addi	a0,a0,816 # ffffffffc0205e60 <commands+0x438>
ffffffffc0200b38:	e5cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b3c:	646c                	ld	a1,200(s0)
ffffffffc0200b3e:	00005517          	auipc	a0,0x5
ffffffffc0200b42:	33a50513          	addi	a0,a0,826 # ffffffffc0205e78 <commands+0x450>
ffffffffc0200b46:	e4eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b4a:	686c                	ld	a1,208(s0)
ffffffffc0200b4c:	00005517          	auipc	a0,0x5
ffffffffc0200b50:	34450513          	addi	a0,a0,836 # ffffffffc0205e90 <commands+0x468>
ffffffffc0200b54:	e40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b58:	6c6c                	ld	a1,216(s0)
ffffffffc0200b5a:	00005517          	auipc	a0,0x5
ffffffffc0200b5e:	34e50513          	addi	a0,a0,846 # ffffffffc0205ea8 <commands+0x480>
ffffffffc0200b62:	e32ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b66:	706c                	ld	a1,224(s0)
ffffffffc0200b68:	00005517          	auipc	a0,0x5
ffffffffc0200b6c:	35850513          	addi	a0,a0,856 # ffffffffc0205ec0 <commands+0x498>
ffffffffc0200b70:	e24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b74:	746c                	ld	a1,232(s0)
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	36250513          	addi	a0,a0,866 # ffffffffc0205ed8 <commands+0x4b0>
ffffffffc0200b7e:	e16ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b82:	786c                	ld	a1,240(s0)
ffffffffc0200b84:	00005517          	auipc	a0,0x5
ffffffffc0200b88:	36c50513          	addi	a0,a0,876 # ffffffffc0205ef0 <commands+0x4c8>
ffffffffc0200b8c:	e08ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b90:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b92:	6402                	ld	s0,0(sp)
ffffffffc0200b94:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b96:	00005517          	auipc	a0,0x5
ffffffffc0200b9a:	37250513          	addi	a0,a0,882 # ffffffffc0205f08 <commands+0x4e0>
}
ffffffffc0200b9e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ba4 <print_trapframe>:
{
ffffffffc0200ba4:	1141                	addi	sp,sp,-16
ffffffffc0200ba6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200ba8:	85aa                	mv	a1,a0
{
ffffffffc0200baa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bac:	00005517          	auipc	a0,0x5
ffffffffc0200bb0:	37450513          	addi	a0,a0,884 # ffffffffc0205f20 <commands+0x4f8>
{
ffffffffc0200bb4:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bb6:	ddeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200bba:	8522                	mv	a0,s0
ffffffffc0200bbc:	e1bff0ef          	jal	ra,ffffffffc02009d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200bc0:	10043583          	ld	a1,256(s0)
ffffffffc0200bc4:	00005517          	auipc	a0,0x5
ffffffffc0200bc8:	37450513          	addi	a0,a0,884 # ffffffffc0205f38 <commands+0x510>
ffffffffc0200bcc:	dc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200bd0:	10843583          	ld	a1,264(s0)
ffffffffc0200bd4:	00005517          	auipc	a0,0x5
ffffffffc0200bd8:	37c50513          	addi	a0,a0,892 # ffffffffc0205f50 <commands+0x528>
ffffffffc0200bdc:	db8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200be0:	11043583          	ld	a1,272(s0)
ffffffffc0200be4:	00005517          	auipc	a0,0x5
ffffffffc0200be8:	38450513          	addi	a0,a0,900 # ffffffffc0205f68 <commands+0x540>
ffffffffc0200bec:	da8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200bf4:	6402                	ld	s0,0(sp)
ffffffffc0200bf6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bf8:	00005517          	auipc	a0,0x5
ffffffffc0200bfc:	38050513          	addi	a0,a0,896 # ffffffffc0205f78 <commands+0x550>
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c02:	d92ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200c06 <interrupt_handler>:

extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200c06:	11853783          	ld	a5,280(a0)
ffffffffc0200c0a:	472d                	li	a4,11
ffffffffc0200c0c:	0786                	slli	a5,a5,0x1
ffffffffc0200c0e:	8385                	srli	a5,a5,0x1
ffffffffc0200c10:	06f76d63          	bltu	a4,a5,ffffffffc0200c8a <interrupt_handler+0x84>
ffffffffc0200c14:	00005717          	auipc	a4,0x5
ffffffffc0200c18:	42c70713          	addi	a4,a4,1068 # ffffffffc0206040 <commands+0x618>
ffffffffc0200c1c:	078a                	slli	a5,a5,0x2
ffffffffc0200c1e:	97ba                	add	a5,a5,a4
ffffffffc0200c20:	439c                	lw	a5,0(a5)
ffffffffc0200c22:	97ba                	add	a5,a5,a4
ffffffffc0200c24:	8782                	jr	a5
        break;
    case IRQ_S_SOFT:
        cprintf("Supervisor software interrupt\n");
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c26:	00005517          	auipc	a0,0x5
ffffffffc0200c2a:	3aa50513          	addi	a0,a0,938 # ffffffffc0205fd0 <commands+0x5a8>
ffffffffc0200c2e:	d66ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c32:	00005517          	auipc	a0,0x5
ffffffffc0200c36:	35e50513          	addi	a0,a0,862 # ffffffffc0205f90 <commands+0x568>
ffffffffc0200c3a:	d5aff06f          	j	ffffffffc0200194 <cprintf>
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	3b250513          	addi	a0,a0,946 # ffffffffc0205ff0 <commands+0x5c8>
ffffffffc0200c46:	d4eff06f          	j	ffffffffc0200194 <cprintf>
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
ffffffffc0200c4a:	00005517          	auipc	a0,0x5
ffffffffc0200c4e:	3d650513          	addi	a0,a0,982 # ffffffffc0206020 <commands+0x5f8>
ffffffffc0200c52:	d42ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200c56:	1141                	addi	sp,sp,-16
ffffffffc0200c58:	e406                	sd	ra,8(sp)
        clock_set_next_event();
ffffffffc0200c5a:	919ff0ef          	jal	ra,ffffffffc0200572 <clock_set_next_event>
        ticks++;
ffffffffc0200c5e:	000aa797          	auipc	a5,0xaa
ffffffffc0200c62:	a1278793          	addi	a5,a5,-1518 # ffffffffc02aa670 <ticks>
ffffffffc0200c66:	6398                	ld	a4,0(a5)
ffffffffc0200c68:	0705                	addi	a4,a4,1
ffffffffc0200c6a:	e398                	sd	a4,0(a5)
        if (ticks % TICK_NUM == 0) {
ffffffffc0200c6c:	639c                	ld	a5,0(a5)
ffffffffc0200c6e:	06400713          	li	a4,100
ffffffffc0200c72:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200c76:	cb99                	beqz	a5,ffffffffc0200c8c <interrupt_handler+0x86>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c78:	60a2                	ld	ra,8(sp)
ffffffffc0200c7a:	0141                	addi	sp,sp,16
ffffffffc0200c7c:	8082                	ret
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c7e:	00005517          	auipc	a0,0x5
ffffffffc0200c82:	33250513          	addi	a0,a0,818 # ffffffffc0205fb0 <commands+0x588>
ffffffffc0200c86:	d0eff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c8a:	bf29                	j	ffffffffc0200ba4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c8c:	06400593          	li	a1,100
ffffffffc0200c90:	00005517          	auipc	a0,0x5
ffffffffc0200c94:	38050513          	addi	a0,a0,896 # ffffffffc0206010 <commands+0x5e8>
ffffffffc0200c98:	cfcff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            if (current != NULL) {
ffffffffc0200c9c:	000aa797          	auipc	a5,0xaa
ffffffffc0200ca0:	a2c7b783          	ld	a5,-1492(a5) # ffffffffc02aa6c8 <current>
ffffffffc0200ca4:	dbf1                	beqz	a5,ffffffffc0200c78 <interrupt_handler+0x72>
                current->need_resched = 1;
ffffffffc0200ca6:	4705                	li	a4,1
ffffffffc0200ca8:	ef98                	sd	a4,24(a5)
ffffffffc0200caa:	b7f9                	j	ffffffffc0200c78 <interrupt_handler+0x72>

ffffffffc0200cac <exception_handler>:
}

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200cac:	11853583          	ld	a1,280(a0)
{
ffffffffc0200cb0:	1101                	addi	sp,sp,-32
ffffffffc0200cb2:	e822                	sd	s0,16(sp)
ffffffffc0200cb4:	ec06                	sd	ra,24(sp)
ffffffffc0200cb6:	47bd                	li	a5,15
ffffffffc0200cb8:	842a                	mv	s0,a0
ffffffffc0200cba:	0eb7e563          	bltu	a5,a1,ffffffffc0200da4 <exception_handler+0xf8>
ffffffffc0200cbe:	00005697          	auipc	a3,0x5
ffffffffc0200cc2:	51668693          	addi	a3,a3,1302 # ffffffffc02061d4 <commands+0x7ac>
ffffffffc0200cc6:	00259713          	slli	a4,a1,0x2
ffffffffc0200cca:	9736                	add	a4,a4,a3
ffffffffc0200ccc:	431c                	lw	a5,0(a4)
ffffffffc0200cce:	97b6                	add	a5,a5,a3
ffffffffc0200cd0:	8782                	jr	a5
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200cd2:	10053783          	ld	a5,256(a0)
    uintptr_t addr = tf->tval;
ffffffffc0200cd6:	11053603          	ld	a2,272(a0)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200cda:	1007f793          	andi	a5,a5,256
    if (trap_in_kernel(tf))
ffffffffc0200cde:	10079763          	bnez	a5,ffffffffc0200dec <exception_handler+0x140>
    int ret = do_pgfault(current->mm, tf->cause, addr);
ffffffffc0200ce2:	000aa417          	auipc	s0,0xaa
ffffffffc0200ce6:	9e640413          	addi	s0,s0,-1562 # ffffffffc02aa6c8 <current>
ffffffffc0200cea:	601c                	ld	a5,0(s0)
ffffffffc0200cec:	2581                	sext.w	a1,a1
ffffffffc0200cee:	7788                	ld	a0,40(a5)
ffffffffc0200cf0:	0e8030ef          	jal	ra,ffffffffc0203dd8 <do_pgfault>
    if (ret != 0)
ffffffffc0200cf4:	c93d                	beqz	a0,ffffffffc0200d6a <exception_handler+0xbe>
        current->flags |= PF_EXITING;
ffffffffc0200cf6:	6018                	ld	a4,0(s0)
ffffffffc0200cf8:	0b072783          	lw	a5,176(a4)
ffffffffc0200cfc:	0017e793          	ori	a5,a5,1
ffffffffc0200d00:	0af72823          	sw	a5,176(a4)
ffffffffc0200d04:	a09d                	j	ffffffffc0200d6a <exception_handler+0xbe>
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200d06:	00005517          	auipc	a0,0x5
ffffffffc0200d0a:	45250513          	addi	a0,a0,1106 # ffffffffc0206158 <commands+0x730>
ffffffffc0200d0e:	c86ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200d12:	10843783          	ld	a5,264(s0)

    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d16:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200d18:	0791                	addi	a5,a5,4
ffffffffc0200d1a:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d1e:	6442                	ld	s0,16(sp)
ffffffffc0200d20:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200d22:	54a0406f          	j	ffffffffc020526c <syscall>
        cprintf("Instruction address misaligned\n");
ffffffffc0200d26:	00005517          	auipc	a0,0x5
ffffffffc0200d2a:	34a50513          	addi	a0,a0,842 # ffffffffc0206070 <commands+0x648>
}
ffffffffc0200d2e:	6442                	ld	s0,16(sp)
ffffffffc0200d30:	60e2                	ld	ra,24(sp)
ffffffffc0200d32:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200d34:	c60ff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200d38:	00005517          	auipc	a0,0x5
ffffffffc0200d3c:	35850513          	addi	a0,a0,856 # ffffffffc0206090 <commands+0x668>
ffffffffc0200d40:	b7fd                	j	ffffffffc0200d2e <exception_handler+0x82>
        cprintf("Illegal instruction\n");
ffffffffc0200d42:	00005517          	auipc	a0,0x5
ffffffffc0200d46:	36e50513          	addi	a0,a0,878 # ffffffffc02060b0 <commands+0x688>
ffffffffc0200d4a:	b7d5                	j	ffffffffc0200d2e <exception_handler+0x82>
    cprintf("Breakpoint\n");
ffffffffc0200d4c:	00005517          	auipc	a0,0x5
ffffffffc0200d50:	37c50513          	addi	a0,a0,892 # ffffffffc02060c8 <commands+0x6a0>
ffffffffc0200d54:	c40ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf->gpr.a7 == 10) {
ffffffffc0200d58:	6458                	ld	a4,136(s0)
ffffffffc0200d5a:	47a9                	li	a5,10
ffffffffc0200d5c:	06f70563          	beq	a4,a5,ffffffffc0200dc6 <exception_handler+0x11a>
        tf->epc += 4;
ffffffffc0200d60:	10843783          	ld	a5,264(s0)
ffffffffc0200d64:	0791                	addi	a5,a5,4
ffffffffc0200d66:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200d6a:	60e2                	ld	ra,24(sp)
ffffffffc0200d6c:	6442                	ld	s0,16(sp)
ffffffffc0200d6e:	6105                	addi	sp,sp,32
ffffffffc0200d70:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d72:	00005517          	auipc	a0,0x5
ffffffffc0200d76:	36650513          	addi	a0,a0,870 # ffffffffc02060d8 <commands+0x6b0>
ffffffffc0200d7a:	bf55                	j	ffffffffc0200d2e <exception_handler+0x82>
        cprintf("Load access fault\n");
ffffffffc0200d7c:	00005517          	auipc	a0,0x5
ffffffffc0200d80:	37c50513          	addi	a0,a0,892 # ffffffffc02060f8 <commands+0x6d0>
ffffffffc0200d84:	b76d                	j	ffffffffc0200d2e <exception_handler+0x82>
        cprintf("Environment call from H-mode\n");
ffffffffc0200d86:	00005517          	auipc	a0,0x5
ffffffffc0200d8a:	3f250513          	addi	a0,a0,1010 # ffffffffc0206178 <commands+0x750>
ffffffffc0200d8e:	b745                	j	ffffffffc0200d2e <exception_handler+0x82>
        cprintf("Environment call from M-mode\n");
ffffffffc0200d90:	00005517          	auipc	a0,0x5
ffffffffc0200d94:	40850513          	addi	a0,a0,1032 # ffffffffc0206198 <commands+0x770>
ffffffffc0200d98:	bf59                	j	ffffffffc0200d2e <exception_handler+0x82>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d9a:	00005517          	auipc	a0,0x5
ffffffffc0200d9e:	3a650513          	addi	a0,a0,934 # ffffffffc0206140 <commands+0x718>
ffffffffc0200da2:	b771                	j	ffffffffc0200d2e <exception_handler+0x82>
        print_trapframe(tf);
ffffffffc0200da4:	8522                	mv	a0,s0
}
ffffffffc0200da6:	6442                	ld	s0,16(sp)
ffffffffc0200da8:	60e2                	ld	ra,24(sp)
ffffffffc0200daa:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200dac:	bbe5                	j	ffffffffc0200ba4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200dae:	00005617          	auipc	a2,0x5
ffffffffc0200db2:	36260613          	addi	a2,a2,866 # ffffffffc0206110 <commands+0x6e8>
ffffffffc0200db6:	0ec00593          	li	a1,236
ffffffffc0200dba:	00005517          	auipc	a0,0x5
ffffffffc0200dbe:	36e50513          	addi	a0,a0,878 # ffffffffc0206128 <commands+0x700>
ffffffffc0200dc2:	eccff0ef          	jal	ra,ffffffffc020048e <__panic>
        tf->epc += 4;
ffffffffc0200dc6:	10843783          	ld	a5,264(s0)
ffffffffc0200dca:	0791                	addi	a5,a5,4
ffffffffc0200dcc:	10f43423          	sd	a5,264(s0)
        syscall();
ffffffffc0200dd0:	49c040ef          	jal	ra,ffffffffc020526c <syscall>
        kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dd4:	000aa797          	auipc	a5,0xaa
ffffffffc0200dd8:	8f47b783          	ld	a5,-1804(a5) # ffffffffc02aa6c8 <current>
ffffffffc0200ddc:	6b9c                	ld	a5,16(a5)
ffffffffc0200dde:	8522                	mv	a0,s0
}
ffffffffc0200de0:	6442                	ld	s0,16(sp)
ffffffffc0200de2:	60e2                	ld	ra,24(sp)
        kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200de4:	6589                	lui	a1,0x2
ffffffffc0200de6:	95be                	add	a1,a1,a5
}
ffffffffc0200de8:	6105                	addi	sp,sp,32
        kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dea:	aab5                	j	ffffffffc0200f66 <kernel_execve_ret>
ffffffffc0200dec:	e432                	sd	a2,8(sp)
        print_trapframe(tf);
ffffffffc0200dee:	db7ff0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
        panic("page fault in kernel at %p\n", addr);
ffffffffc0200df2:	6622                	ld	a2,8(sp)
ffffffffc0200df4:	0bc00593          	li	a1,188
ffffffffc0200df8:	00005517          	auipc	a0,0x5
ffffffffc0200dfc:	33050513          	addi	a0,a0,816 # ffffffffc0206128 <commands+0x700>
ffffffffc0200e00:	86b2                	mv	a3,a2
ffffffffc0200e02:	00005617          	auipc	a2,0x5
ffffffffc0200e06:	3b660613          	addi	a2,a2,950 # ffffffffc02061b8 <commands+0x790>
ffffffffc0200e0a:	e84ff0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0200e0e <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
ffffffffc0200e0e:	1101                	addi	sp,sp,-32
ffffffffc0200e10:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e12:	000aa417          	auipc	s0,0xaa
ffffffffc0200e16:	8b640413          	addi	s0,s0,-1866 # ffffffffc02aa6c8 <current>
ffffffffc0200e1a:	6018                	ld	a4,0(s0)
{
ffffffffc0200e1c:	ec06                	sd	ra,24(sp)
ffffffffc0200e1e:	e426                	sd	s1,8(sp)
ffffffffc0200e20:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e22:	11853683          	ld	a3,280(a0)
    if (current == NULL)
ffffffffc0200e26:	cf1d                	beqz	a4,ffffffffc0200e64 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e28:	10053483          	ld	s1,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e2c:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200e30:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e32:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e36:	0206c463          	bltz	a3,ffffffffc0200e5e <trap+0x50>
        exception_handler(tf);
ffffffffc0200e3a:	e73ff0ef          	jal	ra,ffffffffc0200cac <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e3e:	601c                	ld	a5,0(s0)
ffffffffc0200e40:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel)
ffffffffc0200e44:	e499                	bnez	s1,ffffffffc0200e52 <trap+0x44>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e46:	0b07a703          	lw	a4,176(a5)
ffffffffc0200e4a:	8b05                	andi	a4,a4,1
ffffffffc0200e4c:	e329                	bnez	a4,ffffffffc0200e8e <trap+0x80>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e4e:	6f9c                	ld	a5,24(a5)
ffffffffc0200e50:	eb85                	bnez	a5,ffffffffc0200e80 <trap+0x72>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e52:	60e2                	ld	ra,24(sp)
ffffffffc0200e54:	6442                	ld	s0,16(sp)
ffffffffc0200e56:	64a2                	ld	s1,8(sp)
ffffffffc0200e58:	6902                	ld	s2,0(sp)
ffffffffc0200e5a:	6105                	addi	sp,sp,32
ffffffffc0200e5c:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e5e:	da9ff0ef          	jal	ra,ffffffffc0200c06 <interrupt_handler>
ffffffffc0200e62:	bff1                	j	ffffffffc0200e3e <trap+0x30>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e64:	0006c863          	bltz	a3,ffffffffc0200e74 <trap+0x66>
}
ffffffffc0200e68:	6442                	ld	s0,16(sp)
ffffffffc0200e6a:	60e2                	ld	ra,24(sp)
ffffffffc0200e6c:	64a2                	ld	s1,8(sp)
ffffffffc0200e6e:	6902                	ld	s2,0(sp)
ffffffffc0200e70:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200e72:	bd2d                	j	ffffffffc0200cac <exception_handler>
}
ffffffffc0200e74:	6442                	ld	s0,16(sp)
ffffffffc0200e76:	60e2                	ld	ra,24(sp)
ffffffffc0200e78:	64a2                	ld	s1,8(sp)
ffffffffc0200e7a:	6902                	ld	s2,0(sp)
ffffffffc0200e7c:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200e7e:	b361                	j	ffffffffc0200c06 <interrupt_handler>
}
ffffffffc0200e80:	6442                	ld	s0,16(sp)
ffffffffc0200e82:	60e2                	ld	ra,24(sp)
ffffffffc0200e84:	64a2                	ld	s1,8(sp)
ffffffffc0200e86:	6902                	ld	s2,0(sp)
ffffffffc0200e88:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e8a:	2f60406f          	j	ffffffffc0205180 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e8e:	555d                	li	a0,-9
ffffffffc0200e90:	636030ef          	jal	ra,ffffffffc02044c6 <do_exit>
            if (current->need_resched)
ffffffffc0200e94:	601c                	ld	a5,0(s0)
ffffffffc0200e96:	bf65                	j	ffffffffc0200e4e <trap+0x40>

ffffffffc0200e98 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e98:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e9c:	00011463          	bnez	sp,ffffffffc0200ea4 <__alltraps+0xc>
ffffffffc0200ea0:	14002173          	csrr	sp,sscratch
ffffffffc0200ea4:	712d                	addi	sp,sp,-288
ffffffffc0200ea6:	e002                	sd	zero,0(sp)
ffffffffc0200ea8:	e406                	sd	ra,8(sp)
ffffffffc0200eaa:	ec0e                	sd	gp,24(sp)
ffffffffc0200eac:	f012                	sd	tp,32(sp)
ffffffffc0200eae:	f416                	sd	t0,40(sp)
ffffffffc0200eb0:	f81a                	sd	t1,48(sp)
ffffffffc0200eb2:	fc1e                	sd	t2,56(sp)
ffffffffc0200eb4:	e0a2                	sd	s0,64(sp)
ffffffffc0200eb6:	e4a6                	sd	s1,72(sp)
ffffffffc0200eb8:	e8aa                	sd	a0,80(sp)
ffffffffc0200eba:	ecae                	sd	a1,88(sp)
ffffffffc0200ebc:	f0b2                	sd	a2,96(sp)
ffffffffc0200ebe:	f4b6                	sd	a3,104(sp)
ffffffffc0200ec0:	f8ba                	sd	a4,112(sp)
ffffffffc0200ec2:	fcbe                	sd	a5,120(sp)
ffffffffc0200ec4:	e142                	sd	a6,128(sp)
ffffffffc0200ec6:	e546                	sd	a7,136(sp)
ffffffffc0200ec8:	e94a                	sd	s2,144(sp)
ffffffffc0200eca:	ed4e                	sd	s3,152(sp)
ffffffffc0200ecc:	f152                	sd	s4,160(sp)
ffffffffc0200ece:	f556                	sd	s5,168(sp)
ffffffffc0200ed0:	f95a                	sd	s6,176(sp)
ffffffffc0200ed2:	fd5e                	sd	s7,184(sp)
ffffffffc0200ed4:	e1e2                	sd	s8,192(sp)
ffffffffc0200ed6:	e5e6                	sd	s9,200(sp)
ffffffffc0200ed8:	e9ea                	sd	s10,208(sp)
ffffffffc0200eda:	edee                	sd	s11,216(sp)
ffffffffc0200edc:	f1f2                	sd	t3,224(sp)
ffffffffc0200ede:	f5f6                	sd	t4,232(sp)
ffffffffc0200ee0:	f9fa                	sd	t5,240(sp)
ffffffffc0200ee2:	fdfe                	sd	t6,248(sp)
ffffffffc0200ee4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ee8:	100024f3          	csrr	s1,sstatus
ffffffffc0200eec:	14102973          	csrr	s2,sepc
ffffffffc0200ef0:	143029f3          	csrr	s3,stval
ffffffffc0200ef4:	14202a73          	csrr	s4,scause
ffffffffc0200ef8:	e822                	sd	s0,16(sp)
ffffffffc0200efa:	e226                	sd	s1,256(sp)
ffffffffc0200efc:	e64a                	sd	s2,264(sp)
ffffffffc0200efe:	ea4e                	sd	s3,272(sp)
ffffffffc0200f00:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f02:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f04:	f0bff0ef          	jal	ra,ffffffffc0200e0e <trap>

ffffffffc0200f08 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f08:	6492                	ld	s1,256(sp)
ffffffffc0200f0a:	6932                	ld	s2,264(sp)
ffffffffc0200f0c:	1004f413          	andi	s0,s1,256
ffffffffc0200f10:	e401                	bnez	s0,ffffffffc0200f18 <__trapret+0x10>
ffffffffc0200f12:	1200                	addi	s0,sp,288
ffffffffc0200f14:	14041073          	csrw	sscratch,s0
ffffffffc0200f18:	10049073          	csrw	sstatus,s1
ffffffffc0200f1c:	14191073          	csrw	sepc,s2
ffffffffc0200f20:	60a2                	ld	ra,8(sp)
ffffffffc0200f22:	61e2                	ld	gp,24(sp)
ffffffffc0200f24:	7202                	ld	tp,32(sp)
ffffffffc0200f26:	72a2                	ld	t0,40(sp)
ffffffffc0200f28:	7342                	ld	t1,48(sp)
ffffffffc0200f2a:	73e2                	ld	t2,56(sp)
ffffffffc0200f2c:	6406                	ld	s0,64(sp)
ffffffffc0200f2e:	64a6                	ld	s1,72(sp)
ffffffffc0200f30:	6546                	ld	a0,80(sp)
ffffffffc0200f32:	65e6                	ld	a1,88(sp)
ffffffffc0200f34:	7606                	ld	a2,96(sp)
ffffffffc0200f36:	76a6                	ld	a3,104(sp)
ffffffffc0200f38:	7746                	ld	a4,112(sp)
ffffffffc0200f3a:	77e6                	ld	a5,120(sp)
ffffffffc0200f3c:	680a                	ld	a6,128(sp)
ffffffffc0200f3e:	68aa                	ld	a7,136(sp)
ffffffffc0200f40:	694a                	ld	s2,144(sp)
ffffffffc0200f42:	69ea                	ld	s3,152(sp)
ffffffffc0200f44:	7a0a                	ld	s4,160(sp)
ffffffffc0200f46:	7aaa                	ld	s5,168(sp)
ffffffffc0200f48:	7b4a                	ld	s6,176(sp)
ffffffffc0200f4a:	7bea                	ld	s7,184(sp)
ffffffffc0200f4c:	6c0e                	ld	s8,192(sp)
ffffffffc0200f4e:	6cae                	ld	s9,200(sp)
ffffffffc0200f50:	6d4e                	ld	s10,208(sp)
ffffffffc0200f52:	6dee                	ld	s11,216(sp)
ffffffffc0200f54:	7e0e                	ld	t3,224(sp)
ffffffffc0200f56:	7eae                	ld	t4,232(sp)
ffffffffc0200f58:	7f4e                	ld	t5,240(sp)
ffffffffc0200f5a:	7fee                	ld	t6,248(sp)
ffffffffc0200f5c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f5e:	10200073          	sret

ffffffffc0200f62 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f62:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f64:	b755                	j	ffffffffc0200f08 <__trapret>

ffffffffc0200f66 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f66:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f6a:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f6e:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f72:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f76:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f7a:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f7e:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f82:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f86:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f8a:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f8c:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f8e:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f90:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f92:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f94:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f96:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f98:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f9a:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f9c:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f9e:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200fa0:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200fa2:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200fa4:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200fa6:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200fa8:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200faa:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200fac:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200fae:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200fb0:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200fb2:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200fb4:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200fb6:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200fb8:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200fba:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200fbc:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200fbe:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200fc0:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200fc2:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200fc4:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200fc6:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200fc8:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200fca:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200fcc:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200fce:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200fd0:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200fd2:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200fd4:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200fd6:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200fd8:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200fda:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200fdc:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200fde:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200fe0:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200fe2:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200fe4:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200fe6:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200fe8:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200fea:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200fec:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200fee:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200ff0:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200ff2:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200ff4:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200ff6:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200ff8:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200ffa:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200ffc:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200ffe:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0201000:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0201002:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0201004:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0201006:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0201008:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc020100a:	812e                	mv	sp,a1
ffffffffc020100c:	bdf5                	j	ffffffffc0200f08 <__trapret>

ffffffffc020100e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020100e:	000a5797          	auipc	a5,0xa5
ffffffffc0201012:	63278793          	addi	a5,a5,1586 # ffffffffc02a6640 <free_area>
ffffffffc0201016:	e79c                	sd	a5,8(a5)
ffffffffc0201018:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc020101a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020101e:	8082                	ret

ffffffffc0201020 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0201020:	000a5517          	auipc	a0,0xa5
ffffffffc0201024:	63056503          	lwu	a0,1584(a0) # ffffffffc02a6650 <free_area+0x10>
ffffffffc0201028:	8082                	ret

ffffffffc020102a <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc020102a:	715d                	addi	sp,sp,-80
ffffffffc020102c:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020102e:	000a5417          	auipc	s0,0xa5
ffffffffc0201032:	61240413          	addi	s0,s0,1554 # ffffffffc02a6640 <free_area>
ffffffffc0201036:	641c                	ld	a5,8(s0)
ffffffffc0201038:	e486                	sd	ra,72(sp)
ffffffffc020103a:	fc26                	sd	s1,56(sp)
ffffffffc020103c:	f84a                	sd	s2,48(sp)
ffffffffc020103e:	f44e                	sd	s3,40(sp)
ffffffffc0201040:	f052                	sd	s4,32(sp)
ffffffffc0201042:	ec56                	sd	s5,24(sp)
ffffffffc0201044:	e85a                	sd	s6,16(sp)
ffffffffc0201046:	e45e                	sd	s7,8(sp)
ffffffffc0201048:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020104a:	2a878d63          	beq	a5,s0,ffffffffc0201304 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020104e:	4481                	li	s1,0
ffffffffc0201050:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201052:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201056:	8b09                	andi	a4,a4,2
ffffffffc0201058:	2a070a63          	beqz	a4,ffffffffc020130c <default_check+0x2e2>
        count++, total += p->property;
ffffffffc020105c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201060:	679c                	ld	a5,8(a5)
ffffffffc0201062:	2905                	addiw	s2,s2,1
ffffffffc0201064:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0201066:	fe8796e3          	bne	a5,s0,ffffffffc0201052 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020106a:	89a6                	mv	s3,s1
ffffffffc020106c:	6df000ef          	jal	ra,ffffffffc0201f4a <nr_free_pages>
ffffffffc0201070:	6f351e63          	bne	a0,s3,ffffffffc020176c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201074:	4505                	li	a0,1
ffffffffc0201076:	657000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc020107a:	8aaa                	mv	s5,a0
ffffffffc020107c:	42050863          	beqz	a0,ffffffffc02014ac <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201080:	4505                	li	a0,1
ffffffffc0201082:	64b000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201086:	89aa                	mv	s3,a0
ffffffffc0201088:	70050263          	beqz	a0,ffffffffc020178c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020108c:	4505                	li	a0,1
ffffffffc020108e:	63f000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201092:	8a2a                	mv	s4,a0
ffffffffc0201094:	48050c63          	beqz	a0,ffffffffc020152c <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201098:	293a8a63          	beq	s5,s3,ffffffffc020132c <default_check+0x302>
ffffffffc020109c:	28aa8863          	beq	s5,a0,ffffffffc020132c <default_check+0x302>
ffffffffc02010a0:	28a98663          	beq	s3,a0,ffffffffc020132c <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010a4:	000aa783          	lw	a5,0(s5)
ffffffffc02010a8:	2a079263          	bnez	a5,ffffffffc020134c <default_check+0x322>
ffffffffc02010ac:	0009a783          	lw	a5,0(s3)
ffffffffc02010b0:	28079e63          	bnez	a5,ffffffffc020134c <default_check+0x322>
ffffffffc02010b4:	411c                	lw	a5,0(a0)
ffffffffc02010b6:	28079b63          	bnez	a5,ffffffffc020134c <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc02010ba:	000a9797          	auipc	a5,0xa9
ffffffffc02010be:	5f67b783          	ld	a5,1526(a5) # ffffffffc02aa6b0 <pages>
ffffffffc02010c2:	40fa8733          	sub	a4,s5,a5
ffffffffc02010c6:	00007617          	auipc	a2,0x7
ffffffffc02010ca:	80a63603          	ld	a2,-2038(a2) # ffffffffc02078d0 <nbase>
ffffffffc02010ce:	8719                	srai	a4,a4,0x6
ffffffffc02010d0:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010d2:	000a9697          	auipc	a3,0xa9
ffffffffc02010d6:	5d66b683          	ld	a3,1494(a3) # ffffffffc02aa6a8 <npage>
ffffffffc02010da:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02010dc:	0732                	slli	a4,a4,0xc
ffffffffc02010de:	28d77763          	bgeu	a4,a3,ffffffffc020136c <default_check+0x342>
    return page - pages + nbase;
ffffffffc02010e2:	40f98733          	sub	a4,s3,a5
ffffffffc02010e6:	8719                	srai	a4,a4,0x6
ffffffffc02010e8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010ea:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010ec:	4cd77063          	bgeu	a4,a3,ffffffffc02015ac <default_check+0x582>
    return page - pages + nbase;
ffffffffc02010f0:	40f507b3          	sub	a5,a0,a5
ffffffffc02010f4:	8799                	srai	a5,a5,0x6
ffffffffc02010f6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010f8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010fa:	30d7f963          	bgeu	a5,a3,ffffffffc020140c <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02010fe:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201100:	00043c03          	ld	s8,0(s0)
ffffffffc0201104:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201108:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc020110c:	e400                	sd	s0,8(s0)
ffffffffc020110e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201110:	000a5797          	auipc	a5,0xa5
ffffffffc0201114:	5407a023          	sw	zero,1344(a5) # ffffffffc02a6650 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201118:	5b5000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc020111c:	2c051863          	bnez	a0,ffffffffc02013ec <default_check+0x3c2>
    free_page(p0);
ffffffffc0201120:	4585                	li	a1,1
ffffffffc0201122:	8556                	mv	a0,s5
ffffffffc0201124:	5e7000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    free_page(p1);
ffffffffc0201128:	4585                	li	a1,1
ffffffffc020112a:	854e                	mv	a0,s3
ffffffffc020112c:	5df000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    free_page(p2);
ffffffffc0201130:	4585                	li	a1,1
ffffffffc0201132:	8552                	mv	a0,s4
ffffffffc0201134:	5d7000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    assert(nr_free == 3);
ffffffffc0201138:	4818                	lw	a4,16(s0)
ffffffffc020113a:	478d                	li	a5,3
ffffffffc020113c:	28f71863          	bne	a4,a5,ffffffffc02013cc <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201140:	4505                	li	a0,1
ffffffffc0201142:	58b000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201146:	89aa                	mv	s3,a0
ffffffffc0201148:	26050263          	beqz	a0,ffffffffc02013ac <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020114c:	4505                	li	a0,1
ffffffffc020114e:	57f000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201152:	8aaa                	mv	s5,a0
ffffffffc0201154:	3a050c63          	beqz	a0,ffffffffc020150c <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201158:	4505                	li	a0,1
ffffffffc020115a:	573000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc020115e:	8a2a                	mv	s4,a0
ffffffffc0201160:	38050663          	beqz	a0,ffffffffc02014ec <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0201164:	4505                	li	a0,1
ffffffffc0201166:	567000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc020116a:	36051163          	bnez	a0,ffffffffc02014cc <default_check+0x4a2>
    free_page(p0);
ffffffffc020116e:	4585                	li	a1,1
ffffffffc0201170:	854e                	mv	a0,s3
ffffffffc0201172:	599000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201176:	641c                	ld	a5,8(s0)
ffffffffc0201178:	20878a63          	beq	a5,s0,ffffffffc020138c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020117c:	4505                	li	a0,1
ffffffffc020117e:	54f000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201182:	30a99563          	bne	s3,a0,ffffffffc020148c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0201186:	4505                	li	a0,1
ffffffffc0201188:	545000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc020118c:	2e051063          	bnez	a0,ffffffffc020146c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0201190:	481c                	lw	a5,16(s0)
ffffffffc0201192:	2a079d63          	bnez	a5,ffffffffc020144c <default_check+0x422>
    free_page(p);
ffffffffc0201196:	854e                	mv	a0,s3
ffffffffc0201198:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020119a:	01843023          	sd	s8,0(s0)
ffffffffc020119e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc02011a2:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc02011a6:	565000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    free_page(p1);
ffffffffc02011aa:	4585                	li	a1,1
ffffffffc02011ac:	8556                	mv	a0,s5
ffffffffc02011ae:	55d000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    free_page(p2);
ffffffffc02011b2:	4585                	li	a1,1
ffffffffc02011b4:	8552                	mv	a0,s4
ffffffffc02011b6:	555000ef          	jal	ra,ffffffffc0201f0a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02011ba:	4515                	li	a0,5
ffffffffc02011bc:	511000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc02011c0:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02011c2:	26050563          	beqz	a0,ffffffffc020142c <default_check+0x402>
ffffffffc02011c6:	651c                	ld	a5,8(a0)
ffffffffc02011c8:	8385                	srli	a5,a5,0x1
ffffffffc02011ca:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc02011cc:	54079063          	bnez	a5,ffffffffc020170c <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011d0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011d2:	00043b03          	ld	s6,0(s0)
ffffffffc02011d6:	00843a83          	ld	s5,8(s0)
ffffffffc02011da:	e000                	sd	s0,0(s0)
ffffffffc02011dc:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02011de:	4ef000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc02011e2:	50051563          	bnez	a0,ffffffffc02016ec <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011e6:	08098a13          	addi	s4,s3,128
ffffffffc02011ea:	8552                	mv	a0,s4
ffffffffc02011ec:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011ee:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02011f2:	000a5797          	auipc	a5,0xa5
ffffffffc02011f6:	4407af23          	sw	zero,1118(a5) # ffffffffc02a6650 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011fa:	511000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011fe:	4511                	li	a0,4
ffffffffc0201200:	4cd000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201204:	4c051463          	bnez	a0,ffffffffc02016cc <default_check+0x6a2>
ffffffffc0201208:	0889b783          	ld	a5,136(s3)
ffffffffc020120c:	8385                	srli	a5,a5,0x1
ffffffffc020120e:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201210:	48078e63          	beqz	a5,ffffffffc02016ac <default_check+0x682>
ffffffffc0201214:	0909a703          	lw	a4,144(s3)
ffffffffc0201218:	478d                	li	a5,3
ffffffffc020121a:	48f71963          	bne	a4,a5,ffffffffc02016ac <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020121e:	450d                	li	a0,3
ffffffffc0201220:	4ad000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201224:	8c2a                	mv	s8,a0
ffffffffc0201226:	46050363          	beqz	a0,ffffffffc020168c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020122a:	4505                	li	a0,1
ffffffffc020122c:	4a1000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0201230:	42051e63          	bnez	a0,ffffffffc020166c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201234:	418a1c63          	bne	s4,s8,ffffffffc020164c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201238:	4585                	li	a1,1
ffffffffc020123a:	854e                	mv	a0,s3
ffffffffc020123c:	4cf000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    free_pages(p1, 3);
ffffffffc0201240:	458d                	li	a1,3
ffffffffc0201242:	8552                	mv	a0,s4
ffffffffc0201244:	4c7000ef          	jal	ra,ffffffffc0201f0a <free_pages>
ffffffffc0201248:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020124c:	04098c13          	addi	s8,s3,64
ffffffffc0201250:	8385                	srli	a5,a5,0x1
ffffffffc0201252:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201254:	3c078c63          	beqz	a5,ffffffffc020162c <default_check+0x602>
ffffffffc0201258:	0109a703          	lw	a4,16(s3)
ffffffffc020125c:	4785                	li	a5,1
ffffffffc020125e:	3cf71763          	bne	a4,a5,ffffffffc020162c <default_check+0x602>
ffffffffc0201262:	008a3783          	ld	a5,8(s4)
ffffffffc0201266:	8385                	srli	a5,a5,0x1
ffffffffc0201268:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020126a:	3a078163          	beqz	a5,ffffffffc020160c <default_check+0x5e2>
ffffffffc020126e:	010a2703          	lw	a4,16(s4)
ffffffffc0201272:	478d                	li	a5,3
ffffffffc0201274:	38f71c63          	bne	a4,a5,ffffffffc020160c <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201278:	4505                	li	a0,1
ffffffffc020127a:	453000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc020127e:	36a99763          	bne	s3,a0,ffffffffc02015ec <default_check+0x5c2>
    free_page(p0);
ffffffffc0201282:	4585                	li	a1,1
ffffffffc0201284:	487000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201288:	4509                	li	a0,2
ffffffffc020128a:	443000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc020128e:	32aa1f63          	bne	s4,a0,ffffffffc02015cc <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0201292:	4589                	li	a1,2
ffffffffc0201294:	477000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    free_page(p2);
ffffffffc0201298:	4585                	li	a1,1
ffffffffc020129a:	8562                	mv	a0,s8
ffffffffc020129c:	46f000ef          	jal	ra,ffffffffc0201f0a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012a0:	4515                	li	a0,5
ffffffffc02012a2:	42b000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc02012a6:	89aa                	mv	s3,a0
ffffffffc02012a8:	48050263          	beqz	a0,ffffffffc020172c <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02012ac:	4505                	li	a0,1
ffffffffc02012ae:	41f000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc02012b2:	2c051d63          	bnez	a0,ffffffffc020158c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02012b6:	481c                	lw	a5,16(s0)
ffffffffc02012b8:	2a079a63          	bnez	a5,ffffffffc020156c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02012bc:	4595                	li	a1,5
ffffffffc02012be:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02012c0:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02012c4:	01643023          	sd	s6,0(s0)
ffffffffc02012c8:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02012cc:	43f000ef          	jal	ra,ffffffffc0201f0a <free_pages>
    return listelm->next;
ffffffffc02012d0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012d2:	00878963          	beq	a5,s0,ffffffffc02012e4 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012d6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012da:	679c                	ld	a5,8(a5)
ffffffffc02012dc:	397d                	addiw	s2,s2,-1
ffffffffc02012de:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012e0:	fe879be3          	bne	a5,s0,ffffffffc02012d6 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02012e4:	26091463          	bnez	s2,ffffffffc020154c <default_check+0x522>
    assert(total == 0);
ffffffffc02012e8:	46049263          	bnez	s1,ffffffffc020174c <default_check+0x722>
}
ffffffffc02012ec:	60a6                	ld	ra,72(sp)
ffffffffc02012ee:	6406                	ld	s0,64(sp)
ffffffffc02012f0:	74e2                	ld	s1,56(sp)
ffffffffc02012f2:	7942                	ld	s2,48(sp)
ffffffffc02012f4:	79a2                	ld	s3,40(sp)
ffffffffc02012f6:	7a02                	ld	s4,32(sp)
ffffffffc02012f8:	6ae2                	ld	s5,24(sp)
ffffffffc02012fa:	6b42                	ld	s6,16(sp)
ffffffffc02012fc:	6ba2                	ld	s7,8(sp)
ffffffffc02012fe:	6c02                	ld	s8,0(sp)
ffffffffc0201300:	6161                	addi	sp,sp,80
ffffffffc0201302:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201304:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201306:	4481                	li	s1,0
ffffffffc0201308:	4901                	li	s2,0
ffffffffc020130a:	b38d                	j	ffffffffc020106c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc020130c:	00005697          	auipc	a3,0x5
ffffffffc0201310:	f0c68693          	addi	a3,a3,-244 # ffffffffc0206218 <commands+0x7f0>
ffffffffc0201314:	00005617          	auipc	a2,0x5
ffffffffc0201318:	f1460613          	addi	a2,a2,-236 # ffffffffc0206228 <commands+0x800>
ffffffffc020131c:	11000593          	li	a1,272
ffffffffc0201320:	00005517          	auipc	a0,0x5
ffffffffc0201324:	f2050513          	addi	a0,a0,-224 # ffffffffc0206240 <commands+0x818>
ffffffffc0201328:	966ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020132c:	00005697          	auipc	a3,0x5
ffffffffc0201330:	fac68693          	addi	a3,a3,-84 # ffffffffc02062d8 <commands+0x8b0>
ffffffffc0201334:	00005617          	auipc	a2,0x5
ffffffffc0201338:	ef460613          	addi	a2,a2,-268 # ffffffffc0206228 <commands+0x800>
ffffffffc020133c:	0db00593          	li	a1,219
ffffffffc0201340:	00005517          	auipc	a0,0x5
ffffffffc0201344:	f0050513          	addi	a0,a0,-256 # ffffffffc0206240 <commands+0x818>
ffffffffc0201348:	946ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020134c:	00005697          	auipc	a3,0x5
ffffffffc0201350:	fb468693          	addi	a3,a3,-76 # ffffffffc0206300 <commands+0x8d8>
ffffffffc0201354:	00005617          	auipc	a2,0x5
ffffffffc0201358:	ed460613          	addi	a2,a2,-300 # ffffffffc0206228 <commands+0x800>
ffffffffc020135c:	0dc00593          	li	a1,220
ffffffffc0201360:	00005517          	auipc	a0,0x5
ffffffffc0201364:	ee050513          	addi	a0,a0,-288 # ffffffffc0206240 <commands+0x818>
ffffffffc0201368:	926ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020136c:	00005697          	auipc	a3,0x5
ffffffffc0201370:	fd468693          	addi	a3,a3,-44 # ffffffffc0206340 <commands+0x918>
ffffffffc0201374:	00005617          	auipc	a2,0x5
ffffffffc0201378:	eb460613          	addi	a2,a2,-332 # ffffffffc0206228 <commands+0x800>
ffffffffc020137c:	0de00593          	li	a1,222
ffffffffc0201380:	00005517          	auipc	a0,0x5
ffffffffc0201384:	ec050513          	addi	a0,a0,-320 # ffffffffc0206240 <commands+0x818>
ffffffffc0201388:	906ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc020138c:	00005697          	auipc	a3,0x5
ffffffffc0201390:	03c68693          	addi	a3,a3,60 # ffffffffc02063c8 <commands+0x9a0>
ffffffffc0201394:	00005617          	auipc	a2,0x5
ffffffffc0201398:	e9460613          	addi	a2,a2,-364 # ffffffffc0206228 <commands+0x800>
ffffffffc020139c:	0f700593          	li	a1,247
ffffffffc02013a0:	00005517          	auipc	a0,0x5
ffffffffc02013a4:	ea050513          	addi	a0,a0,-352 # ffffffffc0206240 <commands+0x818>
ffffffffc02013a8:	8e6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013ac:	00005697          	auipc	a3,0x5
ffffffffc02013b0:	ecc68693          	addi	a3,a3,-308 # ffffffffc0206278 <commands+0x850>
ffffffffc02013b4:	00005617          	auipc	a2,0x5
ffffffffc02013b8:	e7460613          	addi	a2,a2,-396 # ffffffffc0206228 <commands+0x800>
ffffffffc02013bc:	0f000593          	li	a1,240
ffffffffc02013c0:	00005517          	auipc	a0,0x5
ffffffffc02013c4:	e8050513          	addi	a0,a0,-384 # ffffffffc0206240 <commands+0x818>
ffffffffc02013c8:	8c6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02013cc:	00005697          	auipc	a3,0x5
ffffffffc02013d0:	fec68693          	addi	a3,a3,-20 # ffffffffc02063b8 <commands+0x990>
ffffffffc02013d4:	00005617          	auipc	a2,0x5
ffffffffc02013d8:	e5460613          	addi	a2,a2,-428 # ffffffffc0206228 <commands+0x800>
ffffffffc02013dc:	0ee00593          	li	a1,238
ffffffffc02013e0:	00005517          	auipc	a0,0x5
ffffffffc02013e4:	e6050513          	addi	a0,a0,-416 # ffffffffc0206240 <commands+0x818>
ffffffffc02013e8:	8a6ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013ec:	00005697          	auipc	a3,0x5
ffffffffc02013f0:	fb468693          	addi	a3,a3,-76 # ffffffffc02063a0 <commands+0x978>
ffffffffc02013f4:	00005617          	auipc	a2,0x5
ffffffffc02013f8:	e3460613          	addi	a2,a2,-460 # ffffffffc0206228 <commands+0x800>
ffffffffc02013fc:	0e900593          	li	a1,233
ffffffffc0201400:	00005517          	auipc	a0,0x5
ffffffffc0201404:	e4050513          	addi	a0,a0,-448 # ffffffffc0206240 <commands+0x818>
ffffffffc0201408:	886ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020140c:	00005697          	auipc	a3,0x5
ffffffffc0201410:	f7468693          	addi	a3,a3,-140 # ffffffffc0206380 <commands+0x958>
ffffffffc0201414:	00005617          	auipc	a2,0x5
ffffffffc0201418:	e1460613          	addi	a2,a2,-492 # ffffffffc0206228 <commands+0x800>
ffffffffc020141c:	0e000593          	li	a1,224
ffffffffc0201420:	00005517          	auipc	a0,0x5
ffffffffc0201424:	e2050513          	addi	a0,a0,-480 # ffffffffc0206240 <commands+0x818>
ffffffffc0201428:	866ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020142c:	00005697          	auipc	a3,0x5
ffffffffc0201430:	fe468693          	addi	a3,a3,-28 # ffffffffc0206410 <commands+0x9e8>
ffffffffc0201434:	00005617          	auipc	a2,0x5
ffffffffc0201438:	df460613          	addi	a2,a2,-524 # ffffffffc0206228 <commands+0x800>
ffffffffc020143c:	11800593          	li	a1,280
ffffffffc0201440:	00005517          	auipc	a0,0x5
ffffffffc0201444:	e0050513          	addi	a0,a0,-512 # ffffffffc0206240 <commands+0x818>
ffffffffc0201448:	846ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020144c:	00005697          	auipc	a3,0x5
ffffffffc0201450:	fb468693          	addi	a3,a3,-76 # ffffffffc0206400 <commands+0x9d8>
ffffffffc0201454:	00005617          	auipc	a2,0x5
ffffffffc0201458:	dd460613          	addi	a2,a2,-556 # ffffffffc0206228 <commands+0x800>
ffffffffc020145c:	0fd00593          	li	a1,253
ffffffffc0201460:	00005517          	auipc	a0,0x5
ffffffffc0201464:	de050513          	addi	a0,a0,-544 # ffffffffc0206240 <commands+0x818>
ffffffffc0201468:	826ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020146c:	00005697          	auipc	a3,0x5
ffffffffc0201470:	f3468693          	addi	a3,a3,-204 # ffffffffc02063a0 <commands+0x978>
ffffffffc0201474:	00005617          	auipc	a2,0x5
ffffffffc0201478:	db460613          	addi	a2,a2,-588 # ffffffffc0206228 <commands+0x800>
ffffffffc020147c:	0fb00593          	li	a1,251
ffffffffc0201480:	00005517          	auipc	a0,0x5
ffffffffc0201484:	dc050513          	addi	a0,a0,-576 # ffffffffc0206240 <commands+0x818>
ffffffffc0201488:	806ff0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020148c:	00005697          	auipc	a3,0x5
ffffffffc0201490:	f5468693          	addi	a3,a3,-172 # ffffffffc02063e0 <commands+0x9b8>
ffffffffc0201494:	00005617          	auipc	a2,0x5
ffffffffc0201498:	d9460613          	addi	a2,a2,-620 # ffffffffc0206228 <commands+0x800>
ffffffffc020149c:	0fa00593          	li	a1,250
ffffffffc02014a0:	00005517          	auipc	a0,0x5
ffffffffc02014a4:	da050513          	addi	a0,a0,-608 # ffffffffc0206240 <commands+0x818>
ffffffffc02014a8:	fe7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014ac:	00005697          	auipc	a3,0x5
ffffffffc02014b0:	dcc68693          	addi	a3,a3,-564 # ffffffffc0206278 <commands+0x850>
ffffffffc02014b4:	00005617          	auipc	a2,0x5
ffffffffc02014b8:	d7460613          	addi	a2,a2,-652 # ffffffffc0206228 <commands+0x800>
ffffffffc02014bc:	0d700593          	li	a1,215
ffffffffc02014c0:	00005517          	auipc	a0,0x5
ffffffffc02014c4:	d8050513          	addi	a0,a0,-640 # ffffffffc0206240 <commands+0x818>
ffffffffc02014c8:	fc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	ed468693          	addi	a3,a3,-300 # ffffffffc02063a0 <commands+0x978>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	d5460613          	addi	a2,a2,-684 # ffffffffc0206228 <commands+0x800>
ffffffffc02014dc:	0f400593          	li	a1,244
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	d6050513          	addi	a0,a0,-672 # ffffffffc0206240 <commands+0x818>
ffffffffc02014e8:	fa7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	dcc68693          	addi	a3,a3,-564 # ffffffffc02062b8 <commands+0x890>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	d3460613          	addi	a2,a2,-716 # ffffffffc0206228 <commands+0x800>
ffffffffc02014fc:	0f200593          	li	a1,242
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	d4050513          	addi	a0,a0,-704 # ffffffffc0206240 <commands+0x818>
ffffffffc0201508:	f87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	d8c68693          	addi	a3,a3,-628 # ffffffffc0206298 <commands+0x870>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	d1460613          	addi	a2,a2,-748 # ffffffffc0206228 <commands+0x800>
ffffffffc020151c:	0f100593          	li	a1,241
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	d2050513          	addi	a0,a0,-736 # ffffffffc0206240 <commands+0x818>
ffffffffc0201528:	f67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	d8c68693          	addi	a3,a3,-628 # ffffffffc02062b8 <commands+0x890>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	cf460613          	addi	a2,a2,-780 # ffffffffc0206228 <commands+0x800>
ffffffffc020153c:	0d900593          	li	a1,217
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	d0050513          	addi	a0,a0,-768 # ffffffffc0206240 <commands+0x818>
ffffffffc0201548:	f47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	01468693          	addi	a3,a3,20 # ffffffffc0206560 <commands+0xb38>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	cd460613          	addi	a2,a2,-812 # ffffffffc0206228 <commands+0x800>
ffffffffc020155c:	14600593          	li	a1,326
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	ce050513          	addi	a0,a0,-800 # ffffffffc0206240 <commands+0x818>
ffffffffc0201568:	f27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	e9468693          	addi	a3,a3,-364 # ffffffffc0206400 <commands+0x9d8>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	cb460613          	addi	a2,a2,-844 # ffffffffc0206228 <commands+0x800>
ffffffffc020157c:	13a00593          	li	a1,314
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	cc050513          	addi	a0,a0,-832 # ffffffffc0206240 <commands+0x818>
ffffffffc0201588:	f07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	e1468693          	addi	a3,a3,-492 # ffffffffc02063a0 <commands+0x978>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	c9460613          	addi	a2,a2,-876 # ffffffffc0206228 <commands+0x800>
ffffffffc020159c:	13800593          	li	a1,312
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	ca050513          	addi	a0,a0,-864 # ffffffffc0206240 <commands+0x818>
ffffffffc02015a8:	ee7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	db468693          	addi	a3,a3,-588 # ffffffffc0206360 <commands+0x938>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	c7460613          	addi	a2,a2,-908 # ffffffffc0206228 <commands+0x800>
ffffffffc02015bc:	0df00593          	li	a1,223
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	c8050513          	addi	a0,a0,-896 # ffffffffc0206240 <commands+0x818>
ffffffffc02015c8:	ec7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	f5468693          	addi	a3,a3,-172 # ffffffffc0206520 <commands+0xaf8>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	c5460613          	addi	a2,a2,-940 # ffffffffc0206228 <commands+0x800>
ffffffffc02015dc:	13200593          	li	a1,306
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	c6050513          	addi	a0,a0,-928 # ffffffffc0206240 <commands+0x818>
ffffffffc02015e8:	ea7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	f1468693          	addi	a3,a3,-236 # ffffffffc0206500 <commands+0xad8>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	c3460613          	addi	a2,a2,-972 # ffffffffc0206228 <commands+0x800>
ffffffffc02015fc:	13000593          	li	a1,304
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	c4050513          	addi	a0,a0,-960 # ffffffffc0206240 <commands+0x818>
ffffffffc0201608:	e87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	ecc68693          	addi	a3,a3,-308 # ffffffffc02064d8 <commands+0xab0>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	c1460613          	addi	a2,a2,-1004 # ffffffffc0206228 <commands+0x800>
ffffffffc020161c:	12e00593          	li	a1,302
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	c2050513          	addi	a0,a0,-992 # ffffffffc0206240 <commands+0x818>
ffffffffc0201628:	e67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	e8468693          	addi	a3,a3,-380 # ffffffffc02064b0 <commands+0xa88>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	bf460613          	addi	a2,a2,-1036 # ffffffffc0206228 <commands+0x800>
ffffffffc020163c:	12d00593          	li	a1,301
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	c0050513          	addi	a0,a0,-1024 # ffffffffc0206240 <commands+0x818>
ffffffffc0201648:	e47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	e5468693          	addi	a3,a3,-428 # ffffffffc02064a0 <commands+0xa78>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	bd460613          	addi	a2,a2,-1068 # ffffffffc0206228 <commands+0x800>
ffffffffc020165c:	12800593          	li	a1,296
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	be050513          	addi	a0,a0,-1056 # ffffffffc0206240 <commands+0x818>
ffffffffc0201668:	e27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	d3468693          	addi	a3,a3,-716 # ffffffffc02063a0 <commands+0x978>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	bb460613          	addi	a2,a2,-1100 # ffffffffc0206228 <commands+0x800>
ffffffffc020167c:	12700593          	li	a1,295
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	bc050513          	addi	a0,a0,-1088 # ffffffffc0206240 <commands+0x818>
ffffffffc0201688:	e07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	df468693          	addi	a3,a3,-524 # ffffffffc0206480 <commands+0xa58>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	b9460613          	addi	a2,a2,-1132 # ffffffffc0206228 <commands+0x800>
ffffffffc020169c:	12600593          	li	a1,294
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	ba050513          	addi	a0,a0,-1120 # ffffffffc0206240 <commands+0x818>
ffffffffc02016a8:	de7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	da468693          	addi	a3,a3,-604 # ffffffffc0206450 <commands+0xa28>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	b7460613          	addi	a2,a2,-1164 # ffffffffc0206228 <commands+0x800>
ffffffffc02016bc:	12500593          	li	a1,293
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	b8050513          	addi	a0,a0,-1152 # ffffffffc0206240 <commands+0x818>
ffffffffc02016c8:	dc7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	d6c68693          	addi	a3,a3,-660 # ffffffffc0206438 <commands+0xa10>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	b5460613          	addi	a2,a2,-1196 # ffffffffc0206228 <commands+0x800>
ffffffffc02016dc:	12400593          	li	a1,292
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	b6050513          	addi	a0,a0,-1184 # ffffffffc0206240 <commands+0x818>
ffffffffc02016e8:	da7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	cb468693          	addi	a3,a3,-844 # ffffffffc02063a0 <commands+0x978>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	b3460613          	addi	a2,a2,-1228 # ffffffffc0206228 <commands+0x800>
ffffffffc02016fc:	11e00593          	li	a1,286
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	b4050513          	addi	a0,a0,-1216 # ffffffffc0206240 <commands+0x818>
ffffffffc0201708:	d87fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	d1468693          	addi	a3,a3,-748 # ffffffffc0206420 <commands+0x9f8>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	b1460613          	addi	a2,a2,-1260 # ffffffffc0206228 <commands+0x800>
ffffffffc020171c:	11900593          	li	a1,281
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	b2050513          	addi	a0,a0,-1248 # ffffffffc0206240 <commands+0x818>
ffffffffc0201728:	d67fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	e1468693          	addi	a3,a3,-492 # ffffffffc0206540 <commands+0xb18>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	af460613          	addi	a2,a2,-1292 # ffffffffc0206228 <commands+0x800>
ffffffffc020173c:	13700593          	li	a1,311
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	b0050513          	addi	a0,a0,-1280 # ffffffffc0206240 <commands+0x818>
ffffffffc0201748:	d47fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc020174c:	00005697          	auipc	a3,0x5
ffffffffc0201750:	e2468693          	addi	a3,a3,-476 # ffffffffc0206570 <commands+0xb48>
ffffffffc0201754:	00005617          	auipc	a2,0x5
ffffffffc0201758:	ad460613          	addi	a2,a2,-1324 # ffffffffc0206228 <commands+0x800>
ffffffffc020175c:	14700593          	li	a1,327
ffffffffc0201760:	00005517          	auipc	a0,0x5
ffffffffc0201764:	ae050513          	addi	a0,a0,-1312 # ffffffffc0206240 <commands+0x818>
ffffffffc0201768:	d27fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc020176c:	00005697          	auipc	a3,0x5
ffffffffc0201770:	aec68693          	addi	a3,a3,-1300 # ffffffffc0206258 <commands+0x830>
ffffffffc0201774:	00005617          	auipc	a2,0x5
ffffffffc0201778:	ab460613          	addi	a2,a2,-1356 # ffffffffc0206228 <commands+0x800>
ffffffffc020177c:	11300593          	li	a1,275
ffffffffc0201780:	00005517          	auipc	a0,0x5
ffffffffc0201784:	ac050513          	addi	a0,a0,-1344 # ffffffffc0206240 <commands+0x818>
ffffffffc0201788:	d07fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020178c:	00005697          	auipc	a3,0x5
ffffffffc0201790:	b0c68693          	addi	a3,a3,-1268 # ffffffffc0206298 <commands+0x870>
ffffffffc0201794:	00005617          	auipc	a2,0x5
ffffffffc0201798:	a9460613          	addi	a2,a2,-1388 # ffffffffc0206228 <commands+0x800>
ffffffffc020179c:	0d800593          	li	a1,216
ffffffffc02017a0:	00005517          	auipc	a0,0x5
ffffffffc02017a4:	aa050513          	addi	a0,a0,-1376 # ffffffffc0206240 <commands+0x818>
ffffffffc02017a8:	ce7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02017ac <default_free_pages>:
{
ffffffffc02017ac:	1141                	addi	sp,sp,-16
ffffffffc02017ae:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017b0:	14058463          	beqz	a1,ffffffffc02018f8 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc02017b4:	00659693          	slli	a3,a1,0x6
ffffffffc02017b8:	96aa                	add	a3,a3,a0
ffffffffc02017ba:	87aa                	mv	a5,a0
ffffffffc02017bc:	02d50263          	beq	a0,a3,ffffffffc02017e0 <default_free_pages+0x34>
ffffffffc02017c0:	6798                	ld	a4,8(a5)
ffffffffc02017c2:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017c4:	10071a63          	bnez	a4,ffffffffc02018d8 <default_free_pages+0x12c>
ffffffffc02017c8:	6798                	ld	a4,8(a5)
ffffffffc02017ca:	8b09                	andi	a4,a4,2
ffffffffc02017cc:	10071663          	bnez	a4,ffffffffc02018d8 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02017d0:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017d4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017d8:	04078793          	addi	a5,a5,64
ffffffffc02017dc:	fed792e3          	bne	a5,a3,ffffffffc02017c0 <default_free_pages+0x14>
    base->property = n;
ffffffffc02017e0:	2581                	sext.w	a1,a1
ffffffffc02017e2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017e4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017e8:	4789                	li	a5,2
ffffffffc02017ea:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017ee:	000a5697          	auipc	a3,0xa5
ffffffffc02017f2:	e5268693          	addi	a3,a3,-430 # ffffffffc02a6640 <free_area>
ffffffffc02017f6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02017f8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02017fa:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02017fe:	9db9                	addw	a1,a1,a4
ffffffffc0201800:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201802:	0ad78463          	beq	a5,a3,ffffffffc02018aa <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201806:	fe878713          	addi	a4,a5,-24
ffffffffc020180a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020180e:	4581                	li	a1,0
            if (base < page)
ffffffffc0201810:	00e56a63          	bltu	a0,a4,ffffffffc0201824 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201814:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201816:	04d70c63          	beq	a4,a3,ffffffffc020186e <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc020181a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc020181c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201820:	fee57ae3          	bgeu	a0,a4,ffffffffc0201814 <default_free_pages+0x68>
ffffffffc0201824:	c199                	beqz	a1,ffffffffc020182a <default_free_pages+0x7e>
ffffffffc0201826:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020182a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020182c:	e390                	sd	a2,0(a5)
ffffffffc020182e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201830:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201832:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc0201834:	00d70d63          	beq	a4,a3,ffffffffc020184e <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201838:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020183c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201840:	02059813          	slli	a6,a1,0x20
ffffffffc0201844:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201848:	97b2                	add	a5,a5,a2
ffffffffc020184a:	02f50c63          	beq	a0,a5,ffffffffc0201882 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020184e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201850:	00d78c63          	beq	a5,a3,ffffffffc0201868 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201854:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201856:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020185a:	02061593          	slli	a1,a2,0x20
ffffffffc020185e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201862:	972a                	add	a4,a4,a0
ffffffffc0201864:	04e68a63          	beq	a3,a4,ffffffffc02018b8 <default_free_pages+0x10c>
}
ffffffffc0201868:	60a2                	ld	ra,8(sp)
ffffffffc020186a:	0141                	addi	sp,sp,16
ffffffffc020186c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020186e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201870:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201872:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201874:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201876:	02d70763          	beq	a4,a3,ffffffffc02018a4 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020187a:	8832                	mv	a6,a2
ffffffffc020187c:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc020187e:	87ba                	mv	a5,a4
ffffffffc0201880:	bf71                	j	ffffffffc020181c <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201882:	491c                	lw	a5,16(a0)
ffffffffc0201884:	9dbd                	addw	a1,a1,a5
ffffffffc0201886:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020188a:	57f5                	li	a5,-3
ffffffffc020188c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201890:	01853803          	ld	a6,24(a0)
ffffffffc0201894:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201896:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201898:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc020189c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020189e:	0105b023          	sd	a6,0(a1)
ffffffffc02018a2:	b77d                	j	ffffffffc0201850 <default_free_pages+0xa4>
ffffffffc02018a4:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc02018a6:	873e                	mv	a4,a5
ffffffffc02018a8:	bf41                	j	ffffffffc0201838 <default_free_pages+0x8c>
}
ffffffffc02018aa:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018ac:	e390                	sd	a2,0(a5)
ffffffffc02018ae:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018b0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018b2:	ed1c                	sd	a5,24(a0)
ffffffffc02018b4:	0141                	addi	sp,sp,16
ffffffffc02018b6:	8082                	ret
            base->property += p->property;
ffffffffc02018b8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018bc:	ff078693          	addi	a3,a5,-16
ffffffffc02018c0:	9e39                	addw	a2,a2,a4
ffffffffc02018c2:	c910                	sw	a2,16(a0)
ffffffffc02018c4:	5775                	li	a4,-3
ffffffffc02018c6:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018ca:	6398                	ld	a4,0(a5)
ffffffffc02018cc:	679c                	ld	a5,8(a5)
}
ffffffffc02018ce:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02018d0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02018d2:	e398                	sd	a4,0(a5)
ffffffffc02018d4:	0141                	addi	sp,sp,16
ffffffffc02018d6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018d8:	00005697          	auipc	a3,0x5
ffffffffc02018dc:	cb068693          	addi	a3,a3,-848 # ffffffffc0206588 <commands+0xb60>
ffffffffc02018e0:	00005617          	auipc	a2,0x5
ffffffffc02018e4:	94860613          	addi	a2,a2,-1720 # ffffffffc0206228 <commands+0x800>
ffffffffc02018e8:	09400593          	li	a1,148
ffffffffc02018ec:	00005517          	auipc	a0,0x5
ffffffffc02018f0:	95450513          	addi	a0,a0,-1708 # ffffffffc0206240 <commands+0x818>
ffffffffc02018f4:	b9bfe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc02018f8:	00005697          	auipc	a3,0x5
ffffffffc02018fc:	c8868693          	addi	a3,a3,-888 # ffffffffc0206580 <commands+0xb58>
ffffffffc0201900:	00005617          	auipc	a2,0x5
ffffffffc0201904:	92860613          	addi	a2,a2,-1752 # ffffffffc0206228 <commands+0x800>
ffffffffc0201908:	09000593          	li	a1,144
ffffffffc020190c:	00005517          	auipc	a0,0x5
ffffffffc0201910:	93450513          	addi	a0,a0,-1740 # ffffffffc0206240 <commands+0x818>
ffffffffc0201914:	b7bfe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201918 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201918:	c941                	beqz	a0,ffffffffc02019a8 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc020191a:	000a5597          	auipc	a1,0xa5
ffffffffc020191e:	d2658593          	addi	a1,a1,-730 # ffffffffc02a6640 <free_area>
ffffffffc0201922:	0105a803          	lw	a6,16(a1)
ffffffffc0201926:	872a                	mv	a4,a0
ffffffffc0201928:	02081793          	slli	a5,a6,0x20
ffffffffc020192c:	9381                	srli	a5,a5,0x20
ffffffffc020192e:	00a7ee63          	bltu	a5,a0,ffffffffc020194a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201932:	87ae                	mv	a5,a1
ffffffffc0201934:	a801                	j	ffffffffc0201944 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc0201936:	ff87a683          	lw	a3,-8(a5)
ffffffffc020193a:	02069613          	slli	a2,a3,0x20
ffffffffc020193e:	9201                	srli	a2,a2,0x20
ffffffffc0201940:	00e67763          	bgeu	a2,a4,ffffffffc020194e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201944:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201946:	feb798e3          	bne	a5,a1,ffffffffc0201936 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020194a:	4501                	li	a0,0
}
ffffffffc020194c:	8082                	ret
    return listelm->prev;
ffffffffc020194e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201952:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201956:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020195a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc020195e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201962:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc0201966:	02c77863          	bgeu	a4,a2,ffffffffc0201996 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020196a:	071a                	slli	a4,a4,0x6
ffffffffc020196c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020196e:	41c686bb          	subw	a3,a3,t3
ffffffffc0201972:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201974:	00870613          	addi	a2,a4,8
ffffffffc0201978:	4689                	li	a3,2
ffffffffc020197a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020197e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201982:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201986:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020198a:	e290                	sd	a2,0(a3)
ffffffffc020198c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201990:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0201992:	01173c23          	sd	a7,24(a4)
ffffffffc0201996:	41c8083b          	subw	a6,a6,t3
ffffffffc020199a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020199e:	5775                	li	a4,-3
ffffffffc02019a0:	17c1                	addi	a5,a5,-16
ffffffffc02019a2:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02019a6:	8082                	ret
{
ffffffffc02019a8:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02019aa:	00005697          	auipc	a3,0x5
ffffffffc02019ae:	bd668693          	addi	a3,a3,-1066 # ffffffffc0206580 <commands+0xb58>
ffffffffc02019b2:	00005617          	auipc	a2,0x5
ffffffffc02019b6:	87660613          	addi	a2,a2,-1930 # ffffffffc0206228 <commands+0x800>
ffffffffc02019ba:	06c00593          	li	a1,108
ffffffffc02019be:	00005517          	auipc	a0,0x5
ffffffffc02019c2:	88250513          	addi	a0,a0,-1918 # ffffffffc0206240 <commands+0x818>
{
ffffffffc02019c6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019c8:	ac7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02019cc <default_init_memmap>:
{
ffffffffc02019cc:	1141                	addi	sp,sp,-16
ffffffffc02019ce:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019d0:	c5f1                	beqz	a1,ffffffffc0201a9c <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc02019d2:	00659693          	slli	a3,a1,0x6
ffffffffc02019d6:	96aa                	add	a3,a3,a0
ffffffffc02019d8:	87aa                	mv	a5,a0
ffffffffc02019da:	00d50f63          	beq	a0,a3,ffffffffc02019f8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019de:	6798                	ld	a4,8(a5)
ffffffffc02019e0:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02019e2:	cf49                	beqz	a4,ffffffffc0201a7c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02019e4:	0007a823          	sw	zero,16(a5)
ffffffffc02019e8:	0007b423          	sd	zero,8(a5)
ffffffffc02019ec:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019f0:	04078793          	addi	a5,a5,64
ffffffffc02019f4:	fed795e3          	bne	a5,a3,ffffffffc02019de <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019f8:	2581                	sext.w	a1,a1
ffffffffc02019fa:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019fc:	4789                	li	a5,2
ffffffffc02019fe:	00850713          	addi	a4,a0,8
ffffffffc0201a02:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a06:	000a5697          	auipc	a3,0xa5
ffffffffc0201a0a:	c3a68693          	addi	a3,a3,-966 # ffffffffc02a6640 <free_area>
ffffffffc0201a0e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201a10:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a12:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201a16:	9db9                	addw	a1,a1,a4
ffffffffc0201a18:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a1a:	04d78a63          	beq	a5,a3,ffffffffc0201a6e <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a1e:	fe878713          	addi	a4,a5,-24
ffffffffc0201a22:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc0201a26:	4581                	li	a1,0
            if (base < page)
ffffffffc0201a28:	00e56a63          	bltu	a0,a4,ffffffffc0201a3c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a2c:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a2e:	02d70263          	beq	a4,a3,ffffffffc0201a52 <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc0201a32:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a34:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a38:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a2c <default_init_memmap+0x60>
ffffffffc0201a3c:	c199                	beqz	a1,ffffffffc0201a42 <default_init_memmap+0x76>
ffffffffc0201a3e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a42:	6398                	ld	a4,0(a5)
}
ffffffffc0201a44:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a46:	e390                	sd	a2,0(a5)
ffffffffc0201a48:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201a4a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a4c:	ed18                	sd	a4,24(a0)
ffffffffc0201a4e:	0141                	addi	sp,sp,16
ffffffffc0201a50:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a52:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a54:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a56:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a58:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a5a:	00d70663          	beq	a4,a3,ffffffffc0201a66 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201a5e:	8832                	mv	a6,a2
ffffffffc0201a60:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc0201a62:	87ba                	mv	a5,a4
ffffffffc0201a64:	bfc1                	j	ffffffffc0201a34 <default_init_memmap+0x68>
}
ffffffffc0201a66:	60a2                	ld	ra,8(sp)
ffffffffc0201a68:	e290                	sd	a2,0(a3)
ffffffffc0201a6a:	0141                	addi	sp,sp,16
ffffffffc0201a6c:	8082                	ret
ffffffffc0201a6e:	60a2                	ld	ra,8(sp)
ffffffffc0201a70:	e390                	sd	a2,0(a5)
ffffffffc0201a72:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a74:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a76:	ed1c                	sd	a5,24(a0)
ffffffffc0201a78:	0141                	addi	sp,sp,16
ffffffffc0201a7a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a7c:	00005697          	auipc	a3,0x5
ffffffffc0201a80:	b3468693          	addi	a3,a3,-1228 # ffffffffc02065b0 <commands+0xb88>
ffffffffc0201a84:	00004617          	auipc	a2,0x4
ffffffffc0201a88:	7a460613          	addi	a2,a2,1956 # ffffffffc0206228 <commands+0x800>
ffffffffc0201a8c:	04b00593          	li	a1,75
ffffffffc0201a90:	00004517          	auipc	a0,0x4
ffffffffc0201a94:	7b050513          	addi	a0,a0,1968 # ffffffffc0206240 <commands+0x818>
ffffffffc0201a98:	9f7fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a9c:	00005697          	auipc	a3,0x5
ffffffffc0201aa0:	ae468693          	addi	a3,a3,-1308 # ffffffffc0206580 <commands+0xb58>
ffffffffc0201aa4:	00004617          	auipc	a2,0x4
ffffffffc0201aa8:	78460613          	addi	a2,a2,1924 # ffffffffc0206228 <commands+0x800>
ffffffffc0201aac:	04700593          	li	a1,71
ffffffffc0201ab0:	00004517          	auipc	a0,0x4
ffffffffc0201ab4:	79050513          	addi	a0,a0,1936 # ffffffffc0206240 <commands+0x818>
ffffffffc0201ab8:	9d7fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201abc <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201abc:	c94d                	beqz	a0,ffffffffc0201b6e <slob_free+0xb2>
{
ffffffffc0201abe:	1141                	addi	sp,sp,-16
ffffffffc0201ac0:	e022                	sd	s0,0(sp)
ffffffffc0201ac2:	e406                	sd	ra,8(sp)
ffffffffc0201ac4:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201ac6:	e9c1                	bnez	a1,ffffffffc0201b56 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ac8:	100027f3          	csrr	a5,sstatus
ffffffffc0201acc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ace:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ad0:	ebd9                	bnez	a5,ffffffffc0201b66 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ad2:	000a4617          	auipc	a2,0xa4
ffffffffc0201ad6:	75e60613          	addi	a2,a2,1886 # ffffffffc02a6230 <slobfree>
ffffffffc0201ada:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201adc:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ade:	679c                	ld	a5,8(a5)
ffffffffc0201ae0:	02877a63          	bgeu	a4,s0,ffffffffc0201b14 <slob_free+0x58>
ffffffffc0201ae4:	00f46463          	bltu	s0,a5,ffffffffc0201aec <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ae8:	fef76ae3          	bltu	a4,a5,ffffffffc0201adc <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201aec:	400c                	lw	a1,0(s0)
ffffffffc0201aee:	00459693          	slli	a3,a1,0x4
ffffffffc0201af2:	96a2                	add	a3,a3,s0
ffffffffc0201af4:	02d78a63          	beq	a5,a3,ffffffffc0201b28 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201af8:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201afa:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201afc:	00469793          	slli	a5,a3,0x4
ffffffffc0201b00:	97ba                	add	a5,a5,a4
ffffffffc0201b02:	02f40e63          	beq	s0,a5,ffffffffc0201b3e <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201b06:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201b08:	e218                	sd	a4,0(a2)
    if (flag)
ffffffffc0201b0a:	e129                	bnez	a0,ffffffffc0201b4c <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b0c:	60a2                	ld	ra,8(sp)
ffffffffc0201b0e:	6402                	ld	s0,0(sp)
ffffffffc0201b10:	0141                	addi	sp,sp,16
ffffffffc0201b12:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b14:	fcf764e3          	bltu	a4,a5,ffffffffc0201adc <slob_free+0x20>
ffffffffc0201b18:	fcf472e3          	bgeu	s0,a5,ffffffffc0201adc <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201b1c:	400c                	lw	a1,0(s0)
ffffffffc0201b1e:	00459693          	slli	a3,a1,0x4
ffffffffc0201b22:	96a2                	add	a3,a3,s0
ffffffffc0201b24:	fcd79ae3          	bne	a5,a3,ffffffffc0201af8 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201b28:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b2a:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b2c:	9db5                	addw	a1,a1,a3
ffffffffc0201b2e:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc0201b30:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201b32:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201b34:	00469793          	slli	a5,a3,0x4
ffffffffc0201b38:	97ba                	add	a5,a5,a4
ffffffffc0201b3a:	fcf416e3          	bne	s0,a5,ffffffffc0201b06 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201b3e:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201b40:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201b42:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201b44:	9ebd                	addw	a3,a3,a5
ffffffffc0201b46:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201b48:	e70c                	sd	a1,8(a4)
ffffffffc0201b4a:	d169                	beqz	a0,ffffffffc0201b0c <slob_free+0x50>
}
ffffffffc0201b4c:	6402                	ld	s0,0(sp)
ffffffffc0201b4e:	60a2                	ld	ra,8(sp)
ffffffffc0201b50:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201b52:	e5dfe06f          	j	ffffffffc02009ae <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201b56:	25bd                	addiw	a1,a1,15
ffffffffc0201b58:	8191                	srli	a1,a1,0x4
ffffffffc0201b5a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b5c:	100027f3          	csrr	a5,sstatus
ffffffffc0201b60:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b62:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b64:	d7bd                	beqz	a5,ffffffffc0201ad2 <slob_free+0x16>
        intr_disable();
ffffffffc0201b66:	e4ffe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201b6a:	4505                	li	a0,1
ffffffffc0201b6c:	b79d                	j	ffffffffc0201ad2 <slob_free+0x16>
ffffffffc0201b6e:	8082                	ret

ffffffffc0201b70 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b70:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b72:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b74:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b78:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b7a:	352000ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
	if (!page)
ffffffffc0201b7e:	c91d                	beqz	a0,ffffffffc0201bb4 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b80:	000a9697          	auipc	a3,0xa9
ffffffffc0201b84:	b306b683          	ld	a3,-1232(a3) # ffffffffc02aa6b0 <pages>
ffffffffc0201b88:	8d15                	sub	a0,a0,a3
ffffffffc0201b8a:	8519                	srai	a0,a0,0x6
ffffffffc0201b8c:	00006697          	auipc	a3,0x6
ffffffffc0201b90:	d446b683          	ld	a3,-700(a3) # ffffffffc02078d0 <nbase>
ffffffffc0201b94:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201b96:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b9a:	83b1                	srli	a5,a5,0xc
ffffffffc0201b9c:	000a9717          	auipc	a4,0xa9
ffffffffc0201ba0:	b0c73703          	ld	a4,-1268(a4) # ffffffffc02aa6a8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ba4:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201ba6:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bba <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201baa:	000a9697          	auipc	a3,0xa9
ffffffffc0201bae:	b166b683          	ld	a3,-1258(a3) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0201bb2:	9536                	add	a0,a0,a3
}
ffffffffc0201bb4:	60a2                	ld	ra,8(sp)
ffffffffc0201bb6:	0141                	addi	sp,sp,16
ffffffffc0201bb8:	8082                	ret
ffffffffc0201bba:	86aa                	mv	a3,a0
ffffffffc0201bbc:	00005617          	auipc	a2,0x5
ffffffffc0201bc0:	a5460613          	addi	a2,a2,-1452 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0201bc4:	07100593          	li	a1,113
ffffffffc0201bc8:	00005517          	auipc	a0,0x5
ffffffffc0201bcc:	a7050513          	addi	a0,a0,-1424 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0201bd0:	8bffe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201bd4 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201bd4:	1101                	addi	sp,sp,-32
ffffffffc0201bd6:	ec06                	sd	ra,24(sp)
ffffffffc0201bd8:	e822                	sd	s0,16(sp)
ffffffffc0201bda:	e426                	sd	s1,8(sp)
ffffffffc0201bdc:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bde:	01050713          	addi	a4,a0,16
ffffffffc0201be2:	6785                	lui	a5,0x1
ffffffffc0201be4:	0cf77363          	bgeu	a4,a5,ffffffffc0201caa <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201be8:	00f50493          	addi	s1,a0,15
ffffffffc0201bec:	8091                	srli	s1,s1,0x4
ffffffffc0201bee:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bf0:	10002673          	csrr	a2,sstatus
ffffffffc0201bf4:	8a09                	andi	a2,a2,2
ffffffffc0201bf6:	e25d                	bnez	a2,ffffffffc0201c9c <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201bf8:	000a4917          	auipc	s2,0xa4
ffffffffc0201bfc:	63890913          	addi	s2,s2,1592 # ffffffffc02a6230 <slobfree>
ffffffffc0201c00:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c04:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201c06:	4398                	lw	a4,0(a5)
ffffffffc0201c08:	08975e63          	bge	a4,s1,ffffffffc0201ca4 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201c0c:	00f68b63          	beq	a3,a5,ffffffffc0201c22 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c10:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c12:	4018                	lw	a4,0(s0)
ffffffffc0201c14:	02975a63          	bge	a4,s1,ffffffffc0201c48 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201c18:	00093683          	ld	a3,0(s2)
ffffffffc0201c1c:	87a2                	mv	a5,s0
ffffffffc0201c1e:	fef699e3          	bne	a3,a5,ffffffffc0201c10 <slob_alloc.constprop.0+0x3c>
    if (flag)
ffffffffc0201c22:	ee31                	bnez	a2,ffffffffc0201c7e <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c24:	4501                	li	a0,0
ffffffffc0201c26:	f4bff0ef          	jal	ra,ffffffffc0201b70 <__slob_get_free_pages.constprop.0>
ffffffffc0201c2a:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201c2c:	cd05                	beqz	a0,ffffffffc0201c64 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c2e:	6585                	lui	a1,0x1
ffffffffc0201c30:	e8dff0ef          	jal	ra,ffffffffc0201abc <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c34:	10002673          	csrr	a2,sstatus
ffffffffc0201c38:	8a09                	andi	a2,a2,2
ffffffffc0201c3a:	ee05                	bnez	a2,ffffffffc0201c72 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201c3c:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c40:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc0201c42:	4018                	lw	a4,0(s0)
ffffffffc0201c44:	fc974ae3          	blt	a4,s1,ffffffffc0201c18 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c48:	04e48763          	beq	s1,a4,ffffffffc0201c96 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201c4c:	00449693          	slli	a3,s1,0x4
ffffffffc0201c50:	96a2                	add	a3,a3,s0
ffffffffc0201c52:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201c54:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201c56:	9f05                	subw	a4,a4,s1
ffffffffc0201c58:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201c5a:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201c5c:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201c5e:	00f93023          	sd	a5,0(s2)
    if (flag)
ffffffffc0201c62:	e20d                	bnez	a2,ffffffffc0201c84 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201c64:	60e2                	ld	ra,24(sp)
ffffffffc0201c66:	8522                	mv	a0,s0
ffffffffc0201c68:	6442                	ld	s0,16(sp)
ffffffffc0201c6a:	64a2                	ld	s1,8(sp)
ffffffffc0201c6c:	6902                	ld	s2,0(sp)
ffffffffc0201c6e:	6105                	addi	sp,sp,32
ffffffffc0201c70:	8082                	ret
        intr_disable();
ffffffffc0201c72:	d43fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
			cur = slobfree;
ffffffffc0201c76:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201c7a:	4605                	li	a2,1
ffffffffc0201c7c:	b7d1                	j	ffffffffc0201c40 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201c7e:	d31fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201c82:	b74d                	j	ffffffffc0201c24 <slob_alloc.constprop.0+0x50>
ffffffffc0201c84:	d2bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
}
ffffffffc0201c88:	60e2                	ld	ra,24(sp)
ffffffffc0201c8a:	8522                	mv	a0,s0
ffffffffc0201c8c:	6442                	ld	s0,16(sp)
ffffffffc0201c8e:	64a2                	ld	s1,8(sp)
ffffffffc0201c90:	6902                	ld	s2,0(sp)
ffffffffc0201c92:	6105                	addi	sp,sp,32
ffffffffc0201c94:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c96:	6418                	ld	a4,8(s0)
ffffffffc0201c98:	e798                	sd	a4,8(a5)
ffffffffc0201c9a:	b7d1                	j	ffffffffc0201c5e <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201c9c:	d19fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0201ca0:	4605                	li	a2,1
ffffffffc0201ca2:	bf99                	j	ffffffffc0201bf8 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201ca4:	843e                	mv	s0,a5
ffffffffc0201ca6:	87b6                	mv	a5,a3
ffffffffc0201ca8:	b745                	j	ffffffffc0201c48 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201caa:	00005697          	auipc	a3,0x5
ffffffffc0201cae:	99e68693          	addi	a3,a3,-1634 # ffffffffc0206648 <default_pmm_manager+0x70>
ffffffffc0201cb2:	00004617          	auipc	a2,0x4
ffffffffc0201cb6:	57660613          	addi	a2,a2,1398 # ffffffffc0206228 <commands+0x800>
ffffffffc0201cba:	06300593          	li	a1,99
ffffffffc0201cbe:	00005517          	auipc	a0,0x5
ffffffffc0201cc2:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0206668 <default_pmm_manager+0x90>
ffffffffc0201cc6:	fc8fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201cca <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cca:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201ccc:	00005517          	auipc	a0,0x5
ffffffffc0201cd0:	9b450513          	addi	a0,a0,-1612 # ffffffffc0206680 <default_pmm_manager+0xa8>
{
ffffffffc0201cd4:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201cd6:	cbefe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cda:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cdc:	00005517          	auipc	a0,0x5
ffffffffc0201ce0:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206698 <default_pmm_manager+0xc0>
}
ffffffffc0201ce4:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ce6:	caefe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201cea <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201cea:	4501                	li	a0,0
ffffffffc0201cec:	8082                	ret

ffffffffc0201cee <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cee:	1101                	addi	sp,sp,-32
ffffffffc0201cf0:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cf2:	6905                	lui	s2,0x1
{
ffffffffc0201cf4:	e822                	sd	s0,16(sp)
ffffffffc0201cf6:	ec06                	sd	ra,24(sp)
ffffffffc0201cf8:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cfa:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bb1>
{
ffffffffc0201cfe:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d00:	04a7f963          	bgeu	a5,a0,ffffffffc0201d52 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d04:	4561                	li	a0,24
ffffffffc0201d06:	ecfff0ef          	jal	ra,ffffffffc0201bd4 <slob_alloc.constprop.0>
ffffffffc0201d0a:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201d0c:	c929                	beqz	a0,ffffffffc0201d5e <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201d0e:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201d12:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d14:	00f95763          	bge	s2,a5,ffffffffc0201d22 <kmalloc+0x34>
ffffffffc0201d18:	6705                	lui	a4,0x1
ffffffffc0201d1a:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201d1c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d1e:	fef74ee3          	blt	a4,a5,ffffffffc0201d1a <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201d22:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d24:	e4dff0ef          	jal	ra,ffffffffc0201b70 <__slob_get_free_pages.constprop.0>
ffffffffc0201d28:	e488                	sd	a0,8(s1)
ffffffffc0201d2a:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201d2c:	c525                	beqz	a0,ffffffffc0201d94 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d2e:	100027f3          	csrr	a5,sstatus
ffffffffc0201d32:	8b89                	andi	a5,a5,2
ffffffffc0201d34:	ef8d                	bnez	a5,ffffffffc0201d6e <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201d36:	000a9797          	auipc	a5,0xa9
ffffffffc0201d3a:	95a78793          	addi	a5,a5,-1702 # ffffffffc02aa690 <bigblocks>
ffffffffc0201d3e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d40:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d42:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201d44:	60e2                	ld	ra,24(sp)
ffffffffc0201d46:	8522                	mv	a0,s0
ffffffffc0201d48:	6442                	ld	s0,16(sp)
ffffffffc0201d4a:	64a2                	ld	s1,8(sp)
ffffffffc0201d4c:	6902                	ld	s2,0(sp)
ffffffffc0201d4e:	6105                	addi	sp,sp,32
ffffffffc0201d50:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d52:	0541                	addi	a0,a0,16
ffffffffc0201d54:	e81ff0ef          	jal	ra,ffffffffc0201bd4 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d58:	01050413          	addi	s0,a0,16
ffffffffc0201d5c:	f565                	bnez	a0,ffffffffc0201d44 <kmalloc+0x56>
ffffffffc0201d5e:	4401                	li	s0,0
}
ffffffffc0201d60:	60e2                	ld	ra,24(sp)
ffffffffc0201d62:	8522                	mv	a0,s0
ffffffffc0201d64:	6442                	ld	s0,16(sp)
ffffffffc0201d66:	64a2                	ld	s1,8(sp)
ffffffffc0201d68:	6902                	ld	s2,0(sp)
ffffffffc0201d6a:	6105                	addi	sp,sp,32
ffffffffc0201d6c:	8082                	ret
        intr_disable();
ffffffffc0201d6e:	c47fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d72:	000a9797          	auipc	a5,0xa9
ffffffffc0201d76:	91e78793          	addi	a5,a5,-1762 # ffffffffc02aa690 <bigblocks>
ffffffffc0201d7a:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201d7c:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201d7e:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201d80:	c2ffe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
		return bb->pages;
ffffffffc0201d84:	6480                	ld	s0,8(s1)
}
ffffffffc0201d86:	60e2                	ld	ra,24(sp)
ffffffffc0201d88:	64a2                	ld	s1,8(sp)
ffffffffc0201d8a:	8522                	mv	a0,s0
ffffffffc0201d8c:	6442                	ld	s0,16(sp)
ffffffffc0201d8e:	6902                	ld	s2,0(sp)
ffffffffc0201d90:	6105                	addi	sp,sp,32
ffffffffc0201d92:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d94:	45e1                	li	a1,24
ffffffffc0201d96:	8526                	mv	a0,s1
ffffffffc0201d98:	d25ff0ef          	jal	ra,ffffffffc0201abc <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201d9c:	b765                	j	ffffffffc0201d44 <kmalloc+0x56>

ffffffffc0201d9e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d9e:	c169                	beqz	a0,ffffffffc0201e60 <kfree+0xc2>
{
ffffffffc0201da0:	1101                	addi	sp,sp,-32
ffffffffc0201da2:	e822                	sd	s0,16(sp)
ffffffffc0201da4:	ec06                	sd	ra,24(sp)
ffffffffc0201da6:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201da8:	03451793          	slli	a5,a0,0x34
ffffffffc0201dac:	842a                	mv	s0,a0
ffffffffc0201dae:	e3d9                	bnez	a5,ffffffffc0201e34 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201db0:	100027f3          	csrr	a5,sstatus
ffffffffc0201db4:	8b89                	andi	a5,a5,2
ffffffffc0201db6:	e7d9                	bnez	a5,ffffffffc0201e44 <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201db8:	000a9797          	auipc	a5,0xa9
ffffffffc0201dbc:	8d87b783          	ld	a5,-1832(a5) # ffffffffc02aa690 <bigblocks>
    return 0;
ffffffffc0201dc0:	4601                	li	a2,0
ffffffffc0201dc2:	cbad                	beqz	a5,ffffffffc0201e34 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201dc4:	000a9697          	auipc	a3,0xa9
ffffffffc0201dc8:	8cc68693          	addi	a3,a3,-1844 # ffffffffc02aa690 <bigblocks>
ffffffffc0201dcc:	a021                	j	ffffffffc0201dd4 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dce:	01048693          	addi	a3,s1,16
ffffffffc0201dd2:	c3a5                	beqz	a5,ffffffffc0201e32 <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201dd4:	6798                	ld	a4,8(a5)
ffffffffc0201dd6:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201dd8:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201dda:	fe871ae3          	bne	a4,s0,ffffffffc0201dce <kfree+0x30>
				*last = bb->next;
ffffffffc0201dde:	e29c                	sd	a5,0(a3)
    if (flag)
ffffffffc0201de0:	ee2d                	bnez	a2,ffffffffc0201e5a <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201de2:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201de6:	4098                	lw	a4,0(s1)
ffffffffc0201de8:	08f46963          	bltu	s0,a5,ffffffffc0201e7a <kfree+0xdc>
ffffffffc0201dec:	000a9697          	auipc	a3,0xa9
ffffffffc0201df0:	8d46b683          	ld	a3,-1836(a3) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0201df4:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201df6:	8031                	srli	s0,s0,0xc
ffffffffc0201df8:	000a9797          	auipc	a5,0xa9
ffffffffc0201dfc:	8b07b783          	ld	a5,-1872(a5) # ffffffffc02aa6a8 <npage>
ffffffffc0201e00:	06f47163          	bgeu	s0,a5,ffffffffc0201e62 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e04:	00006517          	auipc	a0,0x6
ffffffffc0201e08:	acc53503          	ld	a0,-1332(a0) # ffffffffc02078d0 <nbase>
ffffffffc0201e0c:	8c09                	sub	s0,s0,a0
ffffffffc0201e0e:	041a                	slli	s0,s0,0x6
	free_pages(kva2page(kva), 1 << order);
ffffffffc0201e10:	000a9517          	auipc	a0,0xa9
ffffffffc0201e14:	8a053503          	ld	a0,-1888(a0) # ffffffffc02aa6b0 <pages>
ffffffffc0201e18:	4585                	li	a1,1
ffffffffc0201e1a:	9522                	add	a0,a0,s0
ffffffffc0201e1c:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201e20:	0ea000ef          	jal	ra,ffffffffc0201f0a <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e24:	6442                	ld	s0,16(sp)
ffffffffc0201e26:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e28:	8526                	mv	a0,s1
}
ffffffffc0201e2a:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e2c:	45e1                	li	a1,24
}
ffffffffc0201e2e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e30:	b171                	j	ffffffffc0201abc <slob_free>
ffffffffc0201e32:	e20d                	bnez	a2,ffffffffc0201e54 <kfree+0xb6>
ffffffffc0201e34:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201e38:	6442                	ld	s0,16(sp)
ffffffffc0201e3a:	60e2                	ld	ra,24(sp)
ffffffffc0201e3c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e3e:	4581                	li	a1,0
}
ffffffffc0201e40:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e42:	b9ad                	j	ffffffffc0201abc <slob_free>
        intr_disable();
ffffffffc0201e44:	b71fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e48:	000a9797          	auipc	a5,0xa9
ffffffffc0201e4c:	8487b783          	ld	a5,-1976(a5) # ffffffffc02aa690 <bigblocks>
        return 1;
ffffffffc0201e50:	4605                	li	a2,1
ffffffffc0201e52:	fbad                	bnez	a5,ffffffffc0201dc4 <kfree+0x26>
        intr_enable();
ffffffffc0201e54:	b5bfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e58:	bff1                	j	ffffffffc0201e34 <kfree+0x96>
ffffffffc0201e5a:	b55fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0201e5e:	b751                	j	ffffffffc0201de2 <kfree+0x44>
ffffffffc0201e60:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e62:	00005617          	auipc	a2,0x5
ffffffffc0201e66:	87e60613          	addi	a2,a2,-1922 # ffffffffc02066e0 <default_pmm_manager+0x108>
ffffffffc0201e6a:	06900593          	li	a1,105
ffffffffc0201e6e:	00004517          	auipc	a0,0x4
ffffffffc0201e72:	7ca50513          	addi	a0,a0,1994 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0201e76:	e18fe0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e7a:	86a2                	mv	a3,s0
ffffffffc0201e7c:	00005617          	auipc	a2,0x5
ffffffffc0201e80:	83c60613          	addi	a2,a2,-1988 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc0201e84:	07700593          	li	a1,119
ffffffffc0201e88:	00004517          	auipc	a0,0x4
ffffffffc0201e8c:	7b050513          	addi	a0,a0,1968 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0201e90:	dfefe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201e94 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e94:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e96:	00005617          	auipc	a2,0x5
ffffffffc0201e9a:	84a60613          	addi	a2,a2,-1974 # ffffffffc02066e0 <default_pmm_manager+0x108>
ffffffffc0201e9e:	06900593          	li	a1,105
ffffffffc0201ea2:	00004517          	auipc	a0,0x4
ffffffffc0201ea6:	79650513          	addi	a0,a0,1942 # ffffffffc0206638 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201eaa:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201eac:	de2fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201eb0 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201eb0:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201eb2:	00005617          	auipc	a2,0x5
ffffffffc0201eb6:	84e60613          	addi	a2,a2,-1970 # ffffffffc0206700 <default_pmm_manager+0x128>
ffffffffc0201eba:	07f00593          	li	a1,127
ffffffffc0201ebe:	00004517          	auipc	a0,0x4
ffffffffc0201ec2:	77a50513          	addi	a0,a0,1914 # ffffffffc0206638 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201ec6:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201ec8:	dc6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0201ecc <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ecc:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed0:	8b89                	andi	a5,a5,2
ffffffffc0201ed2:	e799                	bnez	a5,ffffffffc0201ee0 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ed4:	000a8797          	auipc	a5,0xa8
ffffffffc0201ed8:	7e47b783          	ld	a5,2020(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201edc:	6f9c                	ld	a5,24(a5)
ffffffffc0201ede:	8782                	jr	a5
{
ffffffffc0201ee0:	1141                	addi	sp,sp,-16
ffffffffc0201ee2:	e406                	sd	ra,8(sp)
ffffffffc0201ee4:	e022                	sd	s0,0(sp)
ffffffffc0201ee6:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201ee8:	acdfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eec:	000a8797          	auipc	a5,0xa8
ffffffffc0201ef0:	7cc7b783          	ld	a5,1996(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201ef4:	6f9c                	ld	a5,24(a5)
ffffffffc0201ef6:	8522                	mv	a0,s0
ffffffffc0201ef8:	9782                	jalr	a5
ffffffffc0201efa:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201efc:	ab3fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f00:	60a2                	ld	ra,8(sp)
ffffffffc0201f02:	8522                	mv	a0,s0
ffffffffc0201f04:	6402                	ld	s0,0(sp)
ffffffffc0201f06:	0141                	addi	sp,sp,16
ffffffffc0201f08:	8082                	ret

ffffffffc0201f0a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f0a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f0e:	8b89                	andi	a5,a5,2
ffffffffc0201f10:	e799                	bnez	a5,ffffffffc0201f1e <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f12:	000a8797          	auipc	a5,0xa8
ffffffffc0201f16:	7a67b783          	ld	a5,1958(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201f1a:	739c                	ld	a5,32(a5)
ffffffffc0201f1c:	8782                	jr	a5
{
ffffffffc0201f1e:	1101                	addi	sp,sp,-32
ffffffffc0201f20:	ec06                	sd	ra,24(sp)
ffffffffc0201f22:	e822                	sd	s0,16(sp)
ffffffffc0201f24:	e426                	sd	s1,8(sp)
ffffffffc0201f26:	842a                	mv	s0,a0
ffffffffc0201f28:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201f2a:	a8bfe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f2e:	000a8797          	auipc	a5,0xa8
ffffffffc0201f32:	78a7b783          	ld	a5,1930(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201f36:	739c                	ld	a5,32(a5)
ffffffffc0201f38:	85a6                	mv	a1,s1
ffffffffc0201f3a:	8522                	mv	a0,s0
ffffffffc0201f3c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f3e:	6442                	ld	s0,16(sp)
ffffffffc0201f40:	60e2                	ld	ra,24(sp)
ffffffffc0201f42:	64a2                	ld	s1,8(sp)
ffffffffc0201f44:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f46:	a69fe06f          	j	ffffffffc02009ae <intr_enable>

ffffffffc0201f4a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f4a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f4e:	8b89                	andi	a5,a5,2
ffffffffc0201f50:	e799                	bnez	a5,ffffffffc0201f5e <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f52:	000a8797          	auipc	a5,0xa8
ffffffffc0201f56:	7667b783          	ld	a5,1894(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201f5a:	779c                	ld	a5,40(a5)
ffffffffc0201f5c:	8782                	jr	a5
{
ffffffffc0201f5e:	1141                	addi	sp,sp,-16
ffffffffc0201f60:	e406                	sd	ra,8(sp)
ffffffffc0201f62:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f64:	a51fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f68:	000a8797          	auipc	a5,0xa8
ffffffffc0201f6c:	7507b783          	ld	a5,1872(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201f70:	779c                	ld	a5,40(a5)
ffffffffc0201f72:	9782                	jalr	a5
ffffffffc0201f74:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f76:	a39fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f7a:	60a2                	ld	ra,8(sp)
ffffffffc0201f7c:	8522                	mv	a0,s0
ffffffffc0201f7e:	6402                	ld	s0,0(sp)
ffffffffc0201f80:	0141                	addi	sp,sp,16
ffffffffc0201f82:	8082                	ret

ffffffffc0201f84 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f84:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f88:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201f8c:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f8e:	078e                	slli	a5,a5,0x3
{
ffffffffc0201f90:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f92:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f96:	6094                	ld	a3,0(s1)
{
ffffffffc0201f98:	f04a                	sd	s2,32(sp)
ffffffffc0201f9a:	ec4e                	sd	s3,24(sp)
ffffffffc0201f9c:	e852                	sd	s4,16(sp)
ffffffffc0201f9e:	fc06                	sd	ra,56(sp)
ffffffffc0201fa0:	f822                	sd	s0,48(sp)
ffffffffc0201fa2:	e456                	sd	s5,8(sp)
ffffffffc0201fa4:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201fa6:	0016f793          	andi	a5,a3,1
{
ffffffffc0201faa:	892e                	mv	s2,a1
ffffffffc0201fac:	8a32                	mv	s4,a2
ffffffffc0201fae:	000a8997          	auipc	s3,0xa8
ffffffffc0201fb2:	6fa98993          	addi	s3,s3,1786 # ffffffffc02aa6a8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201fb6:	efbd                	bnez	a5,ffffffffc0202034 <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fb8:	14060c63          	beqz	a2,ffffffffc0202110 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fbc:	100027f3          	csrr	a5,sstatus
ffffffffc0201fc0:	8b89                	andi	a5,a5,2
ffffffffc0201fc2:	14079963          	bnez	a5,ffffffffc0202114 <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fc6:	000a8797          	auipc	a5,0xa8
ffffffffc0201fca:	6f27b783          	ld	a5,1778(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0201fce:	6f9c                	ld	a5,24(a5)
ffffffffc0201fd0:	4505                	li	a0,1
ffffffffc0201fd2:	9782                	jalr	a5
ffffffffc0201fd4:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fd6:	12040d63          	beqz	s0,ffffffffc0202110 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201fda:	000a8b17          	auipc	s6,0xa8
ffffffffc0201fde:	6d6b0b13          	addi	s6,s6,1750 # ffffffffc02aa6b0 <pages>
ffffffffc0201fe2:	000b3503          	ld	a0,0(s6)
ffffffffc0201fe6:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fea:	000a8997          	auipc	s3,0xa8
ffffffffc0201fee:	6be98993          	addi	s3,s3,1726 # ffffffffc02aa6a8 <npage>
ffffffffc0201ff2:	40a40533          	sub	a0,s0,a0
ffffffffc0201ff6:	8519                	srai	a0,a0,0x6
ffffffffc0201ff8:	9556                	add	a0,a0,s5
ffffffffc0201ffa:	0009b703          	ld	a4,0(s3)
ffffffffc0201ffe:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0202002:	4685                	li	a3,1
ffffffffc0202004:	c014                	sw	a3,0(s0)
ffffffffc0202006:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202008:	0532                	slli	a0,a0,0xc
ffffffffc020200a:	16e7f763          	bgeu	a5,a4,ffffffffc0202178 <get_pte+0x1f4>
ffffffffc020200e:	000a8797          	auipc	a5,0xa8
ffffffffc0202012:	6b27b783          	ld	a5,1714(a5) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0202016:	6605                	lui	a2,0x1
ffffffffc0202018:	4581                	li	a1,0
ffffffffc020201a:	953e                	add	a0,a0,a5
ffffffffc020201c:	776030ef          	jal	ra,ffffffffc0205792 <memset>
    return page - pages + nbase;
ffffffffc0202020:	000b3683          	ld	a3,0(s6)
ffffffffc0202024:	40d406b3          	sub	a3,s0,a3
ffffffffc0202028:	8699                	srai	a3,a3,0x6
ffffffffc020202a:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020202c:	06aa                	slli	a3,a3,0xa
ffffffffc020202e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202032:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202034:	77fd                	lui	a5,0xfffff
ffffffffc0202036:	068a                	slli	a3,a3,0x2
ffffffffc0202038:	0009b703          	ld	a4,0(s3)
ffffffffc020203c:	8efd                	and	a3,a3,a5
ffffffffc020203e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202042:	10e7ff63          	bgeu	a5,a4,ffffffffc0202160 <get_pte+0x1dc>
ffffffffc0202046:	000a8a97          	auipc	s5,0xa8
ffffffffc020204a:	67aa8a93          	addi	s5,s5,1658 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc020204e:	000ab403          	ld	s0,0(s5)
ffffffffc0202052:	01595793          	srli	a5,s2,0x15
ffffffffc0202056:	1ff7f793          	andi	a5,a5,511
ffffffffc020205a:	96a2                	add	a3,a3,s0
ffffffffc020205c:	00379413          	slli	s0,a5,0x3
ffffffffc0202060:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202062:	6014                	ld	a3,0(s0)
ffffffffc0202064:	0016f793          	andi	a5,a3,1
ffffffffc0202068:	ebad                	bnez	a5,ffffffffc02020da <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020206a:	0a0a0363          	beqz	s4,ffffffffc0202110 <get_pte+0x18c>
ffffffffc020206e:	100027f3          	csrr	a5,sstatus
ffffffffc0202072:	8b89                	andi	a5,a5,2
ffffffffc0202074:	efcd                	bnez	a5,ffffffffc020212e <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202076:	000a8797          	auipc	a5,0xa8
ffffffffc020207a:	6427b783          	ld	a5,1602(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020207e:	6f9c                	ld	a5,24(a5)
ffffffffc0202080:	4505                	li	a0,1
ffffffffc0202082:	9782                	jalr	a5
ffffffffc0202084:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202086:	c4c9                	beqz	s1,ffffffffc0202110 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0202088:	000a8b17          	auipc	s6,0xa8
ffffffffc020208c:	628b0b13          	addi	s6,s6,1576 # ffffffffc02aa6b0 <pages>
ffffffffc0202090:	000b3503          	ld	a0,0(s6)
ffffffffc0202094:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202098:	0009b703          	ld	a4,0(s3)
ffffffffc020209c:	40a48533          	sub	a0,s1,a0
ffffffffc02020a0:	8519                	srai	a0,a0,0x6
ffffffffc02020a2:	9552                	add	a0,a0,s4
ffffffffc02020a4:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02020a8:	4685                	li	a3,1
ffffffffc02020aa:	c094                	sw	a3,0(s1)
ffffffffc02020ac:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02020ae:	0532                	slli	a0,a0,0xc
ffffffffc02020b0:	0ee7f163          	bgeu	a5,a4,ffffffffc0202192 <get_pte+0x20e>
ffffffffc02020b4:	000ab783          	ld	a5,0(s5)
ffffffffc02020b8:	6605                	lui	a2,0x1
ffffffffc02020ba:	4581                	li	a1,0
ffffffffc02020bc:	953e                	add	a0,a0,a5
ffffffffc02020be:	6d4030ef          	jal	ra,ffffffffc0205792 <memset>
    return page - pages + nbase;
ffffffffc02020c2:	000b3683          	ld	a3,0(s6)
ffffffffc02020c6:	40d486b3          	sub	a3,s1,a3
ffffffffc02020ca:	8699                	srai	a3,a3,0x6
ffffffffc02020cc:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020ce:	06aa                	slli	a3,a3,0xa
ffffffffc02020d0:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020d4:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020d6:	0009b703          	ld	a4,0(s3)
ffffffffc02020da:	068a                	slli	a3,a3,0x2
ffffffffc02020dc:	757d                	lui	a0,0xfffff
ffffffffc02020de:	8ee9                	and	a3,a3,a0
ffffffffc02020e0:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020e4:	06e7f263          	bgeu	a5,a4,ffffffffc0202148 <get_pte+0x1c4>
ffffffffc02020e8:	000ab503          	ld	a0,0(s5)
ffffffffc02020ec:	00c95913          	srli	s2,s2,0xc
ffffffffc02020f0:	1ff97913          	andi	s2,s2,511
ffffffffc02020f4:	96aa                	add	a3,a3,a0
ffffffffc02020f6:	00391513          	slli	a0,s2,0x3
ffffffffc02020fa:	9536                	add	a0,a0,a3
}
ffffffffc02020fc:	70e2                	ld	ra,56(sp)
ffffffffc02020fe:	7442                	ld	s0,48(sp)
ffffffffc0202100:	74a2                	ld	s1,40(sp)
ffffffffc0202102:	7902                	ld	s2,32(sp)
ffffffffc0202104:	69e2                	ld	s3,24(sp)
ffffffffc0202106:	6a42                	ld	s4,16(sp)
ffffffffc0202108:	6aa2                	ld	s5,8(sp)
ffffffffc020210a:	6b02                	ld	s6,0(sp)
ffffffffc020210c:	6121                	addi	sp,sp,64
ffffffffc020210e:	8082                	ret
            return NULL;
ffffffffc0202110:	4501                	li	a0,0
ffffffffc0202112:	b7ed                	j	ffffffffc02020fc <get_pte+0x178>
        intr_disable();
ffffffffc0202114:	8a1fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202118:	000a8797          	auipc	a5,0xa8
ffffffffc020211c:	5a07b783          	ld	a5,1440(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0202120:	6f9c                	ld	a5,24(a5)
ffffffffc0202122:	4505                	li	a0,1
ffffffffc0202124:	9782                	jalr	a5
ffffffffc0202126:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202128:	887fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020212c:	b56d                	j	ffffffffc0201fd6 <get_pte+0x52>
        intr_disable();
ffffffffc020212e:	887fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202132:	000a8797          	auipc	a5,0xa8
ffffffffc0202136:	5867b783          	ld	a5,1414(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020213a:	6f9c                	ld	a5,24(a5)
ffffffffc020213c:	4505                	li	a0,1
ffffffffc020213e:	9782                	jalr	a5
ffffffffc0202140:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0202142:	86dfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202146:	b781                	j	ffffffffc0202086 <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202148:	00004617          	auipc	a2,0x4
ffffffffc020214c:	4c860613          	addi	a2,a2,1224 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0202150:	0fa00593          	li	a1,250
ffffffffc0202154:	00004517          	auipc	a0,0x4
ffffffffc0202158:	5d450513          	addi	a0,a0,1492 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020215c:	b32fe0ef          	jal	ra,ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202160:	00004617          	auipc	a2,0x4
ffffffffc0202164:	4b060613          	addi	a2,a2,1200 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0202168:	0ed00593          	li	a1,237
ffffffffc020216c:	00004517          	auipc	a0,0x4
ffffffffc0202170:	5bc50513          	addi	a0,a0,1468 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202174:	b1afe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202178:	86aa                	mv	a3,a0
ffffffffc020217a:	00004617          	auipc	a2,0x4
ffffffffc020217e:	49660613          	addi	a2,a2,1174 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0202182:	0e900593          	li	a1,233
ffffffffc0202186:	00004517          	auipc	a0,0x4
ffffffffc020218a:	5a250513          	addi	a0,a0,1442 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020218e:	b00fe0ef          	jal	ra,ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202192:	86aa                	mv	a3,a0
ffffffffc0202194:	00004617          	auipc	a2,0x4
ffffffffc0202198:	47c60613          	addi	a2,a2,1148 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc020219c:	0f700593          	li	a1,247
ffffffffc02021a0:	00004517          	auipc	a0,0x4
ffffffffc02021a4:	58850513          	addi	a0,a0,1416 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02021a8:	ae6fe0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02021ac <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021ac:	1141                	addi	sp,sp,-16
ffffffffc02021ae:	e022                	sd	s0,0(sp)
ffffffffc02021b0:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021b2:	4601                	li	a2,0
{
ffffffffc02021b4:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021b6:	dcfff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
    if (ptep_store != NULL)
ffffffffc02021ba:	c011                	beqz	s0,ffffffffc02021be <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021bc:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021be:	c511                	beqz	a0,ffffffffc02021ca <get_page+0x1e>
ffffffffc02021c0:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021c2:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021c4:	0017f713          	andi	a4,a5,1
ffffffffc02021c8:	e709                	bnez	a4,ffffffffc02021d2 <get_page+0x26>
}
ffffffffc02021ca:	60a2                	ld	ra,8(sp)
ffffffffc02021cc:	6402                	ld	s0,0(sp)
ffffffffc02021ce:	0141                	addi	sp,sp,16
ffffffffc02021d0:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02021d2:	078a                	slli	a5,a5,0x2
ffffffffc02021d4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021d6:	000a8717          	auipc	a4,0xa8
ffffffffc02021da:	4d273703          	ld	a4,1234(a4) # ffffffffc02aa6a8 <npage>
ffffffffc02021de:	00e7ff63          	bgeu	a5,a4,ffffffffc02021fc <get_page+0x50>
ffffffffc02021e2:	60a2                	ld	ra,8(sp)
ffffffffc02021e4:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02021e6:	fff80537          	lui	a0,0xfff80
ffffffffc02021ea:	97aa                	add	a5,a5,a0
ffffffffc02021ec:	079a                	slli	a5,a5,0x6
ffffffffc02021ee:	000a8517          	auipc	a0,0xa8
ffffffffc02021f2:	4c253503          	ld	a0,1218(a0) # ffffffffc02aa6b0 <pages>
ffffffffc02021f6:	953e                	add	a0,a0,a5
ffffffffc02021f8:	0141                	addi	sp,sp,16
ffffffffc02021fa:	8082                	ret
ffffffffc02021fc:	c99ff0ef          	jal	ra,ffffffffc0201e94 <pa2page.part.0>

ffffffffc0202200 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202200:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202202:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202206:	f486                	sd	ra,104(sp)
ffffffffc0202208:	f0a2                	sd	s0,96(sp)
ffffffffc020220a:	eca6                	sd	s1,88(sp)
ffffffffc020220c:	e8ca                	sd	s2,80(sp)
ffffffffc020220e:	e4ce                	sd	s3,72(sp)
ffffffffc0202210:	e0d2                	sd	s4,64(sp)
ffffffffc0202212:	fc56                	sd	s5,56(sp)
ffffffffc0202214:	f85a                	sd	s6,48(sp)
ffffffffc0202216:	f45e                	sd	s7,40(sp)
ffffffffc0202218:	f062                	sd	s8,32(sp)
ffffffffc020221a:	ec66                	sd	s9,24(sp)
ffffffffc020221c:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020221e:	17d2                	slli	a5,a5,0x34
ffffffffc0202220:	e3ed                	bnez	a5,ffffffffc0202302 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202222:	002007b7          	lui	a5,0x200
ffffffffc0202226:	842e                	mv	s0,a1
ffffffffc0202228:	0ef5ed63          	bltu	a1,a5,ffffffffc0202322 <unmap_range+0x122>
ffffffffc020222c:	8932                	mv	s2,a2
ffffffffc020222e:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202322 <unmap_range+0x122>
ffffffffc0202232:	4785                	li	a5,1
ffffffffc0202234:	07fe                	slli	a5,a5,0x1f
ffffffffc0202236:	0ec7e663          	bltu	a5,a2,ffffffffc0202322 <unmap_range+0x122>
ffffffffc020223a:	89aa                	mv	s3,a0
        }
        if (*ptep != 0)
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020223c:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage)
ffffffffc020223e:	000a8c97          	auipc	s9,0xa8
ffffffffc0202242:	46ac8c93          	addi	s9,s9,1130 # ffffffffc02aa6a8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202246:	000a8c17          	auipc	s8,0xa8
ffffffffc020224a:	46ac0c13          	addi	s8,s8,1130 # ffffffffc02aa6b0 <pages>
ffffffffc020224e:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202252:	000a8d17          	auipc	s10,0xa8
ffffffffc0202256:	466d0d13          	addi	s10,s10,1126 # ffffffffc02aa6b8 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020225a:	00200b37          	lui	s6,0x200
ffffffffc020225e:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202262:	4601                	li	a2,0
ffffffffc0202264:	85a2                	mv	a1,s0
ffffffffc0202266:	854e                	mv	a0,s3
ffffffffc0202268:	d1dff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
ffffffffc020226c:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020226e:	cd29                	beqz	a0,ffffffffc02022c8 <unmap_range+0xc8>
        if (*ptep != 0)
ffffffffc0202270:	611c                	ld	a5,0(a0)
ffffffffc0202272:	e395                	bnez	a5,ffffffffc0202296 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202274:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202276:	ff2466e3          	bltu	s0,s2,ffffffffc0202262 <unmap_range+0x62>
}
ffffffffc020227a:	70a6                	ld	ra,104(sp)
ffffffffc020227c:	7406                	ld	s0,96(sp)
ffffffffc020227e:	64e6                	ld	s1,88(sp)
ffffffffc0202280:	6946                	ld	s2,80(sp)
ffffffffc0202282:	69a6                	ld	s3,72(sp)
ffffffffc0202284:	6a06                	ld	s4,64(sp)
ffffffffc0202286:	7ae2                	ld	s5,56(sp)
ffffffffc0202288:	7b42                	ld	s6,48(sp)
ffffffffc020228a:	7ba2                	ld	s7,40(sp)
ffffffffc020228c:	7c02                	ld	s8,32(sp)
ffffffffc020228e:	6ce2                	ld	s9,24(sp)
ffffffffc0202290:	6d42                	ld	s10,16(sp)
ffffffffc0202292:	6165                	addi	sp,sp,112
ffffffffc0202294:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202296:	0017f713          	andi	a4,a5,1
ffffffffc020229a:	df69                	beqz	a4,ffffffffc0202274 <unmap_range+0x74>
    if (PPN(pa) >= npage)
ffffffffc020229c:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022a0:	078a                	slli	a5,a5,0x2
ffffffffc02022a2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022a4:	08e7ff63          	bgeu	a5,a4,ffffffffc0202342 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02022a8:	000c3503          	ld	a0,0(s8)
ffffffffc02022ac:	97de                	add	a5,a5,s7
ffffffffc02022ae:	079a                	slli	a5,a5,0x6
ffffffffc02022b0:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02022b2:	411c                	lw	a5,0(a0)
ffffffffc02022b4:	fff7871b          	addiw	a4,a5,-1
ffffffffc02022b8:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc02022ba:	cf11                	beqz	a4,ffffffffc02022d6 <unmap_range+0xd6>
        *ptep = 0;
ffffffffc02022bc:	0004b023          	sd	zero,0(s1)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02022c0:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02022c4:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02022c6:	bf45                	j	ffffffffc0202276 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022c8:	945a                	add	s0,s0,s6
ffffffffc02022ca:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02022ce:	d455                	beqz	s0,ffffffffc020227a <unmap_range+0x7a>
ffffffffc02022d0:	f92469e3          	bltu	s0,s2,ffffffffc0202262 <unmap_range+0x62>
ffffffffc02022d4:	b75d                	j	ffffffffc020227a <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022d6:	100027f3          	csrr	a5,sstatus
ffffffffc02022da:	8b89                	andi	a5,a5,2
ffffffffc02022dc:	e799                	bnez	a5,ffffffffc02022ea <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02022de:	000d3783          	ld	a5,0(s10)
ffffffffc02022e2:	4585                	li	a1,1
ffffffffc02022e4:	739c                	ld	a5,32(a5)
ffffffffc02022e6:	9782                	jalr	a5
    if (flag)
ffffffffc02022e8:	bfd1                	j	ffffffffc02022bc <unmap_range+0xbc>
ffffffffc02022ea:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02022ec:	ec8fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc02022f0:	000d3783          	ld	a5,0(s10)
ffffffffc02022f4:	6522                	ld	a0,8(sp)
ffffffffc02022f6:	4585                	li	a1,1
ffffffffc02022f8:	739c                	ld	a5,32(a5)
ffffffffc02022fa:	9782                	jalr	a5
        intr_enable();
ffffffffc02022fc:	eb2fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202300:	bf75                	j	ffffffffc02022bc <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202302:	00004697          	auipc	a3,0x4
ffffffffc0202306:	43668693          	addi	a3,a3,1078 # ffffffffc0206738 <default_pmm_manager+0x160>
ffffffffc020230a:	00004617          	auipc	a2,0x4
ffffffffc020230e:	f1e60613          	addi	a2,a2,-226 # ffffffffc0206228 <commands+0x800>
ffffffffc0202312:	12000593          	li	a1,288
ffffffffc0202316:	00004517          	auipc	a0,0x4
ffffffffc020231a:	41250513          	addi	a0,a0,1042 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020231e:	970fe0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202322:	00004697          	auipc	a3,0x4
ffffffffc0202326:	44668693          	addi	a3,a3,1094 # ffffffffc0206768 <default_pmm_manager+0x190>
ffffffffc020232a:	00004617          	auipc	a2,0x4
ffffffffc020232e:	efe60613          	addi	a2,a2,-258 # ffffffffc0206228 <commands+0x800>
ffffffffc0202332:	12100593          	li	a1,289
ffffffffc0202336:	00004517          	auipc	a0,0x4
ffffffffc020233a:	3f250513          	addi	a0,a0,1010 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020233e:	950fe0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202342:	b53ff0ef          	jal	ra,ffffffffc0201e94 <pa2page.part.0>

ffffffffc0202346 <exit_range>:
{
ffffffffc0202346:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202348:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020234c:	fc86                	sd	ra,120(sp)
ffffffffc020234e:	f8a2                	sd	s0,112(sp)
ffffffffc0202350:	f4a6                	sd	s1,104(sp)
ffffffffc0202352:	f0ca                	sd	s2,96(sp)
ffffffffc0202354:	ecce                	sd	s3,88(sp)
ffffffffc0202356:	e8d2                	sd	s4,80(sp)
ffffffffc0202358:	e4d6                	sd	s5,72(sp)
ffffffffc020235a:	e0da                	sd	s6,64(sp)
ffffffffc020235c:	fc5e                	sd	s7,56(sp)
ffffffffc020235e:	f862                	sd	s8,48(sp)
ffffffffc0202360:	f466                	sd	s9,40(sp)
ffffffffc0202362:	f06a                	sd	s10,32(sp)
ffffffffc0202364:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202366:	17d2                	slli	a5,a5,0x34
ffffffffc0202368:	20079a63          	bnez	a5,ffffffffc020257c <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020236c:	002007b7          	lui	a5,0x200
ffffffffc0202370:	24f5e463          	bltu	a1,a5,ffffffffc02025b8 <exit_range+0x272>
ffffffffc0202374:	8ab2                	mv	s5,a2
ffffffffc0202376:	24c5f163          	bgeu	a1,a2,ffffffffc02025b8 <exit_range+0x272>
ffffffffc020237a:	4785                	li	a5,1
ffffffffc020237c:	07fe                	slli	a5,a5,0x1f
ffffffffc020237e:	22c7ed63          	bltu	a5,a2,ffffffffc02025b8 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202382:	c00009b7          	lui	s3,0xc0000
ffffffffc0202386:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020238a:	ffe00937          	lui	s2,0xffe00
ffffffffc020238e:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0202392:	5cfd                	li	s9,-1
ffffffffc0202394:	8c2a                	mv	s8,a0
ffffffffc0202396:	0125f933          	and	s2,a1,s2
ffffffffc020239a:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage)
ffffffffc020239c:	000a8d17          	auipc	s10,0xa8
ffffffffc02023a0:	30cd0d13          	addi	s10,s10,780 # ffffffffc02aa6a8 <npage>
    return KADDR(page2pa(page));
ffffffffc02023a4:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023a8:	000a8717          	auipc	a4,0xa8
ffffffffc02023ac:	30870713          	addi	a4,a4,776 # ffffffffc02aa6b0 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02023b0:	000a8d97          	auipc	s11,0xa8
ffffffffc02023b4:	308d8d93          	addi	s11,s11,776 # ffffffffc02aa6b8 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02023b8:	c0000437          	lui	s0,0xc0000
ffffffffc02023bc:	944e                	add	s0,s0,s3
ffffffffc02023be:	8079                	srli	s0,s0,0x1e
ffffffffc02023c0:	1ff47413          	andi	s0,s0,511
ffffffffc02023c4:	040e                	slli	s0,s0,0x3
ffffffffc02023c6:	9462                	add	s0,s0,s8
ffffffffc02023c8:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee8>
        if (pde1 & PTE_V)
ffffffffc02023cc:	001a7793          	andi	a5,s4,1
ffffffffc02023d0:	eb99                	bnez	a5,ffffffffc02023e6 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02023d2:	12098463          	beqz	s3,ffffffffc02024fa <exit_range+0x1b4>
ffffffffc02023d6:	400007b7          	lui	a5,0x40000
ffffffffc02023da:	97ce                	add	a5,a5,s3
ffffffffc02023dc:	894e                	mv	s2,s3
ffffffffc02023de:	1159fe63          	bgeu	s3,s5,ffffffffc02024fa <exit_range+0x1b4>
ffffffffc02023e2:	89be                	mv	s3,a5
ffffffffc02023e4:	bfd1                	j	ffffffffc02023b8 <exit_range+0x72>
    if (PPN(pa) >= npage)
ffffffffc02023e6:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023ea:	0a0a                	slli	s4,s4,0x2
ffffffffc02023ec:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage)
ffffffffc02023f0:	1cfa7263          	bgeu	s4,a5,ffffffffc02025b4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023f4:	fff80637          	lui	a2,0xfff80
ffffffffc02023f8:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc02023fa:	000806b7          	lui	a3,0x80
ffffffffc02023fe:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202400:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202404:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202406:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202408:	18f5fa63          	bgeu	a1,a5,ffffffffc020259c <exit_range+0x256>
ffffffffc020240c:	000a8817          	auipc	a6,0xa8
ffffffffc0202410:	2b480813          	addi	a6,a6,692 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0202414:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc0202418:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020241a:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc020241e:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202420:	00080337          	lui	t1,0x80
ffffffffc0202424:	6885                	lui	a7,0x1
ffffffffc0202426:	a819                	j	ffffffffc020243c <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc0202428:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020242a:	002007b7          	lui	a5,0x200
ffffffffc020242e:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202430:	08090c63          	beqz	s2,ffffffffc02024c8 <exit_range+0x182>
ffffffffc0202434:	09397a63          	bgeu	s2,s3,ffffffffc02024c8 <exit_range+0x182>
ffffffffc0202438:	0f597063          	bgeu	s2,s5,ffffffffc0202518 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020243c:	01595493          	srli	s1,s2,0x15
ffffffffc0202440:	1ff4f493          	andi	s1,s1,511
ffffffffc0202444:	048e                	slli	s1,s1,0x3
ffffffffc0202446:	94da                	add	s1,s1,s6
ffffffffc0202448:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V)
ffffffffc020244a:	0017f693          	andi	a3,a5,1
ffffffffc020244e:	dee9                	beqz	a3,ffffffffc0202428 <exit_range+0xe2>
    if (PPN(pa) >= npage)
ffffffffc0202450:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202454:	078a                	slli	a5,a5,0x2
ffffffffc0202456:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202458:	14b7fe63          	bgeu	a5,a1,ffffffffc02025b4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020245c:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc020245e:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202462:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202466:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020246a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020246c:	12bef863          	bgeu	t4,a1,ffffffffc020259c <exit_range+0x256>
ffffffffc0202470:	00083783          	ld	a5,0(a6)
ffffffffc0202474:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202476:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V)
ffffffffc020247a:	629c                	ld	a5,0(a3)
ffffffffc020247c:	8b85                	andi	a5,a5,1
ffffffffc020247e:	f7d5                	bnez	a5,ffffffffc020242a <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202480:	06a1                	addi	a3,a3,8
ffffffffc0202482:	fed59ce3          	bne	a1,a3,ffffffffc020247a <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202486:	631c                	ld	a5,0(a4)
ffffffffc0202488:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020248a:	100027f3          	csrr	a5,sstatus
ffffffffc020248e:	8b89                	andi	a5,a5,2
ffffffffc0202490:	e7d9                	bnez	a5,ffffffffc020251e <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0202492:	000db783          	ld	a5,0(s11)
ffffffffc0202496:	4585                	li	a1,1
ffffffffc0202498:	e032                	sd	a2,0(sp)
ffffffffc020249a:	739c                	ld	a5,32(a5)
ffffffffc020249c:	9782                	jalr	a5
    if (flag)
ffffffffc020249e:	6602                	ld	a2,0(sp)
ffffffffc02024a0:	000a8817          	auipc	a6,0xa8
ffffffffc02024a4:	22080813          	addi	a6,a6,544 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc02024a8:	fff80e37          	lui	t3,0xfff80
ffffffffc02024ac:	00080337          	lui	t1,0x80
ffffffffc02024b0:	6885                	lui	a7,0x1
ffffffffc02024b2:	000a8717          	auipc	a4,0xa8
ffffffffc02024b6:	1fe70713          	addi	a4,a4,510 # ffffffffc02aa6b0 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024ba:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02024be:	002007b7          	lui	a5,0x200
ffffffffc02024c2:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02024c4:	f60918e3          	bnez	s2,ffffffffc0202434 <exit_range+0xee>
            if (free_pd0)
ffffffffc02024c8:	f00b85e3          	beqz	s7,ffffffffc02023d2 <exit_range+0x8c>
    if (PPN(pa) >= npage)
ffffffffc02024cc:	000d3783          	ld	a5,0(s10)
ffffffffc02024d0:	0efa7263          	bgeu	s4,a5,ffffffffc02025b4 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02024d4:	6308                	ld	a0,0(a4)
ffffffffc02024d6:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02024d8:	100027f3          	csrr	a5,sstatus
ffffffffc02024dc:	8b89                	andi	a5,a5,2
ffffffffc02024de:	efad                	bnez	a5,ffffffffc0202558 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02024e0:	000db783          	ld	a5,0(s11)
ffffffffc02024e4:	4585                	li	a1,1
ffffffffc02024e6:	739c                	ld	a5,32(a5)
ffffffffc02024e8:	9782                	jalr	a5
ffffffffc02024ea:	000a8717          	auipc	a4,0xa8
ffffffffc02024ee:	1c670713          	addi	a4,a4,454 # ffffffffc02aa6b0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc02024f2:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc02024f6:	ee0990e3          	bnez	s3,ffffffffc02023d6 <exit_range+0x90>
}
ffffffffc02024fa:	70e6                	ld	ra,120(sp)
ffffffffc02024fc:	7446                	ld	s0,112(sp)
ffffffffc02024fe:	74a6                	ld	s1,104(sp)
ffffffffc0202500:	7906                	ld	s2,96(sp)
ffffffffc0202502:	69e6                	ld	s3,88(sp)
ffffffffc0202504:	6a46                	ld	s4,80(sp)
ffffffffc0202506:	6aa6                	ld	s5,72(sp)
ffffffffc0202508:	6b06                	ld	s6,64(sp)
ffffffffc020250a:	7be2                	ld	s7,56(sp)
ffffffffc020250c:	7c42                	ld	s8,48(sp)
ffffffffc020250e:	7ca2                	ld	s9,40(sp)
ffffffffc0202510:	7d02                	ld	s10,32(sp)
ffffffffc0202512:	6de2                	ld	s11,24(sp)
ffffffffc0202514:	6109                	addi	sp,sp,128
ffffffffc0202516:	8082                	ret
            if (free_pd0)
ffffffffc0202518:	ea0b8fe3          	beqz	s7,ffffffffc02023d6 <exit_range+0x90>
ffffffffc020251c:	bf45                	j	ffffffffc02024cc <exit_range+0x186>
ffffffffc020251e:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202520:	e42a                	sd	a0,8(sp)
ffffffffc0202522:	c92fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202526:	000db783          	ld	a5,0(s11)
ffffffffc020252a:	6522                	ld	a0,8(sp)
ffffffffc020252c:	4585                	li	a1,1
ffffffffc020252e:	739c                	ld	a5,32(a5)
ffffffffc0202530:	9782                	jalr	a5
        intr_enable();
ffffffffc0202532:	c7cfe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202536:	6602                	ld	a2,0(sp)
ffffffffc0202538:	000a8717          	auipc	a4,0xa8
ffffffffc020253c:	17870713          	addi	a4,a4,376 # ffffffffc02aa6b0 <pages>
ffffffffc0202540:	6885                	lui	a7,0x1
ffffffffc0202542:	00080337          	lui	t1,0x80
ffffffffc0202546:	fff80e37          	lui	t3,0xfff80
ffffffffc020254a:	000a8817          	auipc	a6,0xa8
ffffffffc020254e:	17680813          	addi	a6,a6,374 # ffffffffc02aa6c0 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202552:	0004b023          	sd	zero,0(s1)
ffffffffc0202556:	b7a5                	j	ffffffffc02024be <exit_range+0x178>
ffffffffc0202558:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020255a:	c5afe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020255e:	000db783          	ld	a5,0(s11)
ffffffffc0202562:	6502                	ld	a0,0(sp)
ffffffffc0202564:	4585                	li	a1,1
ffffffffc0202566:	739c                	ld	a5,32(a5)
ffffffffc0202568:	9782                	jalr	a5
        intr_enable();
ffffffffc020256a:	c44fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020256e:	000a8717          	auipc	a4,0xa8
ffffffffc0202572:	14270713          	addi	a4,a4,322 # ffffffffc02aa6b0 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202576:	00043023          	sd	zero,0(s0)
ffffffffc020257a:	bfb5                	j	ffffffffc02024f6 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020257c:	00004697          	auipc	a3,0x4
ffffffffc0202580:	1bc68693          	addi	a3,a3,444 # ffffffffc0206738 <default_pmm_manager+0x160>
ffffffffc0202584:	00004617          	auipc	a2,0x4
ffffffffc0202588:	ca460613          	addi	a2,a2,-860 # ffffffffc0206228 <commands+0x800>
ffffffffc020258c:	13500593          	li	a1,309
ffffffffc0202590:	00004517          	auipc	a0,0x4
ffffffffc0202594:	19850513          	addi	a0,a0,408 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202598:	ef7fd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020259c:	00004617          	auipc	a2,0x4
ffffffffc02025a0:	07460613          	addi	a2,a2,116 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc02025a4:	07100593          	li	a1,113
ffffffffc02025a8:	00004517          	auipc	a0,0x4
ffffffffc02025ac:	09050513          	addi	a0,a0,144 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc02025b0:	edffd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc02025b4:	8e1ff0ef          	jal	ra,ffffffffc0201e94 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025b8:	00004697          	auipc	a3,0x4
ffffffffc02025bc:	1b068693          	addi	a3,a3,432 # ffffffffc0206768 <default_pmm_manager+0x190>
ffffffffc02025c0:	00004617          	auipc	a2,0x4
ffffffffc02025c4:	c6860613          	addi	a2,a2,-920 # ffffffffc0206228 <commands+0x800>
ffffffffc02025c8:	13600593          	li	a1,310
ffffffffc02025cc:	00004517          	auipc	a0,0x4
ffffffffc02025d0:	15c50513          	addi	a0,a0,348 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02025d4:	ebbfd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02025d8 <page_remove>:
{
ffffffffc02025d8:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025da:	4601                	li	a2,0
{
ffffffffc02025dc:	ec26                	sd	s1,24(sp)
ffffffffc02025de:	f406                	sd	ra,40(sp)
ffffffffc02025e0:	f022                	sd	s0,32(sp)
ffffffffc02025e2:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025e4:	9a1ff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
    if (ptep != NULL)
ffffffffc02025e8:	c511                	beqz	a0,ffffffffc02025f4 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc02025ea:	611c                	ld	a5,0(a0)
ffffffffc02025ec:	842a                	mv	s0,a0
ffffffffc02025ee:	0017f713          	andi	a4,a5,1
ffffffffc02025f2:	e711                	bnez	a4,ffffffffc02025fe <page_remove+0x26>
}
ffffffffc02025f4:	70a2                	ld	ra,40(sp)
ffffffffc02025f6:	7402                	ld	s0,32(sp)
ffffffffc02025f8:	64e2                	ld	s1,24(sp)
ffffffffc02025fa:	6145                	addi	sp,sp,48
ffffffffc02025fc:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02025fe:	078a                	slli	a5,a5,0x2
ffffffffc0202600:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202602:	000a8717          	auipc	a4,0xa8
ffffffffc0202606:	0a673703          	ld	a4,166(a4) # ffffffffc02aa6a8 <npage>
ffffffffc020260a:	06e7f363          	bgeu	a5,a4,ffffffffc0202670 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020260e:	fff80537          	lui	a0,0xfff80
ffffffffc0202612:	97aa                	add	a5,a5,a0
ffffffffc0202614:	079a                	slli	a5,a5,0x6
ffffffffc0202616:	000a8517          	auipc	a0,0xa8
ffffffffc020261a:	09a53503          	ld	a0,154(a0) # ffffffffc02aa6b0 <pages>
ffffffffc020261e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202620:	411c                	lw	a5,0(a0)
ffffffffc0202622:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202626:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202628:	cb11                	beqz	a4,ffffffffc020263c <page_remove+0x64>
        *ptep = 0;
ffffffffc020262a:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020262e:	12048073          	sfence.vma	s1
}
ffffffffc0202632:	70a2                	ld	ra,40(sp)
ffffffffc0202634:	7402                	ld	s0,32(sp)
ffffffffc0202636:	64e2                	ld	s1,24(sp)
ffffffffc0202638:	6145                	addi	sp,sp,48
ffffffffc020263a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020263c:	100027f3          	csrr	a5,sstatus
ffffffffc0202640:	8b89                	andi	a5,a5,2
ffffffffc0202642:	eb89                	bnez	a5,ffffffffc0202654 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202644:	000a8797          	auipc	a5,0xa8
ffffffffc0202648:	0747b783          	ld	a5,116(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020264c:	739c                	ld	a5,32(a5)
ffffffffc020264e:	4585                	li	a1,1
ffffffffc0202650:	9782                	jalr	a5
    if (flag)
ffffffffc0202652:	bfe1                	j	ffffffffc020262a <page_remove+0x52>
        intr_disable();
ffffffffc0202654:	e42a                	sd	a0,8(sp)
ffffffffc0202656:	b5efe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc020265a:	000a8797          	auipc	a5,0xa8
ffffffffc020265e:	05e7b783          	ld	a5,94(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc0202662:	739c                	ld	a5,32(a5)
ffffffffc0202664:	6522                	ld	a0,8(sp)
ffffffffc0202666:	4585                	li	a1,1
ffffffffc0202668:	9782                	jalr	a5
        intr_enable();
ffffffffc020266a:	b44fe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc020266e:	bf75                	j	ffffffffc020262a <page_remove+0x52>
ffffffffc0202670:	825ff0ef          	jal	ra,ffffffffc0201e94 <pa2page.part.0>

ffffffffc0202674 <page_insert>:
{
ffffffffc0202674:	7139                	addi	sp,sp,-64
ffffffffc0202676:	e852                	sd	s4,16(sp)
ffffffffc0202678:	8a32                	mv	s4,a2
ffffffffc020267a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020267c:	4605                	li	a2,1
{
ffffffffc020267e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202680:	85d2                	mv	a1,s4
{
ffffffffc0202682:	f426                	sd	s1,40(sp)
ffffffffc0202684:	fc06                	sd	ra,56(sp)
ffffffffc0202686:	f04a                	sd	s2,32(sp)
ffffffffc0202688:	ec4e                	sd	s3,24(sp)
ffffffffc020268a:	e456                	sd	s5,8(sp)
ffffffffc020268c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020268e:	8f7ff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
    if (ptep == NULL)
ffffffffc0202692:	c961                	beqz	a0,ffffffffc0202762 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202694:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202696:	611c                	ld	a5,0(a0)
ffffffffc0202698:	89aa                	mv	s3,a0
ffffffffc020269a:	0016871b          	addiw	a4,a3,1
ffffffffc020269e:	c018                	sw	a4,0(s0)
ffffffffc02026a0:	0017f713          	andi	a4,a5,1
ffffffffc02026a4:	ef05                	bnez	a4,ffffffffc02026dc <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02026a6:	000a8717          	auipc	a4,0xa8
ffffffffc02026aa:	00a73703          	ld	a4,10(a4) # ffffffffc02aa6b0 <pages>
ffffffffc02026ae:	8c19                	sub	s0,s0,a4
ffffffffc02026b0:	000807b7          	lui	a5,0x80
ffffffffc02026b4:	8419                	srai	s0,s0,0x6
ffffffffc02026b6:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026b8:	042a                	slli	s0,s0,0xa
ffffffffc02026ba:	8cc1                	or	s1,s1,s0
ffffffffc02026bc:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026c0:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ee8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026c4:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02026c8:	4501                	li	a0,0
}
ffffffffc02026ca:	70e2                	ld	ra,56(sp)
ffffffffc02026cc:	7442                	ld	s0,48(sp)
ffffffffc02026ce:	74a2                	ld	s1,40(sp)
ffffffffc02026d0:	7902                	ld	s2,32(sp)
ffffffffc02026d2:	69e2                	ld	s3,24(sp)
ffffffffc02026d4:	6a42                	ld	s4,16(sp)
ffffffffc02026d6:	6aa2                	ld	s5,8(sp)
ffffffffc02026d8:	6121                	addi	sp,sp,64
ffffffffc02026da:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02026dc:	078a                	slli	a5,a5,0x2
ffffffffc02026de:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026e0:	000a8717          	auipc	a4,0xa8
ffffffffc02026e4:	fc873703          	ld	a4,-56(a4) # ffffffffc02aa6a8 <npage>
ffffffffc02026e8:	06e7ff63          	bgeu	a5,a4,ffffffffc0202766 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026ec:	000a8a97          	auipc	s5,0xa8
ffffffffc02026f0:	fc4a8a93          	addi	s5,s5,-60 # ffffffffc02aa6b0 <pages>
ffffffffc02026f4:	000ab703          	ld	a4,0(s5)
ffffffffc02026f8:	fff80937          	lui	s2,0xfff80
ffffffffc02026fc:	993e                	add	s2,s2,a5
ffffffffc02026fe:	091a                	slli	s2,s2,0x6
ffffffffc0202700:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc0202702:	01240c63          	beq	s0,s2,ffffffffc020271a <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202706:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fcd591c>
ffffffffc020270a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020270e:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) == 0)
ffffffffc0202712:	c691                	beqz	a3,ffffffffc020271e <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202714:	120a0073          	sfence.vma	s4
}
ffffffffc0202718:	bf59                	j	ffffffffc02026ae <page_insert+0x3a>
ffffffffc020271a:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020271c:	bf49                	j	ffffffffc02026ae <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020271e:	100027f3          	csrr	a5,sstatus
ffffffffc0202722:	8b89                	andi	a5,a5,2
ffffffffc0202724:	ef91                	bnez	a5,ffffffffc0202740 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202726:	000a8797          	auipc	a5,0xa8
ffffffffc020272a:	f927b783          	ld	a5,-110(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020272e:	739c                	ld	a5,32(a5)
ffffffffc0202730:	4585                	li	a1,1
ffffffffc0202732:	854a                	mv	a0,s2
ffffffffc0202734:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202736:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020273a:	120a0073          	sfence.vma	s4
ffffffffc020273e:	bf85                	j	ffffffffc02026ae <page_insert+0x3a>
        intr_disable();
ffffffffc0202740:	a74fe0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202744:	000a8797          	auipc	a5,0xa8
ffffffffc0202748:	f747b783          	ld	a5,-140(a5) # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020274c:	739c                	ld	a5,32(a5)
ffffffffc020274e:	4585                	li	a1,1
ffffffffc0202750:	854a                	mv	a0,s2
ffffffffc0202752:	9782                	jalr	a5
        intr_enable();
ffffffffc0202754:	a5afe0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202758:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020275c:	120a0073          	sfence.vma	s4
ffffffffc0202760:	b7b9                	j	ffffffffc02026ae <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202762:	5571                	li	a0,-4
ffffffffc0202764:	b79d                	j	ffffffffc02026ca <page_insert+0x56>
ffffffffc0202766:	f2eff0ef          	jal	ra,ffffffffc0201e94 <pa2page.part.0>

ffffffffc020276a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020276a:	00004797          	auipc	a5,0x4
ffffffffc020276e:	e6e78793          	addi	a5,a5,-402 # ffffffffc02065d8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202772:	638c                	ld	a1,0(a5)
{
ffffffffc0202774:	7159                	addi	sp,sp,-112
ffffffffc0202776:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202778:	00004517          	auipc	a0,0x4
ffffffffc020277c:	00850513          	addi	a0,a0,8 # ffffffffc0206780 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202780:	000a8b17          	auipc	s6,0xa8
ffffffffc0202784:	f38b0b13          	addi	s6,s6,-200 # ffffffffc02aa6b8 <pmm_manager>
{
ffffffffc0202788:	f486                	sd	ra,104(sp)
ffffffffc020278a:	e8ca                	sd	s2,80(sp)
ffffffffc020278c:	e4ce                	sd	s3,72(sp)
ffffffffc020278e:	f0a2                	sd	s0,96(sp)
ffffffffc0202790:	eca6                	sd	s1,88(sp)
ffffffffc0202792:	e0d2                	sd	s4,64(sp)
ffffffffc0202794:	fc56                	sd	s5,56(sp)
ffffffffc0202796:	f45e                	sd	s7,40(sp)
ffffffffc0202798:	f062                	sd	s8,32(sp)
ffffffffc020279a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020279c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027a0:	9f5fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027a4:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027a8:	000a8997          	auipc	s3,0xa8
ffffffffc02027ac:	f1898993          	addi	s3,s3,-232 # ffffffffc02aa6c0 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027b0:	679c                	ld	a5,8(a5)
ffffffffc02027b2:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027b4:	57f5                	li	a5,-3
ffffffffc02027b6:	07fa                	slli	a5,a5,0x1e
ffffffffc02027b8:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027bc:	9defe0ef          	jal	ra,ffffffffc020099a <get_memory_base>
ffffffffc02027c0:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027c2:	9e2fe0ef          	jal	ra,ffffffffc02009a4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027c6:	200505e3          	beqz	a0,ffffffffc02031d0 <pmm_init+0xa66>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027ca:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027cc:	00004517          	auipc	a0,0x4
ffffffffc02027d0:	fec50513          	addi	a0,a0,-20 # ffffffffc02067b8 <default_pmm_manager+0x1e0>
ffffffffc02027d4:	9c1fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027d8:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027dc:	fff40693          	addi	a3,s0,-1
ffffffffc02027e0:	864a                	mv	a2,s2
ffffffffc02027e2:	85a6                	mv	a1,s1
ffffffffc02027e4:	00004517          	auipc	a0,0x4
ffffffffc02027e8:	fec50513          	addi	a0,a0,-20 # ffffffffc02067d0 <default_pmm_manager+0x1f8>
ffffffffc02027ec:	9a9fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02027f0:	c8000737          	lui	a4,0xc8000
ffffffffc02027f4:	87a2                	mv	a5,s0
ffffffffc02027f6:	54876163          	bltu	a4,s0,ffffffffc0202d38 <pmm_init+0x5ce>
ffffffffc02027fa:	757d                	lui	a0,0xfffff
ffffffffc02027fc:	000a9617          	auipc	a2,0xa9
ffffffffc0202800:	ee760613          	addi	a2,a2,-281 # ffffffffc02ab6e3 <end+0xfff>
ffffffffc0202804:	8e69                	and	a2,a2,a0
ffffffffc0202806:	000a8497          	auipc	s1,0xa8
ffffffffc020280a:	ea248493          	addi	s1,s1,-350 # ffffffffc02aa6a8 <npage>
ffffffffc020280e:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202812:	000a8b97          	auipc	s7,0xa8
ffffffffc0202816:	e9eb8b93          	addi	s7,s7,-354 # ffffffffc02aa6b0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020281a:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020281c:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202820:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202824:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202826:	02f50863          	beq	a0,a5,ffffffffc0202856 <pmm_init+0xec>
ffffffffc020282a:	4781                	li	a5,0
ffffffffc020282c:	4585                	li	a1,1
ffffffffc020282e:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202832:	00679513          	slli	a0,a5,0x6
ffffffffc0202836:	9532                	add	a0,a0,a2
ffffffffc0202838:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fd54924>
ffffffffc020283c:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202840:	6088                	ld	a0,0(s1)
ffffffffc0202842:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0202844:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202848:	00d50733          	add	a4,a0,a3
ffffffffc020284c:	fee7e3e3          	bltu	a5,a4,ffffffffc0202832 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202850:	071a                	slli	a4,a4,0x6
ffffffffc0202852:	00e606b3          	add	a3,a2,a4
ffffffffc0202856:	c02007b7          	lui	a5,0xc0200
ffffffffc020285a:	2ef6ece3          	bltu	a3,a5,ffffffffc0203352 <pmm_init+0xbe8>
ffffffffc020285e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202862:	77fd                	lui	a5,0xfffff
ffffffffc0202864:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202866:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202868:	5086eb63          	bltu	a3,s0,ffffffffc0202d7e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020286c:	00004517          	auipc	a0,0x4
ffffffffc0202870:	f8c50513          	addi	a0,a0,-116 # ffffffffc02067f8 <default_pmm_manager+0x220>
ffffffffc0202874:	921fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202878:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020287c:	000a8917          	auipc	s2,0xa8
ffffffffc0202880:	e2490913          	addi	s2,s2,-476 # ffffffffc02aa6a0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202884:	7b9c                	ld	a5,48(a5)
ffffffffc0202886:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202888:	00004517          	auipc	a0,0x4
ffffffffc020288c:	f8850513          	addi	a0,a0,-120 # ffffffffc0206810 <default_pmm_manager+0x238>
ffffffffc0202890:	905fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202894:	00007697          	auipc	a3,0x7
ffffffffc0202898:	76c68693          	addi	a3,a3,1900 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc020289c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028a0:	c02007b7          	lui	a5,0xc0200
ffffffffc02028a4:	28f6ebe3          	bltu	a3,a5,ffffffffc020333a <pmm_init+0xbd0>
ffffffffc02028a8:	0009b783          	ld	a5,0(s3)
ffffffffc02028ac:	8e9d                	sub	a3,a3,a5
ffffffffc02028ae:	000a8797          	auipc	a5,0xa8
ffffffffc02028b2:	ded7b523          	sd	a3,-534(a5) # ffffffffc02aa698 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028b6:	100027f3          	csrr	a5,sstatus
ffffffffc02028ba:	8b89                	andi	a5,a5,2
ffffffffc02028bc:	4a079763          	bnez	a5,ffffffffc0202d6a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028c0:	000b3783          	ld	a5,0(s6)
ffffffffc02028c4:	779c                	ld	a5,40(a5)
ffffffffc02028c6:	9782                	jalr	a5
ffffffffc02028c8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028ca:	6098                	ld	a4,0(s1)
ffffffffc02028cc:	c80007b7          	lui	a5,0xc8000
ffffffffc02028d0:	83b1                	srli	a5,a5,0xc
ffffffffc02028d2:	66e7e363          	bltu	a5,a4,ffffffffc0202f38 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028d6:	00093503          	ld	a0,0(s2)
ffffffffc02028da:	62050f63          	beqz	a0,ffffffffc0202f18 <pmm_init+0x7ae>
ffffffffc02028de:	03451793          	slli	a5,a0,0x34
ffffffffc02028e2:	62079b63          	bnez	a5,ffffffffc0202f18 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028e6:	4601                	li	a2,0
ffffffffc02028e8:	4581                	li	a1,0
ffffffffc02028ea:	8c3ff0ef          	jal	ra,ffffffffc02021ac <get_page>
ffffffffc02028ee:	60051563          	bnez	a0,ffffffffc0202ef8 <pmm_init+0x78e>
ffffffffc02028f2:	100027f3          	csrr	a5,sstatus
ffffffffc02028f6:	8b89                	andi	a5,a5,2
ffffffffc02028f8:	44079e63          	bnez	a5,ffffffffc0202d54 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028fc:	000b3783          	ld	a5,0(s6)
ffffffffc0202900:	4505                	li	a0,1
ffffffffc0202902:	6f9c                	ld	a5,24(a5)
ffffffffc0202904:	9782                	jalr	a5
ffffffffc0202906:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202908:	00093503          	ld	a0,0(s2)
ffffffffc020290c:	4681                	li	a3,0
ffffffffc020290e:	4601                	li	a2,0
ffffffffc0202910:	85d2                	mv	a1,s4
ffffffffc0202912:	d63ff0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc0202916:	26051ae3          	bnez	a0,ffffffffc020338a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020291a:	00093503          	ld	a0,0(s2)
ffffffffc020291e:	4601                	li	a2,0
ffffffffc0202920:	4581                	li	a1,0
ffffffffc0202922:	e62ff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
ffffffffc0202926:	240502e3          	beqz	a0,ffffffffc020336a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc020292a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020292c:	0017f713          	andi	a4,a5,1
ffffffffc0202930:	5a070263          	beqz	a4,ffffffffc0202ed4 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202934:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202936:	078a                	slli	a5,a5,0x2
ffffffffc0202938:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020293a:	58e7fb63          	bgeu	a5,a4,ffffffffc0202ed0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020293e:	000bb683          	ld	a3,0(s7)
ffffffffc0202942:	fff80637          	lui	a2,0xfff80
ffffffffc0202946:	97b2                	add	a5,a5,a2
ffffffffc0202948:	079a                	slli	a5,a5,0x6
ffffffffc020294a:	97b6                	add	a5,a5,a3
ffffffffc020294c:	14fa17e3          	bne	s4,a5,ffffffffc020329a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc0202950:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba0>
ffffffffc0202954:	4785                	li	a5,1
ffffffffc0202956:	12f692e3          	bne	a3,a5,ffffffffc020327a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020295a:	00093503          	ld	a0,0(s2)
ffffffffc020295e:	77fd                	lui	a5,0xfffff
ffffffffc0202960:	6114                	ld	a3,0(a0)
ffffffffc0202962:	068a                	slli	a3,a3,0x2
ffffffffc0202964:	8efd                	and	a3,a3,a5
ffffffffc0202966:	00c6d613          	srli	a2,a3,0xc
ffffffffc020296a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0203262 <pmm_init+0xaf8>
ffffffffc020296e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202972:	96e2                	add	a3,a3,s8
ffffffffc0202974:	0006ba83          	ld	s5,0(a3)
ffffffffc0202978:	0a8a                	slli	s5,s5,0x2
ffffffffc020297a:	00fafab3          	and	s5,s5,a5
ffffffffc020297e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202982:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0203248 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202986:	4601                	li	a2,0
ffffffffc0202988:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020298a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020298c:	df8ff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202990:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202992:	55551363          	bne	a0,s5,ffffffffc0202ed8 <pmm_init+0x76e>
ffffffffc0202996:	100027f3          	csrr	a5,sstatus
ffffffffc020299a:	8b89                	andi	a5,a5,2
ffffffffc020299c:	3a079163          	bnez	a5,ffffffffc0202d3e <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029a0:	000b3783          	ld	a5,0(s6)
ffffffffc02029a4:	4505                	li	a0,1
ffffffffc02029a6:	6f9c                	ld	a5,24(a5)
ffffffffc02029a8:	9782                	jalr	a5
ffffffffc02029aa:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029ac:	00093503          	ld	a0,0(s2)
ffffffffc02029b0:	46d1                	li	a3,20
ffffffffc02029b2:	6605                	lui	a2,0x1
ffffffffc02029b4:	85e2                	mv	a1,s8
ffffffffc02029b6:	cbfff0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc02029ba:	060517e3          	bnez	a0,ffffffffc0203228 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029be:	00093503          	ld	a0,0(s2)
ffffffffc02029c2:	4601                	li	a2,0
ffffffffc02029c4:	6585                	lui	a1,0x1
ffffffffc02029c6:	dbeff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
ffffffffc02029ca:	02050fe3          	beqz	a0,ffffffffc0203208 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc02029ce:	611c                	ld	a5,0(a0)
ffffffffc02029d0:	0107f713          	andi	a4,a5,16
ffffffffc02029d4:	7c070e63          	beqz	a4,ffffffffc02031b0 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc02029d8:	8b91                	andi	a5,a5,4
ffffffffc02029da:	7a078b63          	beqz	a5,ffffffffc0203190 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029de:	00093503          	ld	a0,0(s2)
ffffffffc02029e2:	611c                	ld	a5,0(a0)
ffffffffc02029e4:	8bc1                	andi	a5,a5,16
ffffffffc02029e6:	78078563          	beqz	a5,ffffffffc0203170 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc02029ea:	000c2703          	lw	a4,0(s8)
ffffffffc02029ee:	4785                	li	a5,1
ffffffffc02029f0:	76f71063          	bne	a4,a5,ffffffffc0203150 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029f4:	4681                	li	a3,0
ffffffffc02029f6:	6605                	lui	a2,0x1
ffffffffc02029f8:	85d2                	mv	a1,s4
ffffffffc02029fa:	c7bff0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc02029fe:	72051963          	bnez	a0,ffffffffc0203130 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc0202a02:	000a2703          	lw	a4,0(s4)
ffffffffc0202a06:	4789                	li	a5,2
ffffffffc0202a08:	70f71463          	bne	a4,a5,ffffffffc0203110 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc0202a0c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a10:	6e079063          	bnez	a5,ffffffffc02030f0 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a14:	00093503          	ld	a0,0(s2)
ffffffffc0202a18:	4601                	li	a2,0
ffffffffc0202a1a:	6585                	lui	a1,0x1
ffffffffc0202a1c:	d68ff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
ffffffffc0202a20:	6a050863          	beqz	a0,ffffffffc02030d0 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a24:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a26:	00177793          	andi	a5,a4,1
ffffffffc0202a2a:	4a078563          	beqz	a5,ffffffffc0202ed4 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc0202a2e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a30:	00271793          	slli	a5,a4,0x2
ffffffffc0202a34:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a36:	48d7fd63          	bgeu	a5,a3,ffffffffc0202ed0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a3a:	000bb683          	ld	a3,0(s7)
ffffffffc0202a3e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a42:	97d6                	add	a5,a5,s5
ffffffffc0202a44:	079a                	slli	a5,a5,0x6
ffffffffc0202a46:	97b6                	add	a5,a5,a3
ffffffffc0202a48:	66fa1463          	bne	s4,a5,ffffffffc02030b0 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a4c:	8b41                	andi	a4,a4,16
ffffffffc0202a4e:	64071163          	bnez	a4,ffffffffc0203090 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a52:	00093503          	ld	a0,0(s2)
ffffffffc0202a56:	4581                	li	a1,0
ffffffffc0202a58:	b81ff0ef          	jal	ra,ffffffffc02025d8 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a5c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a60:	4785                	li	a5,1
ffffffffc0202a62:	60fc9763          	bne	s9,a5,ffffffffc0203070 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202a66:	000c2783          	lw	a5,0(s8)
ffffffffc0202a6a:	5e079363          	bnez	a5,ffffffffc0203050 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a6e:	00093503          	ld	a0,0(s2)
ffffffffc0202a72:	6585                	lui	a1,0x1
ffffffffc0202a74:	b65ff0ef          	jal	ra,ffffffffc02025d8 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a78:	000a2783          	lw	a5,0(s4)
ffffffffc0202a7c:	52079a63          	bnez	a5,ffffffffc0202fb0 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202a80:	000c2783          	lw	a5,0(s8)
ffffffffc0202a84:	50079663          	bnez	a5,ffffffffc0202f90 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a88:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a8c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a8e:	000a3683          	ld	a3,0(s4)
ffffffffc0202a92:	068a                	slli	a3,a3,0x2
ffffffffc0202a94:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a96:	42b6fd63          	bgeu	a3,a1,ffffffffc0202ed0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a9a:	000bb503          	ld	a0,0(s7)
ffffffffc0202a9e:	96d6                	add	a3,a3,s5
ffffffffc0202aa0:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202aa2:	00d507b3          	add	a5,a0,a3
ffffffffc0202aa6:	439c                	lw	a5,0(a5)
ffffffffc0202aa8:	4d979463          	bne	a5,s9,ffffffffc0202f70 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc0202aac:	8699                	srai	a3,a3,0x6
ffffffffc0202aae:	00080637          	lui	a2,0x80
ffffffffc0202ab2:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202ab4:	00c69713          	slli	a4,a3,0xc
ffffffffc0202ab8:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202aba:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202abc:	48b77e63          	bgeu	a4,a1,ffffffffc0202f58 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202ac0:	0009b703          	ld	a4,0(s3)
ffffffffc0202ac4:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ac6:	629c                	ld	a5,0(a3)
ffffffffc0202ac8:	078a                	slli	a5,a5,0x2
ffffffffc0202aca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202acc:	40b7f263          	bgeu	a5,a1,ffffffffc0202ed0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ad0:	8f91                	sub	a5,a5,a2
ffffffffc0202ad2:	079a                	slli	a5,a5,0x6
ffffffffc0202ad4:	953e                	add	a0,a0,a5
ffffffffc0202ad6:	100027f3          	csrr	a5,sstatus
ffffffffc0202ada:	8b89                	andi	a5,a5,2
ffffffffc0202adc:	30079963          	bnez	a5,ffffffffc0202dee <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202ae0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ae4:	4585                	li	a1,1
ffffffffc0202ae6:	739c                	ld	a5,32(a5)
ffffffffc0202ae8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aea:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202aee:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202af0:	078a                	slli	a5,a5,0x2
ffffffffc0202af2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202af4:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202ed0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202af8:	000bb503          	ld	a0,0(s7)
ffffffffc0202afc:	fff80737          	lui	a4,0xfff80
ffffffffc0202b00:	97ba                	add	a5,a5,a4
ffffffffc0202b02:	079a                	slli	a5,a5,0x6
ffffffffc0202b04:	953e                	add	a0,a0,a5
ffffffffc0202b06:	100027f3          	csrr	a5,sstatus
ffffffffc0202b0a:	8b89                	andi	a5,a5,2
ffffffffc0202b0c:	2c079563          	bnez	a5,ffffffffc0202dd6 <pmm_init+0x66c>
ffffffffc0202b10:	000b3783          	ld	a5,0(s6)
ffffffffc0202b14:	4585                	li	a1,1
ffffffffc0202b16:	739c                	ld	a5,32(a5)
ffffffffc0202b18:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b1a:	00093783          	ld	a5,0(s2)
ffffffffc0202b1e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd5491c>
    asm volatile("sfence.vma");
ffffffffc0202b22:	12000073          	sfence.vma
ffffffffc0202b26:	100027f3          	csrr	a5,sstatus
ffffffffc0202b2a:	8b89                	andi	a5,a5,2
ffffffffc0202b2c:	28079b63          	bnez	a5,ffffffffc0202dc2 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b30:	000b3783          	ld	a5,0(s6)
ffffffffc0202b34:	779c                	ld	a5,40(a5)
ffffffffc0202b36:	9782                	jalr	a5
ffffffffc0202b38:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b3a:	4b441b63          	bne	s0,s4,ffffffffc0202ff0 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b3e:	00004517          	auipc	a0,0x4
ffffffffc0202b42:	ffa50513          	addi	a0,a0,-6 # ffffffffc0206b38 <default_pmm_manager+0x560>
ffffffffc0202b46:	e4efd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0202b4a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b4e:	8b89                	andi	a5,a5,2
ffffffffc0202b50:	24079f63          	bnez	a5,ffffffffc0202dae <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b54:	000b3783          	ld	a5,0(s6)
ffffffffc0202b58:	779c                	ld	a5,40(a5)
ffffffffc0202b5a:	9782                	jalr	a5
ffffffffc0202b5c:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b5e:	6098                	ld	a4,0(s1)
ffffffffc0202b60:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b64:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b66:	00c71793          	slli	a5,a4,0xc
ffffffffc0202b6a:	6a05                	lui	s4,0x1
ffffffffc0202b6c:	02f47c63          	bgeu	s0,a5,ffffffffc0202ba4 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b70:	00c45793          	srli	a5,s0,0xc
ffffffffc0202b74:	00093503          	ld	a0,0(s2)
ffffffffc0202b78:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202e76 <pmm_init+0x70c>
ffffffffc0202b7c:	0009b583          	ld	a1,0(s3)
ffffffffc0202b80:	4601                	li	a2,0
ffffffffc0202b82:	95a2                	add	a1,a1,s0
ffffffffc0202b84:	c00ff0ef          	jal	ra,ffffffffc0201f84 <get_pte>
ffffffffc0202b88:	32050463          	beqz	a0,ffffffffc0202eb0 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b8c:	611c                	ld	a5,0(a0)
ffffffffc0202b8e:	078a                	slli	a5,a5,0x2
ffffffffc0202b90:	0157f7b3          	and	a5,a5,s5
ffffffffc0202b94:	2e879e63          	bne	a5,s0,ffffffffc0202e90 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b98:	6098                	ld	a4,0(s1)
ffffffffc0202b9a:	9452                	add	s0,s0,s4
ffffffffc0202b9c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202ba0:	fcf468e3          	bltu	s0,a5,ffffffffc0202b70 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202ba4:	00093783          	ld	a5,0(s2)
ffffffffc0202ba8:	639c                	ld	a5,0(a5)
ffffffffc0202baa:	42079363          	bnez	a5,ffffffffc0202fd0 <pmm_init+0x866>
ffffffffc0202bae:	100027f3          	csrr	a5,sstatus
ffffffffc0202bb2:	8b89                	andi	a5,a5,2
ffffffffc0202bb4:	24079963          	bnez	a5,ffffffffc0202e06 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bb8:	000b3783          	ld	a5,0(s6)
ffffffffc0202bbc:	4505                	li	a0,1
ffffffffc0202bbe:	6f9c                	ld	a5,24(a5)
ffffffffc0202bc0:	9782                	jalr	a5
ffffffffc0202bc2:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bc4:	00093503          	ld	a0,0(s2)
ffffffffc0202bc8:	4699                	li	a3,6
ffffffffc0202bca:	10000613          	li	a2,256
ffffffffc0202bce:	85d2                	mv	a1,s4
ffffffffc0202bd0:	aa5ff0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc0202bd4:	44051e63          	bnez	a0,ffffffffc0203030 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202bd8:	000a2703          	lw	a4,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba0>
ffffffffc0202bdc:	4785                	li	a5,1
ffffffffc0202bde:	42f71963          	bne	a4,a5,ffffffffc0203010 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202be2:	00093503          	ld	a0,0(s2)
ffffffffc0202be6:	6405                	lui	s0,0x1
ffffffffc0202be8:	4699                	li	a3,6
ffffffffc0202bea:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8aa0>
ffffffffc0202bee:	85d2                	mv	a1,s4
ffffffffc0202bf0:	a85ff0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc0202bf4:	72051363          	bnez	a0,ffffffffc020331a <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202bf8:	000a2703          	lw	a4,0(s4)
ffffffffc0202bfc:	4789                	li	a5,2
ffffffffc0202bfe:	6ef71e63          	bne	a4,a5,ffffffffc02032fa <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c02:	00004597          	auipc	a1,0x4
ffffffffc0202c06:	07e58593          	addi	a1,a1,126 # ffffffffc0206c80 <default_pmm_manager+0x6a8>
ffffffffc0202c0a:	10000513          	li	a0,256
ffffffffc0202c0e:	319020ef          	jal	ra,ffffffffc0205726 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c12:	10040593          	addi	a1,s0,256
ffffffffc0202c16:	10000513          	li	a0,256
ffffffffc0202c1a:	31f020ef          	jal	ra,ffffffffc0205738 <strcmp>
ffffffffc0202c1e:	6a051e63          	bnez	a0,ffffffffc02032da <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc0202c22:	000bb683          	ld	a3,0(s7)
ffffffffc0202c26:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202c2a:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0202c2c:	40da06b3          	sub	a3,s4,a3
ffffffffc0202c30:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202c32:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202c34:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202c36:	8031                	srli	s0,s0,0xc
ffffffffc0202c38:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c3c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c3e:	30f77d63          	bgeu	a4,a5,ffffffffc0202f58 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c42:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c46:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c4a:	96be                	add	a3,a3,a5
ffffffffc0202c4c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c50:	2a1020ef          	jal	ra,ffffffffc02056f0 <strlen>
ffffffffc0202c54:	66051363          	bnez	a0,ffffffffc02032ba <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c58:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c5c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c5e:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fd5491c>
ffffffffc0202c62:	068a                	slli	a3,a3,0x2
ffffffffc0202c64:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c66:	26f6f563          	bgeu	a3,a5,ffffffffc0202ed0 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc0202c6a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c6c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c6e:	2ef47563          	bgeu	s0,a5,ffffffffc0202f58 <pmm_init+0x7ee>
ffffffffc0202c72:	0009b403          	ld	s0,0(s3)
ffffffffc0202c76:	9436                	add	s0,s0,a3
ffffffffc0202c78:	100027f3          	csrr	a5,sstatus
ffffffffc0202c7c:	8b89                	andi	a5,a5,2
ffffffffc0202c7e:	1e079163          	bnez	a5,ffffffffc0202e60 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202c82:	000b3783          	ld	a5,0(s6)
ffffffffc0202c86:	4585                	li	a1,1
ffffffffc0202c88:	8552                	mv	a0,s4
ffffffffc0202c8a:	739c                	ld	a5,32(a5)
ffffffffc0202c8c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c8e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202c90:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c92:	078a                	slli	a5,a5,0x2
ffffffffc0202c94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c96:	22e7fd63          	bgeu	a5,a4,ffffffffc0202ed0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c9a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c9e:	fff80737          	lui	a4,0xfff80
ffffffffc0202ca2:	97ba                	add	a5,a5,a4
ffffffffc0202ca4:	079a                	slli	a5,a5,0x6
ffffffffc0202ca6:	953e                	add	a0,a0,a5
ffffffffc0202ca8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cac:	8b89                	andi	a5,a5,2
ffffffffc0202cae:	18079d63          	bnez	a5,ffffffffc0202e48 <pmm_init+0x6de>
ffffffffc0202cb2:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb6:	4585                	li	a1,1
ffffffffc0202cb8:	739c                	ld	a5,32(a5)
ffffffffc0202cba:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cbc:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202cc0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cc2:	078a                	slli	a5,a5,0x2
ffffffffc0202cc4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cc6:	20e7f563          	bgeu	a5,a4,ffffffffc0202ed0 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cca:	000bb503          	ld	a0,0(s7)
ffffffffc0202cce:	fff80737          	lui	a4,0xfff80
ffffffffc0202cd2:	97ba                	add	a5,a5,a4
ffffffffc0202cd4:	079a                	slli	a5,a5,0x6
ffffffffc0202cd6:	953e                	add	a0,a0,a5
ffffffffc0202cd8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cdc:	8b89                	andi	a5,a5,2
ffffffffc0202cde:	14079963          	bnez	a5,ffffffffc0202e30 <pmm_init+0x6c6>
ffffffffc0202ce2:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce6:	4585                	li	a1,1
ffffffffc0202ce8:	739c                	ld	a5,32(a5)
ffffffffc0202cea:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cec:	00093783          	ld	a5,0(s2)
ffffffffc0202cf0:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202cf4:	12000073          	sfence.vma
ffffffffc0202cf8:	100027f3          	csrr	a5,sstatus
ffffffffc0202cfc:	8b89                	andi	a5,a5,2
ffffffffc0202cfe:	10079f63          	bnez	a5,ffffffffc0202e1c <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d02:	000b3783          	ld	a5,0(s6)
ffffffffc0202d06:	779c                	ld	a5,40(a5)
ffffffffc0202d08:	9782                	jalr	a5
ffffffffc0202d0a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d0c:	4c8c1e63          	bne	s8,s0,ffffffffc02031e8 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d10:	00004517          	auipc	a0,0x4
ffffffffc0202d14:	fe850513          	addi	a0,a0,-24 # ffffffffc0206cf8 <default_pmm_manager+0x720>
ffffffffc0202d18:	c7cfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0202d1c:	7406                	ld	s0,96(sp)
ffffffffc0202d1e:	70a6                	ld	ra,104(sp)
ffffffffc0202d20:	64e6                	ld	s1,88(sp)
ffffffffc0202d22:	6946                	ld	s2,80(sp)
ffffffffc0202d24:	69a6                	ld	s3,72(sp)
ffffffffc0202d26:	6a06                	ld	s4,64(sp)
ffffffffc0202d28:	7ae2                	ld	s5,56(sp)
ffffffffc0202d2a:	7b42                	ld	s6,48(sp)
ffffffffc0202d2c:	7ba2                	ld	s7,40(sp)
ffffffffc0202d2e:	7c02                	ld	s8,32(sp)
ffffffffc0202d30:	6ce2                	ld	s9,24(sp)
ffffffffc0202d32:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d34:	f97fe06f          	j	ffffffffc0201cca <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc0202d38:	c80007b7          	lui	a5,0xc8000
ffffffffc0202d3c:	bc7d                	j	ffffffffc02027fa <pmm_init+0x90>
        intr_disable();
ffffffffc0202d3e:	c77fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d42:	000b3783          	ld	a5,0(s6)
ffffffffc0202d46:	4505                	li	a0,1
ffffffffc0202d48:	6f9c                	ld	a5,24(a5)
ffffffffc0202d4a:	9782                	jalr	a5
ffffffffc0202d4c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d4e:	c61fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d52:	b9a9                	j	ffffffffc02029ac <pmm_init+0x242>
        intr_disable();
ffffffffc0202d54:	c61fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202d58:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5c:	4505                	li	a0,1
ffffffffc0202d5e:	6f9c                	ld	a5,24(a5)
ffffffffc0202d60:	9782                	jalr	a5
ffffffffc0202d62:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d64:	c4bfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d68:	b645                	j	ffffffffc0202908 <pmm_init+0x19e>
        intr_disable();
ffffffffc0202d6a:	c4bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d6e:	000b3783          	ld	a5,0(s6)
ffffffffc0202d72:	779c                	ld	a5,40(a5)
ffffffffc0202d74:	9782                	jalr	a5
ffffffffc0202d76:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d78:	c37fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202d7c:	b6b9                	j	ffffffffc02028ca <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d7e:	6705                	lui	a4,0x1
ffffffffc0202d80:	177d                	addi	a4,a4,-1
ffffffffc0202d82:	96ba                	add	a3,a3,a4
ffffffffc0202d84:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d86:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d8a:	14a77363          	bgeu	a4,a0,ffffffffc0202ed0 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d8e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202d92:	fff80537          	lui	a0,0xfff80
ffffffffc0202d96:	972a                	add	a4,a4,a0
ffffffffc0202d98:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d9a:	8c1d                	sub	s0,s0,a5
ffffffffc0202d9c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202da0:	00c45593          	srli	a1,s0,0xc
ffffffffc0202da4:	9532                	add	a0,a0,a2
ffffffffc0202da6:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202da8:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202dac:	b4c1                	j	ffffffffc020286c <pmm_init+0x102>
        intr_disable();
ffffffffc0202dae:	c07fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202db2:	000b3783          	ld	a5,0(s6)
ffffffffc0202db6:	779c                	ld	a5,40(a5)
ffffffffc0202db8:	9782                	jalr	a5
ffffffffc0202dba:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202dbc:	bf3fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dc0:	bb79                	j	ffffffffc0202b5e <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202dc2:	bf3fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202dc6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dca:	779c                	ld	a5,40(a5)
ffffffffc0202dcc:	9782                	jalr	a5
ffffffffc0202dce:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dd0:	bdffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dd4:	b39d                	j	ffffffffc0202b3a <pmm_init+0x3d0>
ffffffffc0202dd6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dd8:	bddfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ddc:	000b3783          	ld	a5,0(s6)
ffffffffc0202de0:	6522                	ld	a0,8(sp)
ffffffffc0202de2:	4585                	li	a1,1
ffffffffc0202de4:	739c                	ld	a5,32(a5)
ffffffffc0202de6:	9782                	jalr	a5
        intr_enable();
ffffffffc0202de8:	bc7fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202dec:	b33d                	j	ffffffffc0202b1a <pmm_init+0x3b0>
ffffffffc0202dee:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202df0:	bc5fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202df4:	000b3783          	ld	a5,0(s6)
ffffffffc0202df8:	6522                	ld	a0,8(sp)
ffffffffc0202dfa:	4585                	li	a1,1
ffffffffc0202dfc:	739c                	ld	a5,32(a5)
ffffffffc0202dfe:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e00:	baffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e04:	b1dd                	j	ffffffffc0202aea <pmm_init+0x380>
        intr_disable();
ffffffffc0202e06:	baffd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e0a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e0e:	4505                	li	a0,1
ffffffffc0202e10:	6f9c                	ld	a5,24(a5)
ffffffffc0202e12:	9782                	jalr	a5
ffffffffc0202e14:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e16:	b99fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e1a:	b36d                	j	ffffffffc0202bc4 <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e1c:	b99fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e20:	000b3783          	ld	a5,0(s6)
ffffffffc0202e24:	779c                	ld	a5,40(a5)
ffffffffc0202e26:	9782                	jalr	a5
ffffffffc0202e28:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e2a:	b85fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e2e:	bdf9                	j	ffffffffc0202d0c <pmm_init+0x5a2>
ffffffffc0202e30:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e32:	b83fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e36:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3a:	6522                	ld	a0,8(sp)
ffffffffc0202e3c:	4585                	li	a1,1
ffffffffc0202e3e:	739c                	ld	a5,32(a5)
ffffffffc0202e40:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e42:	b6dfd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e46:	b55d                	j	ffffffffc0202cec <pmm_init+0x582>
ffffffffc0202e48:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e4a:	b6bfd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e4e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e52:	6522                	ld	a0,8(sp)
ffffffffc0202e54:	4585                	li	a1,1
ffffffffc0202e56:	739c                	ld	a5,32(a5)
ffffffffc0202e58:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e5a:	b55fd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e5e:	bdb9                	j	ffffffffc0202cbc <pmm_init+0x552>
        intr_disable();
ffffffffc0202e60:	b55fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0202e64:	000b3783          	ld	a5,0(s6)
ffffffffc0202e68:	4585                	li	a1,1
ffffffffc0202e6a:	8552                	mv	a0,s4
ffffffffc0202e6c:	739c                	ld	a5,32(a5)
ffffffffc0202e6e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e70:	b3ffd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0202e74:	bd29                	j	ffffffffc0202c8e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e76:	86a2                	mv	a3,s0
ffffffffc0202e78:	00003617          	auipc	a2,0x3
ffffffffc0202e7c:	79860613          	addi	a2,a2,1944 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0202e80:	25600593          	li	a1,598
ffffffffc0202e84:	00004517          	auipc	a0,0x4
ffffffffc0202e88:	8a450513          	addi	a0,a0,-1884 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202e8c:	e02fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e90:	00004697          	auipc	a3,0x4
ffffffffc0202e94:	d0868693          	addi	a3,a3,-760 # ffffffffc0206b98 <default_pmm_manager+0x5c0>
ffffffffc0202e98:	00003617          	auipc	a2,0x3
ffffffffc0202e9c:	39060613          	addi	a2,a2,912 # ffffffffc0206228 <commands+0x800>
ffffffffc0202ea0:	25700593          	li	a1,599
ffffffffc0202ea4:	00004517          	auipc	a0,0x4
ffffffffc0202ea8:	88450513          	addi	a0,a0,-1916 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202eac:	de2fd0ef          	jal	ra,ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202eb0:	00004697          	auipc	a3,0x4
ffffffffc0202eb4:	ca868693          	addi	a3,a3,-856 # ffffffffc0206b58 <default_pmm_manager+0x580>
ffffffffc0202eb8:	00003617          	auipc	a2,0x3
ffffffffc0202ebc:	37060613          	addi	a2,a2,880 # ffffffffc0206228 <commands+0x800>
ffffffffc0202ec0:	25600593          	li	a1,598
ffffffffc0202ec4:	00004517          	auipc	a0,0x4
ffffffffc0202ec8:	86450513          	addi	a0,a0,-1948 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202ecc:	dc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0202ed0:	fc5fe0ef          	jal	ra,ffffffffc0201e94 <pa2page.part.0>
ffffffffc0202ed4:	fddfe0ef          	jal	ra,ffffffffc0201eb0 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202ed8:	00004697          	auipc	a3,0x4
ffffffffc0202edc:	a7868693          	addi	a3,a3,-1416 # ffffffffc0206950 <default_pmm_manager+0x378>
ffffffffc0202ee0:	00003617          	auipc	a2,0x3
ffffffffc0202ee4:	34860613          	addi	a2,a2,840 # ffffffffc0206228 <commands+0x800>
ffffffffc0202ee8:	22600593          	li	a1,550
ffffffffc0202eec:	00004517          	auipc	a0,0x4
ffffffffc0202ef0:	83c50513          	addi	a0,a0,-1988 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202ef4:	d9afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202ef8:	00004697          	auipc	a3,0x4
ffffffffc0202efc:	99868693          	addi	a3,a3,-1640 # ffffffffc0206890 <default_pmm_manager+0x2b8>
ffffffffc0202f00:	00003617          	auipc	a2,0x3
ffffffffc0202f04:	32860613          	addi	a2,a2,808 # ffffffffc0206228 <commands+0x800>
ffffffffc0202f08:	21900593          	li	a1,537
ffffffffc0202f0c:	00004517          	auipc	a0,0x4
ffffffffc0202f10:	81c50513          	addi	a0,a0,-2020 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202f14:	d7afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f18:	00004697          	auipc	a3,0x4
ffffffffc0202f1c:	93868693          	addi	a3,a3,-1736 # ffffffffc0206850 <default_pmm_manager+0x278>
ffffffffc0202f20:	00003617          	auipc	a2,0x3
ffffffffc0202f24:	30860613          	addi	a2,a2,776 # ffffffffc0206228 <commands+0x800>
ffffffffc0202f28:	21800593          	li	a1,536
ffffffffc0202f2c:	00003517          	auipc	a0,0x3
ffffffffc0202f30:	7fc50513          	addi	a0,a0,2044 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202f34:	d5afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f38:	00004697          	auipc	a3,0x4
ffffffffc0202f3c:	8f868693          	addi	a3,a3,-1800 # ffffffffc0206830 <default_pmm_manager+0x258>
ffffffffc0202f40:	00003617          	auipc	a2,0x3
ffffffffc0202f44:	2e860613          	addi	a2,a2,744 # ffffffffc0206228 <commands+0x800>
ffffffffc0202f48:	21700593          	li	a1,535
ffffffffc0202f4c:	00003517          	auipc	a0,0x3
ffffffffc0202f50:	7dc50513          	addi	a0,a0,2012 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202f54:	d3afd0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f58:	00003617          	auipc	a2,0x3
ffffffffc0202f5c:	6b860613          	addi	a2,a2,1720 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0202f60:	07100593          	li	a1,113
ffffffffc0202f64:	00003517          	auipc	a0,0x3
ffffffffc0202f68:	6d450513          	addi	a0,a0,1748 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0202f6c:	d22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f70:	00004697          	auipc	a3,0x4
ffffffffc0202f74:	b7068693          	addi	a3,a3,-1168 # ffffffffc0206ae0 <default_pmm_manager+0x508>
ffffffffc0202f78:	00003617          	auipc	a2,0x3
ffffffffc0202f7c:	2b060613          	addi	a2,a2,688 # ffffffffc0206228 <commands+0x800>
ffffffffc0202f80:	23f00593          	li	a1,575
ffffffffc0202f84:	00003517          	auipc	a0,0x3
ffffffffc0202f88:	7a450513          	addi	a0,a0,1956 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202f8c:	d02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f90:	00004697          	auipc	a3,0x4
ffffffffc0202f94:	b0868693          	addi	a3,a3,-1272 # ffffffffc0206a98 <default_pmm_manager+0x4c0>
ffffffffc0202f98:	00003617          	auipc	a2,0x3
ffffffffc0202f9c:	29060613          	addi	a2,a2,656 # ffffffffc0206228 <commands+0x800>
ffffffffc0202fa0:	23d00593          	li	a1,573
ffffffffc0202fa4:	00003517          	auipc	a0,0x3
ffffffffc0202fa8:	78450513          	addi	a0,a0,1924 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202fac:	ce2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fb0:	00004697          	auipc	a3,0x4
ffffffffc0202fb4:	b1868693          	addi	a3,a3,-1256 # ffffffffc0206ac8 <default_pmm_manager+0x4f0>
ffffffffc0202fb8:	00003617          	auipc	a2,0x3
ffffffffc0202fbc:	27060613          	addi	a2,a2,624 # ffffffffc0206228 <commands+0x800>
ffffffffc0202fc0:	23c00593          	li	a1,572
ffffffffc0202fc4:	00003517          	auipc	a0,0x3
ffffffffc0202fc8:	76450513          	addi	a0,a0,1892 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202fcc:	cc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fd0:	00004697          	auipc	a3,0x4
ffffffffc0202fd4:	be068693          	addi	a3,a3,-1056 # ffffffffc0206bb0 <default_pmm_manager+0x5d8>
ffffffffc0202fd8:	00003617          	auipc	a2,0x3
ffffffffc0202fdc:	25060613          	addi	a2,a2,592 # ffffffffc0206228 <commands+0x800>
ffffffffc0202fe0:	25a00593          	li	a1,602
ffffffffc0202fe4:	00003517          	auipc	a0,0x3
ffffffffc0202fe8:	74450513          	addi	a0,a0,1860 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0202fec:	ca2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ff0:	00004697          	auipc	a3,0x4
ffffffffc0202ff4:	b2068693          	addi	a3,a3,-1248 # ffffffffc0206b10 <default_pmm_manager+0x538>
ffffffffc0202ff8:	00003617          	auipc	a2,0x3
ffffffffc0202ffc:	23060613          	addi	a2,a2,560 # ffffffffc0206228 <commands+0x800>
ffffffffc0203000:	24700593          	li	a1,583
ffffffffc0203004:	00003517          	auipc	a0,0x3
ffffffffc0203008:	72450513          	addi	a0,a0,1828 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020300c:	c82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203010:	00004697          	auipc	a3,0x4
ffffffffc0203014:	bf868693          	addi	a3,a3,-1032 # ffffffffc0206c08 <default_pmm_manager+0x630>
ffffffffc0203018:	00003617          	auipc	a2,0x3
ffffffffc020301c:	21060613          	addi	a2,a2,528 # ffffffffc0206228 <commands+0x800>
ffffffffc0203020:	25f00593          	li	a1,607
ffffffffc0203024:	00003517          	auipc	a0,0x3
ffffffffc0203028:	70450513          	addi	a0,a0,1796 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020302c:	c62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203030:	00004697          	auipc	a3,0x4
ffffffffc0203034:	b9868693          	addi	a3,a3,-1128 # ffffffffc0206bc8 <default_pmm_manager+0x5f0>
ffffffffc0203038:	00003617          	auipc	a2,0x3
ffffffffc020303c:	1f060613          	addi	a2,a2,496 # ffffffffc0206228 <commands+0x800>
ffffffffc0203040:	25e00593          	li	a1,606
ffffffffc0203044:	00003517          	auipc	a0,0x3
ffffffffc0203048:	6e450513          	addi	a0,a0,1764 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020304c:	c42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203050:	00004697          	auipc	a3,0x4
ffffffffc0203054:	a4868693          	addi	a3,a3,-1464 # ffffffffc0206a98 <default_pmm_manager+0x4c0>
ffffffffc0203058:	00003617          	auipc	a2,0x3
ffffffffc020305c:	1d060613          	addi	a2,a2,464 # ffffffffc0206228 <commands+0x800>
ffffffffc0203060:	23900593          	li	a1,569
ffffffffc0203064:	00003517          	auipc	a0,0x3
ffffffffc0203068:	6c450513          	addi	a0,a0,1732 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020306c:	c22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203070:	00004697          	auipc	a3,0x4
ffffffffc0203074:	8c868693          	addi	a3,a3,-1848 # ffffffffc0206938 <default_pmm_manager+0x360>
ffffffffc0203078:	00003617          	auipc	a2,0x3
ffffffffc020307c:	1b060613          	addi	a2,a2,432 # ffffffffc0206228 <commands+0x800>
ffffffffc0203080:	23800593          	li	a1,568
ffffffffc0203084:	00003517          	auipc	a0,0x3
ffffffffc0203088:	6a450513          	addi	a0,a0,1700 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020308c:	c02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203090:	00004697          	auipc	a3,0x4
ffffffffc0203094:	a2068693          	addi	a3,a3,-1504 # ffffffffc0206ab0 <default_pmm_manager+0x4d8>
ffffffffc0203098:	00003617          	auipc	a2,0x3
ffffffffc020309c:	19060613          	addi	a2,a2,400 # ffffffffc0206228 <commands+0x800>
ffffffffc02030a0:	23500593          	li	a1,565
ffffffffc02030a4:	00003517          	auipc	a0,0x3
ffffffffc02030a8:	68450513          	addi	a0,a0,1668 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02030ac:	be2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030b0:	00004697          	auipc	a3,0x4
ffffffffc02030b4:	87068693          	addi	a3,a3,-1936 # ffffffffc0206920 <default_pmm_manager+0x348>
ffffffffc02030b8:	00003617          	auipc	a2,0x3
ffffffffc02030bc:	17060613          	addi	a2,a2,368 # ffffffffc0206228 <commands+0x800>
ffffffffc02030c0:	23400593          	li	a1,564
ffffffffc02030c4:	00003517          	auipc	a0,0x3
ffffffffc02030c8:	66450513          	addi	a0,a0,1636 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02030cc:	bc2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030d0:	00004697          	auipc	a3,0x4
ffffffffc02030d4:	8f068693          	addi	a3,a3,-1808 # ffffffffc02069c0 <default_pmm_manager+0x3e8>
ffffffffc02030d8:	00003617          	auipc	a2,0x3
ffffffffc02030dc:	15060613          	addi	a2,a2,336 # ffffffffc0206228 <commands+0x800>
ffffffffc02030e0:	23300593          	li	a1,563
ffffffffc02030e4:	00003517          	auipc	a0,0x3
ffffffffc02030e8:	64450513          	addi	a0,a0,1604 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02030ec:	ba2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030f0:	00004697          	auipc	a3,0x4
ffffffffc02030f4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0206a98 <default_pmm_manager+0x4c0>
ffffffffc02030f8:	00003617          	auipc	a2,0x3
ffffffffc02030fc:	13060613          	addi	a2,a2,304 # ffffffffc0206228 <commands+0x800>
ffffffffc0203100:	23200593          	li	a1,562
ffffffffc0203104:	00003517          	auipc	a0,0x3
ffffffffc0203108:	62450513          	addi	a0,a0,1572 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020310c:	b82fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203110:	00004697          	auipc	a3,0x4
ffffffffc0203114:	97068693          	addi	a3,a3,-1680 # ffffffffc0206a80 <default_pmm_manager+0x4a8>
ffffffffc0203118:	00003617          	auipc	a2,0x3
ffffffffc020311c:	11060613          	addi	a2,a2,272 # ffffffffc0206228 <commands+0x800>
ffffffffc0203120:	23100593          	li	a1,561
ffffffffc0203124:	00003517          	auipc	a0,0x3
ffffffffc0203128:	60450513          	addi	a0,a0,1540 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020312c:	b62fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203130:	00004697          	auipc	a3,0x4
ffffffffc0203134:	92068693          	addi	a3,a3,-1760 # ffffffffc0206a50 <default_pmm_manager+0x478>
ffffffffc0203138:	00003617          	auipc	a2,0x3
ffffffffc020313c:	0f060613          	addi	a2,a2,240 # ffffffffc0206228 <commands+0x800>
ffffffffc0203140:	23000593          	li	a1,560
ffffffffc0203144:	00003517          	auipc	a0,0x3
ffffffffc0203148:	5e450513          	addi	a0,a0,1508 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020314c:	b42fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203150:	00004697          	auipc	a3,0x4
ffffffffc0203154:	8e868693          	addi	a3,a3,-1816 # ffffffffc0206a38 <default_pmm_manager+0x460>
ffffffffc0203158:	00003617          	auipc	a2,0x3
ffffffffc020315c:	0d060613          	addi	a2,a2,208 # ffffffffc0206228 <commands+0x800>
ffffffffc0203160:	22e00593          	li	a1,558
ffffffffc0203164:	00003517          	auipc	a0,0x3
ffffffffc0203168:	5c450513          	addi	a0,a0,1476 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020316c:	b22fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203170:	00004697          	auipc	a3,0x4
ffffffffc0203174:	8a868693          	addi	a3,a3,-1880 # ffffffffc0206a18 <default_pmm_manager+0x440>
ffffffffc0203178:	00003617          	auipc	a2,0x3
ffffffffc020317c:	0b060613          	addi	a2,a2,176 # ffffffffc0206228 <commands+0x800>
ffffffffc0203180:	22d00593          	li	a1,557
ffffffffc0203184:	00003517          	auipc	a0,0x3
ffffffffc0203188:	5a450513          	addi	a0,a0,1444 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020318c:	b02fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203190:	00004697          	auipc	a3,0x4
ffffffffc0203194:	87868693          	addi	a3,a3,-1928 # ffffffffc0206a08 <default_pmm_manager+0x430>
ffffffffc0203198:	00003617          	auipc	a2,0x3
ffffffffc020319c:	09060613          	addi	a2,a2,144 # ffffffffc0206228 <commands+0x800>
ffffffffc02031a0:	22c00593          	li	a1,556
ffffffffc02031a4:	00003517          	auipc	a0,0x3
ffffffffc02031a8:	58450513          	addi	a0,a0,1412 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02031ac:	ae2fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031b0:	00004697          	auipc	a3,0x4
ffffffffc02031b4:	84868693          	addi	a3,a3,-1976 # ffffffffc02069f8 <default_pmm_manager+0x420>
ffffffffc02031b8:	00003617          	auipc	a2,0x3
ffffffffc02031bc:	07060613          	addi	a2,a2,112 # ffffffffc0206228 <commands+0x800>
ffffffffc02031c0:	22b00593          	li	a1,555
ffffffffc02031c4:	00003517          	auipc	a0,0x3
ffffffffc02031c8:	56450513          	addi	a0,a0,1380 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02031cc:	ac2fd0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("DTB memory info not available");
ffffffffc02031d0:	00003617          	auipc	a2,0x3
ffffffffc02031d4:	5c860613          	addi	a2,a2,1480 # ffffffffc0206798 <default_pmm_manager+0x1c0>
ffffffffc02031d8:	06500593          	li	a1,101
ffffffffc02031dc:	00003517          	auipc	a0,0x3
ffffffffc02031e0:	54c50513          	addi	a0,a0,1356 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02031e4:	aaafd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc02031e8:	00004697          	auipc	a3,0x4
ffffffffc02031ec:	92868693          	addi	a3,a3,-1752 # ffffffffc0206b10 <default_pmm_manager+0x538>
ffffffffc02031f0:	00003617          	auipc	a2,0x3
ffffffffc02031f4:	03860613          	addi	a2,a2,56 # ffffffffc0206228 <commands+0x800>
ffffffffc02031f8:	27100593          	li	a1,625
ffffffffc02031fc:	00003517          	auipc	a0,0x3
ffffffffc0203200:	52c50513          	addi	a0,a0,1324 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203204:	a8afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203208:	00003697          	auipc	a3,0x3
ffffffffc020320c:	7b868693          	addi	a3,a3,1976 # ffffffffc02069c0 <default_pmm_manager+0x3e8>
ffffffffc0203210:	00003617          	auipc	a2,0x3
ffffffffc0203214:	01860613          	addi	a2,a2,24 # ffffffffc0206228 <commands+0x800>
ffffffffc0203218:	22a00593          	li	a1,554
ffffffffc020321c:	00003517          	auipc	a0,0x3
ffffffffc0203220:	50c50513          	addi	a0,a0,1292 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203224:	a6afd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203228:	00003697          	auipc	a3,0x3
ffffffffc020322c:	75868693          	addi	a3,a3,1880 # ffffffffc0206980 <default_pmm_manager+0x3a8>
ffffffffc0203230:	00003617          	auipc	a2,0x3
ffffffffc0203234:	ff860613          	addi	a2,a2,-8 # ffffffffc0206228 <commands+0x800>
ffffffffc0203238:	22900593          	li	a1,553
ffffffffc020323c:	00003517          	auipc	a0,0x3
ffffffffc0203240:	4ec50513          	addi	a0,a0,1260 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203244:	a4afd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203248:	86d6                	mv	a3,s5
ffffffffc020324a:	00003617          	auipc	a2,0x3
ffffffffc020324e:	3c660613          	addi	a2,a2,966 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0203252:	22500593          	li	a1,549
ffffffffc0203256:	00003517          	auipc	a0,0x3
ffffffffc020325a:	4d250513          	addi	a0,a0,1234 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020325e:	a30fd0ef          	jal	ra,ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203262:	00003617          	auipc	a2,0x3
ffffffffc0203266:	3ae60613          	addi	a2,a2,942 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc020326a:	22400593          	li	a1,548
ffffffffc020326e:	00003517          	auipc	a0,0x3
ffffffffc0203272:	4ba50513          	addi	a0,a0,1210 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203276:	a18fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020327a:	00003697          	auipc	a3,0x3
ffffffffc020327e:	6be68693          	addi	a3,a3,1726 # ffffffffc0206938 <default_pmm_manager+0x360>
ffffffffc0203282:	00003617          	auipc	a2,0x3
ffffffffc0203286:	fa660613          	addi	a2,a2,-90 # ffffffffc0206228 <commands+0x800>
ffffffffc020328a:	22200593          	li	a1,546
ffffffffc020328e:	00003517          	auipc	a0,0x3
ffffffffc0203292:	49a50513          	addi	a0,a0,1178 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203296:	9f8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020329a:	00003697          	auipc	a3,0x3
ffffffffc020329e:	68668693          	addi	a3,a3,1670 # ffffffffc0206920 <default_pmm_manager+0x348>
ffffffffc02032a2:	00003617          	auipc	a2,0x3
ffffffffc02032a6:	f8660613          	addi	a2,a2,-122 # ffffffffc0206228 <commands+0x800>
ffffffffc02032aa:	22100593          	li	a1,545
ffffffffc02032ae:	00003517          	auipc	a0,0x3
ffffffffc02032b2:	47a50513          	addi	a0,a0,1146 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02032b6:	9d8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032ba:	00004697          	auipc	a3,0x4
ffffffffc02032be:	a1668693          	addi	a3,a3,-1514 # ffffffffc0206cd0 <default_pmm_manager+0x6f8>
ffffffffc02032c2:	00003617          	auipc	a2,0x3
ffffffffc02032c6:	f6660613          	addi	a2,a2,-154 # ffffffffc0206228 <commands+0x800>
ffffffffc02032ca:	26800593          	li	a1,616
ffffffffc02032ce:	00003517          	auipc	a0,0x3
ffffffffc02032d2:	45a50513          	addi	a0,a0,1114 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02032d6:	9b8fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032da:	00004697          	auipc	a3,0x4
ffffffffc02032de:	9be68693          	addi	a3,a3,-1602 # ffffffffc0206c98 <default_pmm_manager+0x6c0>
ffffffffc02032e2:	00003617          	auipc	a2,0x3
ffffffffc02032e6:	f4660613          	addi	a2,a2,-186 # ffffffffc0206228 <commands+0x800>
ffffffffc02032ea:	26500593          	li	a1,613
ffffffffc02032ee:	00003517          	auipc	a0,0x3
ffffffffc02032f2:	43a50513          	addi	a0,a0,1082 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02032f6:	998fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032fa:	00004697          	auipc	a3,0x4
ffffffffc02032fe:	96e68693          	addi	a3,a3,-1682 # ffffffffc0206c68 <default_pmm_manager+0x690>
ffffffffc0203302:	00003617          	auipc	a2,0x3
ffffffffc0203306:	f2660613          	addi	a2,a2,-218 # ffffffffc0206228 <commands+0x800>
ffffffffc020330a:	26100593          	li	a1,609
ffffffffc020330e:	00003517          	auipc	a0,0x3
ffffffffc0203312:	41a50513          	addi	a0,a0,1050 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203316:	978fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020331a:	00004697          	auipc	a3,0x4
ffffffffc020331e:	90668693          	addi	a3,a3,-1786 # ffffffffc0206c20 <default_pmm_manager+0x648>
ffffffffc0203322:	00003617          	auipc	a2,0x3
ffffffffc0203326:	f0660613          	addi	a2,a2,-250 # ffffffffc0206228 <commands+0x800>
ffffffffc020332a:	26000593          	li	a1,608
ffffffffc020332e:	00003517          	auipc	a0,0x3
ffffffffc0203332:	3fa50513          	addi	a0,a0,1018 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203336:	958fd0ef          	jal	ra,ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc020333a:	00003617          	auipc	a2,0x3
ffffffffc020333e:	37e60613          	addi	a2,a2,894 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc0203342:	0c900593          	li	a1,201
ffffffffc0203346:	00003517          	auipc	a0,0x3
ffffffffc020334a:	3e250513          	addi	a0,a0,994 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc020334e:	940fd0ef          	jal	ra,ffffffffc020048e <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203352:	00003617          	auipc	a2,0x3
ffffffffc0203356:	36660613          	addi	a2,a2,870 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc020335a:	08100593          	li	a1,129
ffffffffc020335e:	00003517          	auipc	a0,0x3
ffffffffc0203362:	3ca50513          	addi	a0,a0,970 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203366:	928fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020336a:	00003697          	auipc	a3,0x3
ffffffffc020336e:	58668693          	addi	a3,a3,1414 # ffffffffc02068f0 <default_pmm_manager+0x318>
ffffffffc0203372:	00003617          	auipc	a2,0x3
ffffffffc0203376:	eb660613          	addi	a2,a2,-330 # ffffffffc0206228 <commands+0x800>
ffffffffc020337a:	22000593          	li	a1,544
ffffffffc020337e:	00003517          	auipc	a0,0x3
ffffffffc0203382:	3aa50513          	addi	a0,a0,938 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203386:	908fd0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020338a:	00003697          	auipc	a3,0x3
ffffffffc020338e:	53668693          	addi	a3,a3,1334 # ffffffffc02068c0 <default_pmm_manager+0x2e8>
ffffffffc0203392:	00003617          	auipc	a2,0x3
ffffffffc0203396:	e9660613          	addi	a2,a2,-362 # ffffffffc0206228 <commands+0x800>
ffffffffc020339a:	21d00593          	li	a1,541
ffffffffc020339e:	00003517          	auipc	a0,0x3
ffffffffc02033a2:	38a50513          	addi	a0,a0,906 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02033a6:	8e8fd0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02033aa <copy_range>:
{
ffffffffc02033aa:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033ac:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033b0:	f486                	sd	ra,104(sp)
ffffffffc02033b2:	f0a2                	sd	s0,96(sp)
ffffffffc02033b4:	eca6                	sd	s1,88(sp)
ffffffffc02033b6:	e8ca                	sd	s2,80(sp)
ffffffffc02033b8:	e4ce                	sd	s3,72(sp)
ffffffffc02033ba:	e0d2                	sd	s4,64(sp)
ffffffffc02033bc:	fc56                	sd	s5,56(sp)
ffffffffc02033be:	f85a                	sd	s6,48(sp)
ffffffffc02033c0:	f45e                	sd	s7,40(sp)
ffffffffc02033c2:	f062                	sd	s8,32(sp)
ffffffffc02033c4:	ec66                	sd	s9,24(sp)
ffffffffc02033c6:	e86a                	sd	s10,16(sp)
ffffffffc02033c8:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033ca:	17d2                	slli	a5,a5,0x34
ffffffffc02033cc:	1e079e63          	bnez	a5,ffffffffc02035c8 <copy_range+0x21e>
    assert(USER_ACCESS(start, end));
ffffffffc02033d0:	002007b7          	lui	a5,0x200
ffffffffc02033d4:	8432                	mv	s0,a2
ffffffffc02033d6:	1af66963          	bltu	a2,a5,ffffffffc0203588 <copy_range+0x1de>
ffffffffc02033da:	8936                	mv	s2,a3
ffffffffc02033dc:	1ad67663          	bgeu	a2,a3,ffffffffc0203588 <copy_range+0x1de>
ffffffffc02033e0:	4785                	li	a5,1
ffffffffc02033e2:	07fe                	slli	a5,a5,0x1f
ffffffffc02033e4:	1ad7e263          	bltu	a5,a3,ffffffffc0203588 <copy_range+0x1de>
ffffffffc02033e8:	5afd                	li	s5,-1
ffffffffc02033ea:	8a2a                	mv	s4,a0
ffffffffc02033ec:	89ae                	mv	s3,a1
    if (PPN(pa) >= npage)
ffffffffc02033ee:	000a7c17          	auipc	s8,0xa7
ffffffffc02033f2:	2bac0c13          	addi	s8,s8,698 # ffffffffc02aa6a8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02033f6:	000a7b97          	auipc	s7,0xa7
ffffffffc02033fa:	2bab8b93          	addi	s7,s7,698 # ffffffffc02aa6b0 <pages>
    return page - pages + nbase;
ffffffffc02033fe:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc0203402:	00cada93          	srli	s5,s5,0xc
        page = pmm_manager->alloc_pages(n);
ffffffffc0203406:	000a7c97          	auipc	s9,0xa7
ffffffffc020340a:	2b2c8c93          	addi	s9,s9,690 # ffffffffc02aa6b8 <pmm_manager>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020340e:	4601                	li	a2,0
ffffffffc0203410:	85a2                	mv	a1,s0
ffffffffc0203412:	854e                	mv	a0,s3
ffffffffc0203414:	b71fe0ef          	jal	ra,ffffffffc0201f84 <get_pte>
ffffffffc0203418:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020341a:	c979                	beqz	a0,ffffffffc02034f0 <copy_range+0x146>
        if (*ptep & PTE_V)
ffffffffc020341c:	611c                	ld	a5,0(a0)
ffffffffc020341e:	8b85                	andi	a5,a5,1
ffffffffc0203420:	e78d                	bnez	a5,ffffffffc020344a <copy_range+0xa0>
        start += PGSIZE;
ffffffffc0203422:	6785                	lui	a5,0x1
ffffffffc0203424:	943e                	add	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc0203426:	ff2464e3          	bltu	s0,s2,ffffffffc020340e <copy_range+0x64>
    return 0;
ffffffffc020342a:	4501                	li	a0,0
}
ffffffffc020342c:	70a6                	ld	ra,104(sp)
ffffffffc020342e:	7406                	ld	s0,96(sp)
ffffffffc0203430:	64e6                	ld	s1,88(sp)
ffffffffc0203432:	6946                	ld	s2,80(sp)
ffffffffc0203434:	69a6                	ld	s3,72(sp)
ffffffffc0203436:	6a06                	ld	s4,64(sp)
ffffffffc0203438:	7ae2                	ld	s5,56(sp)
ffffffffc020343a:	7b42                	ld	s6,48(sp)
ffffffffc020343c:	7ba2                	ld	s7,40(sp)
ffffffffc020343e:	7c02                	ld	s8,32(sp)
ffffffffc0203440:	6ce2                	ld	s9,24(sp)
ffffffffc0203442:	6d42                	ld	s10,16(sp)
ffffffffc0203444:	6da2                	ld	s11,8(sp)
ffffffffc0203446:	6165                	addi	sp,sp,112
ffffffffc0203448:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc020344a:	4605                	li	a2,1
ffffffffc020344c:	85a2                	mv	a1,s0
ffffffffc020344e:	8552                	mv	a0,s4
ffffffffc0203450:	b35fe0ef          	jal	ra,ffffffffc0201f84 <get_pte>
ffffffffc0203454:	c179                	beqz	a0,ffffffffc020351a <copy_range+0x170>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203456:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203458:	0017f713          	andi	a4,a5,1
ffffffffc020345c:	01f7f493          	andi	s1,a5,31
ffffffffc0203460:	10070863          	beqz	a4,ffffffffc0203570 <copy_range+0x1c6>
    if (PPN(pa) >= npage)
ffffffffc0203464:	000c3683          	ld	a3,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203468:	078a                	slli	a5,a5,0x2
ffffffffc020346a:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020346e:	0ed77563          	bgeu	a4,a3,ffffffffc0203558 <copy_range+0x1ae>
    return &pages[PPN(pa) - nbase];
ffffffffc0203472:	000bb783          	ld	a5,0(s7)
ffffffffc0203476:	fff806b7          	lui	a3,0xfff80
ffffffffc020347a:	9736                	add	a4,a4,a3
ffffffffc020347c:	071a                	slli	a4,a4,0x6
ffffffffc020347e:	00e78db3          	add	s11,a5,a4
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203482:	10002773          	csrr	a4,sstatus
ffffffffc0203486:	8b09                	andi	a4,a4,2
ffffffffc0203488:	ef35                	bnez	a4,ffffffffc0203504 <copy_range+0x15a>
        page = pmm_manager->alloc_pages(n);
ffffffffc020348a:	000cb703          	ld	a4,0(s9)
ffffffffc020348e:	4505                	li	a0,1
ffffffffc0203490:	6f18                	ld	a4,24(a4)
ffffffffc0203492:	9702                	jalr	a4
ffffffffc0203494:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc0203496:	0a0d8163          	beqz	s11,ffffffffc0203538 <copy_range+0x18e>
            assert(npage != NULL);
ffffffffc020349a:	100d0763          	beqz	s10,ffffffffc02035a8 <copy_range+0x1fe>
    return page - pages + nbase;
ffffffffc020349e:	000bb703          	ld	a4,0(s7)
    return KADDR(page2pa(page));
ffffffffc02034a2:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02034a6:	40ed86b3          	sub	a3,s11,a4
ffffffffc02034aa:	8699                	srai	a3,a3,0x6
ffffffffc02034ac:	96da                	add	a3,a3,s6
    return KADDR(page2pa(page));
ffffffffc02034ae:	0156f7b3          	and	a5,a3,s5
    return page2ppn(page) << PGSHIFT;
ffffffffc02034b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034b4:	06c7f663          	bgeu	a5,a2,ffffffffc0203520 <copy_range+0x176>
    return page - pages + nbase;
ffffffffc02034b8:	40ed07b3          	sub	a5,s10,a4
    return KADDR(page2pa(page));
ffffffffc02034bc:	000a7717          	auipc	a4,0xa7
ffffffffc02034c0:	20470713          	addi	a4,a4,516 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc02034c4:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc02034c6:	8799                	srai	a5,a5,0x6
ffffffffc02034c8:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc02034ca:	0157f733          	and	a4,a5,s5
ffffffffc02034ce:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02034d2:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034d4:	04c77563          	bgeu	a4,a2,ffffffffc020351e <copy_range+0x174>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034d8:	6605                	lui	a2,0x1
ffffffffc02034da:	953e                	add	a0,a0,a5
ffffffffc02034dc:	2c8020ef          	jal	ra,ffffffffc02057a4 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034e0:	86a6                	mv	a3,s1
ffffffffc02034e2:	8622                	mv	a2,s0
ffffffffc02034e4:	85ea                	mv	a1,s10
ffffffffc02034e6:	8552                	mv	a0,s4
ffffffffc02034e8:	98cff0ef          	jal	ra,ffffffffc0202674 <page_insert>
            if (ret != 0) {
ffffffffc02034ec:	d91d                	beqz	a0,ffffffffc0203422 <copy_range+0x78>
ffffffffc02034ee:	bf3d                	j	ffffffffc020342c <copy_range+0x82>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02034f0:	00200637          	lui	a2,0x200
ffffffffc02034f4:	9432                	add	s0,s0,a2
ffffffffc02034f6:	ffe00637          	lui	a2,0xffe00
ffffffffc02034fa:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc02034fc:	d41d                	beqz	s0,ffffffffc020342a <copy_range+0x80>
ffffffffc02034fe:	f12468e3          	bltu	s0,s2,ffffffffc020340e <copy_range+0x64>
ffffffffc0203502:	b725                	j	ffffffffc020342a <copy_range+0x80>
        intr_disable();
ffffffffc0203504:	cb0fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203508:	000cb703          	ld	a4,0(s9)
ffffffffc020350c:	4505                	li	a0,1
ffffffffc020350e:	6f18                	ld	a4,24(a4)
ffffffffc0203510:	9702                	jalr	a4
ffffffffc0203512:	8d2a                	mv	s10,a0
        intr_enable();
ffffffffc0203514:	c9afd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203518:	bfbd                	j	ffffffffc0203496 <copy_range+0xec>
                return -E_NO_MEM;
ffffffffc020351a:	5571                	li	a0,-4
ffffffffc020351c:	bf01                	j	ffffffffc020342c <copy_range+0x82>
ffffffffc020351e:	86be                	mv	a3,a5
ffffffffc0203520:	00003617          	auipc	a2,0x3
ffffffffc0203524:	0f060613          	addi	a2,a2,240 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0203528:	07100593          	li	a1,113
ffffffffc020352c:	00003517          	auipc	a0,0x3
ffffffffc0203530:	10c50513          	addi	a0,a0,268 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0203534:	f5bfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc0203538:	00003697          	auipc	a3,0x3
ffffffffc020353c:	7e068693          	addi	a3,a3,2016 # ffffffffc0206d18 <default_pmm_manager+0x740>
ffffffffc0203540:	00003617          	auipc	a2,0x3
ffffffffc0203544:	ce860613          	addi	a2,a2,-792 # ffffffffc0206228 <commands+0x800>
ffffffffc0203548:	19400593          	li	a1,404
ffffffffc020354c:	00003517          	auipc	a0,0x3
ffffffffc0203550:	1dc50513          	addi	a0,a0,476 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc0203554:	f3bfc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203558:	00003617          	auipc	a2,0x3
ffffffffc020355c:	18860613          	addi	a2,a2,392 # ffffffffc02066e0 <default_pmm_manager+0x108>
ffffffffc0203560:	06900593          	li	a1,105
ffffffffc0203564:	00003517          	auipc	a0,0x3
ffffffffc0203568:	0d450513          	addi	a0,a0,212 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc020356c:	f23fc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203570:	00003617          	auipc	a2,0x3
ffffffffc0203574:	19060613          	addi	a2,a2,400 # ffffffffc0206700 <default_pmm_manager+0x128>
ffffffffc0203578:	07f00593          	li	a1,127
ffffffffc020357c:	00003517          	auipc	a0,0x3
ffffffffc0203580:	0bc50513          	addi	a0,a0,188 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0203584:	f0bfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203588:	00003697          	auipc	a3,0x3
ffffffffc020358c:	1e068693          	addi	a3,a3,480 # ffffffffc0206768 <default_pmm_manager+0x190>
ffffffffc0203590:	00003617          	auipc	a2,0x3
ffffffffc0203594:	c9860613          	addi	a2,a2,-872 # ffffffffc0206228 <commands+0x800>
ffffffffc0203598:	17c00593          	li	a1,380
ffffffffc020359c:	00003517          	auipc	a0,0x3
ffffffffc02035a0:	18c50513          	addi	a0,a0,396 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02035a4:	eebfc0ef          	jal	ra,ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc02035a8:	00003697          	auipc	a3,0x3
ffffffffc02035ac:	78068693          	addi	a3,a3,1920 # ffffffffc0206d28 <default_pmm_manager+0x750>
ffffffffc02035b0:	00003617          	auipc	a2,0x3
ffffffffc02035b4:	c7860613          	addi	a2,a2,-904 # ffffffffc0206228 <commands+0x800>
ffffffffc02035b8:	19500593          	li	a1,405
ffffffffc02035bc:	00003517          	auipc	a0,0x3
ffffffffc02035c0:	16c50513          	addi	a0,a0,364 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02035c4:	ecbfc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035c8:	00003697          	auipc	a3,0x3
ffffffffc02035cc:	17068693          	addi	a3,a3,368 # ffffffffc0206738 <default_pmm_manager+0x160>
ffffffffc02035d0:	00003617          	auipc	a2,0x3
ffffffffc02035d4:	c5860613          	addi	a2,a2,-936 # ffffffffc0206228 <commands+0x800>
ffffffffc02035d8:	17b00593          	li	a1,379
ffffffffc02035dc:	00003517          	auipc	a0,0x3
ffffffffc02035e0:	14c50513          	addi	a0,a0,332 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02035e4:	eabfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02035e8 <pgdir_alloc_page>:
{
ffffffffc02035e8:	7179                	addi	sp,sp,-48
ffffffffc02035ea:	ec26                	sd	s1,24(sp)
ffffffffc02035ec:	e84a                	sd	s2,16(sp)
ffffffffc02035ee:	e052                	sd	s4,0(sp)
ffffffffc02035f0:	f406                	sd	ra,40(sp)
ffffffffc02035f2:	f022                	sd	s0,32(sp)
ffffffffc02035f4:	e44e                	sd	s3,8(sp)
ffffffffc02035f6:	8a2a                	mv	s4,a0
ffffffffc02035f8:	84ae                	mv	s1,a1
ffffffffc02035fa:	8932                	mv	s2,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02035fc:	100027f3          	csrr	a5,sstatus
ffffffffc0203600:	8b89                	andi	a5,a5,2
        page = pmm_manager->alloc_pages(n);
ffffffffc0203602:	000a7997          	auipc	s3,0xa7
ffffffffc0203606:	0b698993          	addi	s3,s3,182 # ffffffffc02aa6b8 <pmm_manager>
ffffffffc020360a:	ef8d                	bnez	a5,ffffffffc0203644 <pgdir_alloc_page+0x5c>
ffffffffc020360c:	0009b783          	ld	a5,0(s3)
ffffffffc0203610:	4505                	li	a0,1
ffffffffc0203612:	6f9c                	ld	a5,24(a5)
ffffffffc0203614:	9782                	jalr	a5
ffffffffc0203616:	842a                	mv	s0,a0
    if (page != NULL)
ffffffffc0203618:	cc09                	beqz	s0,ffffffffc0203632 <pgdir_alloc_page+0x4a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc020361a:	86ca                	mv	a3,s2
ffffffffc020361c:	8626                	mv	a2,s1
ffffffffc020361e:	85a2                	mv	a1,s0
ffffffffc0203620:	8552                	mv	a0,s4
ffffffffc0203622:	852ff0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc0203626:	e915                	bnez	a0,ffffffffc020365a <pgdir_alloc_page+0x72>
        assert(page_ref(page) == 1);
ffffffffc0203628:	4018                	lw	a4,0(s0)
        page->pra_vaddr = la;
ffffffffc020362a:	fc04                	sd	s1,56(s0)
        assert(page_ref(page) == 1);
ffffffffc020362c:	4785                	li	a5,1
ffffffffc020362e:	04f71e63          	bne	a4,a5,ffffffffc020368a <pgdir_alloc_page+0xa2>
}
ffffffffc0203632:	70a2                	ld	ra,40(sp)
ffffffffc0203634:	8522                	mv	a0,s0
ffffffffc0203636:	7402                	ld	s0,32(sp)
ffffffffc0203638:	64e2                	ld	s1,24(sp)
ffffffffc020363a:	6942                	ld	s2,16(sp)
ffffffffc020363c:	69a2                	ld	s3,8(sp)
ffffffffc020363e:	6a02                	ld	s4,0(sp)
ffffffffc0203640:	6145                	addi	sp,sp,48
ffffffffc0203642:	8082                	ret
        intr_disable();
ffffffffc0203644:	b70fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203648:	0009b783          	ld	a5,0(s3)
ffffffffc020364c:	4505                	li	a0,1
ffffffffc020364e:	6f9c                	ld	a5,24(a5)
ffffffffc0203650:	9782                	jalr	a5
ffffffffc0203652:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203654:	b5afd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203658:	b7c1                	j	ffffffffc0203618 <pgdir_alloc_page+0x30>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020365a:	100027f3          	csrr	a5,sstatus
ffffffffc020365e:	8b89                	andi	a5,a5,2
ffffffffc0203660:	eb89                	bnez	a5,ffffffffc0203672 <pgdir_alloc_page+0x8a>
        pmm_manager->free_pages(base, n);
ffffffffc0203662:	0009b783          	ld	a5,0(s3)
ffffffffc0203666:	8522                	mv	a0,s0
ffffffffc0203668:	4585                	li	a1,1
ffffffffc020366a:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc020366c:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc020366e:	9782                	jalr	a5
    if (flag)
ffffffffc0203670:	b7c9                	j	ffffffffc0203632 <pgdir_alloc_page+0x4a>
        intr_disable();
ffffffffc0203672:	b42fd0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
ffffffffc0203676:	0009b783          	ld	a5,0(s3)
ffffffffc020367a:	8522                	mv	a0,s0
ffffffffc020367c:	4585                	li	a1,1
ffffffffc020367e:	739c                	ld	a5,32(a5)
            return NULL;
ffffffffc0203680:	4401                	li	s0,0
        pmm_manager->free_pages(base, n);
ffffffffc0203682:	9782                	jalr	a5
        intr_enable();
ffffffffc0203684:	b2afd0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0203688:	b76d                	j	ffffffffc0203632 <pgdir_alloc_page+0x4a>
        assert(page_ref(page) == 1);
ffffffffc020368a:	00003697          	auipc	a3,0x3
ffffffffc020368e:	6ae68693          	addi	a3,a3,1710 # ffffffffc0206d38 <default_pmm_manager+0x760>
ffffffffc0203692:	00003617          	auipc	a2,0x3
ffffffffc0203696:	b9660613          	addi	a2,a2,-1130 # ffffffffc0206228 <commands+0x800>
ffffffffc020369a:	1fe00593          	li	a1,510
ffffffffc020369e:	00003517          	auipc	a0,0x3
ffffffffc02036a2:	08a50513          	addi	a0,a0,138 # ffffffffc0206728 <default_pmm_manager+0x150>
ffffffffc02036a6:	de9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036aa <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036aa:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02036ac:	00003697          	auipc	a3,0x3
ffffffffc02036b0:	6a468693          	addi	a3,a3,1700 # ffffffffc0206d50 <default_pmm_manager+0x778>
ffffffffc02036b4:	00003617          	auipc	a2,0x3
ffffffffc02036b8:	b7460613          	addi	a2,a2,-1164 # ffffffffc0206228 <commands+0x800>
ffffffffc02036bc:	07500593          	li	a1,117
ffffffffc02036c0:	00003517          	auipc	a0,0x3
ffffffffc02036c4:	6b050513          	addi	a0,a0,1712 # ffffffffc0206d70 <default_pmm_manager+0x798>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036c8:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036ca:	dc5fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02036ce <mm_create>:
{
ffffffffc02036ce:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036d0:	04000513          	li	a0,64
{
ffffffffc02036d4:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036d6:	e18fe0ef          	jal	ra,ffffffffc0201cee <kmalloc>
    if (mm != NULL)
ffffffffc02036da:	cd19                	beqz	a0,ffffffffc02036f8 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036dc:	e508                	sd	a0,8(a0)
ffffffffc02036de:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036e0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036e4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036e8:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036ec:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036f0:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc02036f4:	02053c23          	sd	zero,56(a0)
}
ffffffffc02036f8:	60a2                	ld	ra,8(sp)
ffffffffc02036fa:	0141                	addi	sp,sp,16
ffffffffc02036fc:	8082                	ret

ffffffffc02036fe <find_vma>:
{
ffffffffc02036fe:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0203700:	c505                	beqz	a0,ffffffffc0203728 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0203702:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203704:	c501                	beqz	a0,ffffffffc020370c <find_vma+0xe>
ffffffffc0203706:	651c                	ld	a5,8(a0)
ffffffffc0203708:	02f5f263          	bgeu	a1,a5,ffffffffc020372c <find_vma+0x2e>
    return listelm->next;
ffffffffc020370c:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc020370e:	00f68d63          	beq	a3,a5,ffffffffc0203728 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203712:	fe87b703          	ld	a4,-24(a5) # fe8 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0203716:	00e5e663          	bltu	a1,a4,ffffffffc0203722 <find_vma+0x24>
ffffffffc020371a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020371e:	00e5ec63          	bltu	a1,a4,ffffffffc0203736 <find_vma+0x38>
ffffffffc0203722:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203724:	fef697e3          	bne	a3,a5,ffffffffc0203712 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0203728:	4501                	li	a0,0
}
ffffffffc020372a:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020372c:	691c                	ld	a5,16(a0)
ffffffffc020372e:	fcf5ffe3          	bgeu	a1,a5,ffffffffc020370c <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0203732:	ea88                	sd	a0,16(a3)
ffffffffc0203734:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203736:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc020373a:	ea88                	sd	a0,16(a3)
ffffffffc020373c:	8082                	ret

ffffffffc020373e <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020373e:	6590                	ld	a2,8(a1)
ffffffffc0203740:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203744:	1141                	addi	sp,sp,-16
ffffffffc0203746:	e406                	sd	ra,8(sp)
ffffffffc0203748:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020374a:	01066763          	bltu	a2,a6,ffffffffc0203758 <insert_vma_struct+0x1a>
ffffffffc020374e:	a085                	j	ffffffffc02037ae <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203750:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203754:	04e66863          	bltu	a2,a4,ffffffffc02037a4 <insert_vma_struct+0x66>
ffffffffc0203758:	86be                	mv	a3,a5
ffffffffc020375a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020375c:	fef51ae3          	bne	a0,a5,ffffffffc0203750 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203760:	02a68463          	beq	a3,a0,ffffffffc0203788 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203764:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203768:	fe86b883          	ld	a7,-24(a3)
ffffffffc020376c:	08e8f163          	bgeu	a7,a4,ffffffffc02037ee <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203770:	04e66f63          	bltu	a2,a4,ffffffffc02037ce <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0203774:	00f50a63          	beq	a0,a5,ffffffffc0203788 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0203778:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020377c:	05076963          	bltu	a4,a6,ffffffffc02037ce <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0203780:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203784:	02c77363          	bgeu	a4,a2,ffffffffc02037aa <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203788:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc020378a:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020378c:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203790:	e390                	sd	a2,0(a5)
ffffffffc0203792:	e690                	sd	a2,8(a3)
}
ffffffffc0203794:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0203796:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203798:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc020379a:	0017079b          	addiw	a5,a4,1
ffffffffc020379e:	d11c                	sw	a5,32(a0)
}
ffffffffc02037a0:	0141                	addi	sp,sp,16
ffffffffc02037a2:	8082                	ret
    if (le_prev != list)
ffffffffc02037a4:	fca690e3          	bne	a3,a0,ffffffffc0203764 <insert_vma_struct+0x26>
ffffffffc02037a8:	bfd1                	j	ffffffffc020377c <insert_vma_struct+0x3e>
ffffffffc02037aa:	f01ff0ef          	jal	ra,ffffffffc02036aa <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037ae:	00003697          	auipc	a3,0x3
ffffffffc02037b2:	5d268693          	addi	a3,a3,1490 # ffffffffc0206d80 <default_pmm_manager+0x7a8>
ffffffffc02037b6:	00003617          	auipc	a2,0x3
ffffffffc02037ba:	a7260613          	addi	a2,a2,-1422 # ffffffffc0206228 <commands+0x800>
ffffffffc02037be:	07b00593          	li	a1,123
ffffffffc02037c2:	00003517          	auipc	a0,0x3
ffffffffc02037c6:	5ae50513          	addi	a0,a0,1454 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc02037ca:	cc5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037ce:	00003697          	auipc	a3,0x3
ffffffffc02037d2:	5f268693          	addi	a3,a3,1522 # ffffffffc0206dc0 <default_pmm_manager+0x7e8>
ffffffffc02037d6:	00003617          	auipc	a2,0x3
ffffffffc02037da:	a5260613          	addi	a2,a2,-1454 # ffffffffc0206228 <commands+0x800>
ffffffffc02037de:	07400593          	li	a1,116
ffffffffc02037e2:	00003517          	auipc	a0,0x3
ffffffffc02037e6:	58e50513          	addi	a0,a0,1422 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc02037ea:	ca5fc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037ee:	00003697          	auipc	a3,0x3
ffffffffc02037f2:	5b268693          	addi	a3,a3,1458 # ffffffffc0206da0 <default_pmm_manager+0x7c8>
ffffffffc02037f6:	00003617          	auipc	a2,0x3
ffffffffc02037fa:	a3260613          	addi	a2,a2,-1486 # ffffffffc0206228 <commands+0x800>
ffffffffc02037fe:	07300593          	li	a1,115
ffffffffc0203802:	00003517          	auipc	a0,0x3
ffffffffc0203806:	56e50513          	addi	a0,a0,1390 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc020380a:	c85fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020380e <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020380e:	591c                	lw	a5,48(a0)
{
ffffffffc0203810:	1141                	addi	sp,sp,-16
ffffffffc0203812:	e406                	sd	ra,8(sp)
ffffffffc0203814:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203816:	e78d                	bnez	a5,ffffffffc0203840 <mm_destroy+0x32>
ffffffffc0203818:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020381a:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc020381c:	00a40c63          	beq	s0,a0,ffffffffc0203834 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203820:	6118                	ld	a4,0(a0)
ffffffffc0203822:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203824:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203826:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203828:	e398                	sd	a4,0(a5)
ffffffffc020382a:	d74fe0ef          	jal	ra,ffffffffc0201d9e <kfree>
    return listelm->next;
ffffffffc020382e:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc0203830:	fea418e3          	bne	s0,a0,ffffffffc0203820 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203834:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203836:	6402                	ld	s0,0(sp)
ffffffffc0203838:	60a2                	ld	ra,8(sp)
ffffffffc020383a:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc020383c:	d62fe06f          	j	ffffffffc0201d9e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0203840:	00003697          	auipc	a3,0x3
ffffffffc0203844:	5a068693          	addi	a3,a3,1440 # ffffffffc0206de0 <default_pmm_manager+0x808>
ffffffffc0203848:	00003617          	auipc	a2,0x3
ffffffffc020384c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206228 <commands+0x800>
ffffffffc0203850:	09f00593          	li	a1,159
ffffffffc0203854:	00003517          	auipc	a0,0x3
ffffffffc0203858:	51c50513          	addi	a0,a0,1308 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc020385c:	c33fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203860 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
ffffffffc0203860:	7139                	addi	sp,sp,-64
ffffffffc0203862:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203864:	6405                	lui	s0,0x1
ffffffffc0203866:	147d                	addi	s0,s0,-1
ffffffffc0203868:	77fd                	lui	a5,0xfffff
ffffffffc020386a:	9622                	add	a2,a2,s0
ffffffffc020386c:	962e                	add	a2,a2,a1
{
ffffffffc020386e:	f426                	sd	s1,40(sp)
ffffffffc0203870:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203872:	00f5f4b3          	and	s1,a1,a5
{
ffffffffc0203876:	f04a                	sd	s2,32(sp)
ffffffffc0203878:	ec4e                	sd	s3,24(sp)
ffffffffc020387a:	e852                	sd	s4,16(sp)
ffffffffc020387c:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020387e:	002005b7          	lui	a1,0x200
ffffffffc0203882:	00f67433          	and	s0,a2,a5
ffffffffc0203886:	06b4e363          	bltu	s1,a1,ffffffffc02038ec <mm_map+0x8c>
ffffffffc020388a:	0684f163          	bgeu	s1,s0,ffffffffc02038ec <mm_map+0x8c>
ffffffffc020388e:	4785                	li	a5,1
ffffffffc0203890:	07fe                	slli	a5,a5,0x1f
ffffffffc0203892:	0487ed63          	bltu	a5,s0,ffffffffc02038ec <mm_map+0x8c>
ffffffffc0203896:	89aa                	mv	s3,a0
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0203898:	cd21                	beqz	a0,ffffffffc02038f0 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020389a:	85a6                	mv	a1,s1
ffffffffc020389c:	8ab6                	mv	s5,a3
ffffffffc020389e:	8a3a                	mv	s4,a4
ffffffffc02038a0:	e5fff0ef          	jal	ra,ffffffffc02036fe <find_vma>
ffffffffc02038a4:	c501                	beqz	a0,ffffffffc02038ac <mm_map+0x4c>
ffffffffc02038a6:	651c                	ld	a5,8(a0)
ffffffffc02038a8:	0487e263          	bltu	a5,s0,ffffffffc02038ec <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038ac:	03000513          	li	a0,48
ffffffffc02038b0:	c3efe0ef          	jal	ra,ffffffffc0201cee <kmalloc>
ffffffffc02038b4:	892a                	mv	s2,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02038b6:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02038b8:	02090163          	beqz	s2,ffffffffc02038da <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02038bc:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02038be:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02038c2:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02038c6:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02038ca:	85ca                	mv	a1,s2
ffffffffc02038cc:	e73ff0ef          	jal	ra,ffffffffc020373e <insert_vma_struct>
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc02038d0:	4501                	li	a0,0
    if (vma_store != NULL)
ffffffffc02038d2:	000a0463          	beqz	s4,ffffffffc02038da <mm_map+0x7a>
        *vma_store = vma;
ffffffffc02038d6:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc02038da:	70e2                	ld	ra,56(sp)
ffffffffc02038dc:	7442                	ld	s0,48(sp)
ffffffffc02038de:	74a2                	ld	s1,40(sp)
ffffffffc02038e0:	7902                	ld	s2,32(sp)
ffffffffc02038e2:	69e2                	ld	s3,24(sp)
ffffffffc02038e4:	6a42                	ld	s4,16(sp)
ffffffffc02038e6:	6aa2                	ld	s5,8(sp)
ffffffffc02038e8:	6121                	addi	sp,sp,64
ffffffffc02038ea:	8082                	ret
        return -E_INVAL;
ffffffffc02038ec:	5575                	li	a0,-3
ffffffffc02038ee:	b7f5                	j	ffffffffc02038da <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc02038f0:	00003697          	auipc	a3,0x3
ffffffffc02038f4:	50868693          	addi	a3,a3,1288 # ffffffffc0206df8 <default_pmm_manager+0x820>
ffffffffc02038f8:	00003617          	auipc	a2,0x3
ffffffffc02038fc:	93060613          	addi	a2,a2,-1744 # ffffffffc0206228 <commands+0x800>
ffffffffc0203900:	0b400593          	li	a1,180
ffffffffc0203904:	00003517          	auipc	a0,0x3
ffffffffc0203908:	46c50513          	addi	a0,a0,1132 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc020390c:	b83fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203910 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203910:	7139                	addi	sp,sp,-64
ffffffffc0203912:	fc06                	sd	ra,56(sp)
ffffffffc0203914:	f822                	sd	s0,48(sp)
ffffffffc0203916:	f426                	sd	s1,40(sp)
ffffffffc0203918:	f04a                	sd	s2,32(sp)
ffffffffc020391a:	ec4e                	sd	s3,24(sp)
ffffffffc020391c:	e852                	sd	s4,16(sp)
ffffffffc020391e:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203920:	c52d                	beqz	a0,ffffffffc020398a <dup_mmap+0x7a>
ffffffffc0203922:	892a                	mv	s2,a0
ffffffffc0203924:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc0203926:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203928:	e595                	bnez	a1,ffffffffc0203954 <dup_mmap+0x44>
ffffffffc020392a:	a085                	j	ffffffffc020398a <dup_mmap+0x7a>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020392c:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc020392e:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ef0>
        vma->vm_end = vm_end;
ffffffffc0203932:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203936:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc020393a:	e05ff0ef          	jal	ra,ffffffffc020373e <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc020393e:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bb0>
ffffffffc0203942:	fe843603          	ld	a2,-24(s0)
ffffffffc0203946:	6c8c                	ld	a1,24(s1)
ffffffffc0203948:	01893503          	ld	a0,24(s2)
ffffffffc020394c:	4701                	li	a4,0
ffffffffc020394e:	a5dff0ef          	jal	ra,ffffffffc02033aa <copy_range>
ffffffffc0203952:	e105                	bnez	a0,ffffffffc0203972 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0203954:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203956:	02848863          	beq	s1,s0,ffffffffc0203986 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020395a:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020395e:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203962:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203966:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020396a:	b84fe0ef          	jal	ra,ffffffffc0201cee <kmalloc>
ffffffffc020396e:	85aa                	mv	a1,a0
    if (vma != NULL)
ffffffffc0203970:	fd55                	bnez	a0,ffffffffc020392c <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0203972:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203974:	70e2                	ld	ra,56(sp)
ffffffffc0203976:	7442                	ld	s0,48(sp)
ffffffffc0203978:	74a2                	ld	s1,40(sp)
ffffffffc020397a:	7902                	ld	s2,32(sp)
ffffffffc020397c:	69e2                	ld	s3,24(sp)
ffffffffc020397e:	6a42                	ld	s4,16(sp)
ffffffffc0203980:	6aa2                	ld	s5,8(sp)
ffffffffc0203982:	6121                	addi	sp,sp,64
ffffffffc0203984:	8082                	ret
    return 0;
ffffffffc0203986:	4501                	li	a0,0
ffffffffc0203988:	b7f5                	j	ffffffffc0203974 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc020398a:	00003697          	auipc	a3,0x3
ffffffffc020398e:	47e68693          	addi	a3,a3,1150 # ffffffffc0206e08 <default_pmm_manager+0x830>
ffffffffc0203992:	00003617          	auipc	a2,0x3
ffffffffc0203996:	89660613          	addi	a2,a2,-1898 # ffffffffc0206228 <commands+0x800>
ffffffffc020399a:	0d000593          	li	a1,208
ffffffffc020399e:	00003517          	auipc	a0,0x3
ffffffffc02039a2:	3d250513          	addi	a0,a0,978 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc02039a6:	ae9fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02039aa <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02039aa:	1101                	addi	sp,sp,-32
ffffffffc02039ac:	ec06                	sd	ra,24(sp)
ffffffffc02039ae:	e822                	sd	s0,16(sp)
ffffffffc02039b0:	e426                	sd	s1,8(sp)
ffffffffc02039b2:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039b4:	c531                	beqz	a0,ffffffffc0203a00 <exit_mmap+0x56>
ffffffffc02039b6:	591c                	lw	a5,48(a0)
ffffffffc02039b8:	84aa                	mv	s1,a0
ffffffffc02039ba:	e3b9                	bnez	a5,ffffffffc0203a00 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02039bc:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02039be:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02039c2:	02850663          	beq	a0,s0,ffffffffc02039ee <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039c6:	ff043603          	ld	a2,-16(s0)
ffffffffc02039ca:	fe843583          	ld	a1,-24(s0)
ffffffffc02039ce:	854a                	mv	a0,s2
ffffffffc02039d0:	831fe0ef          	jal	ra,ffffffffc0202200 <unmap_range>
ffffffffc02039d4:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039d6:	fe8498e3          	bne	s1,s0,ffffffffc02039c6 <exit_mmap+0x1c>
ffffffffc02039da:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc02039dc:	00848c63          	beq	s1,s0,ffffffffc02039f4 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039e0:	ff043603          	ld	a2,-16(s0)
ffffffffc02039e4:	fe843583          	ld	a1,-24(s0)
ffffffffc02039e8:	854a                	mv	a0,s2
ffffffffc02039ea:	95dfe0ef          	jal	ra,ffffffffc0202346 <exit_range>
ffffffffc02039ee:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039f0:	fe8498e3          	bne	s1,s0,ffffffffc02039e0 <exit_mmap+0x36>
    }
}
ffffffffc02039f4:	60e2                	ld	ra,24(sp)
ffffffffc02039f6:	6442                	ld	s0,16(sp)
ffffffffc02039f8:	64a2                	ld	s1,8(sp)
ffffffffc02039fa:	6902                	ld	s2,0(sp)
ffffffffc02039fc:	6105                	addi	sp,sp,32
ffffffffc02039fe:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a00:	00003697          	auipc	a3,0x3
ffffffffc0203a04:	42868693          	addi	a3,a3,1064 # ffffffffc0206e28 <default_pmm_manager+0x850>
ffffffffc0203a08:	00003617          	auipc	a2,0x3
ffffffffc0203a0c:	82060613          	addi	a2,a2,-2016 # ffffffffc0206228 <commands+0x800>
ffffffffc0203a10:	0e900593          	li	a1,233
ffffffffc0203a14:	00003517          	auipc	a0,0x3
ffffffffc0203a18:	35c50513          	addi	a0,a0,860 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203a1c:	a73fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203a20 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a20:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a22:	04000513          	li	a0,64
{
ffffffffc0203a26:	fc06                	sd	ra,56(sp)
ffffffffc0203a28:	f822                	sd	s0,48(sp)
ffffffffc0203a2a:	f426                	sd	s1,40(sp)
ffffffffc0203a2c:	f04a                	sd	s2,32(sp)
ffffffffc0203a2e:	ec4e                	sd	s3,24(sp)
ffffffffc0203a30:	e852                	sd	s4,16(sp)
ffffffffc0203a32:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a34:	abafe0ef          	jal	ra,ffffffffc0201cee <kmalloc>
    if (mm != NULL)
ffffffffc0203a38:	2e050663          	beqz	a0,ffffffffc0203d24 <vmm_init+0x304>
ffffffffc0203a3c:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0203a3e:	e508                	sd	a0,8(a0)
ffffffffc0203a40:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a42:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a46:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a4a:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a4e:	02053423          	sd	zero,40(a0)
ffffffffc0203a52:	02052823          	sw	zero,48(a0)
ffffffffc0203a56:	02053c23          	sd	zero,56(a0)
ffffffffc0203a5a:	03200413          	li	s0,50
ffffffffc0203a5e:	a811                	j	ffffffffc0203a72 <vmm_init+0x52>
        vma->vm_start = vm_start;
ffffffffc0203a60:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203a62:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a64:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0203a68:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a6a:	8526                	mv	a0,s1
ffffffffc0203a6c:	cd3ff0ef          	jal	ra,ffffffffc020373e <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203a70:	c80d                	beqz	s0,ffffffffc0203aa2 <vmm_init+0x82>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a72:	03000513          	li	a0,48
ffffffffc0203a76:	a78fe0ef          	jal	ra,ffffffffc0201cee <kmalloc>
ffffffffc0203a7a:	85aa                	mv	a1,a0
ffffffffc0203a7c:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203a80:	f165                	bnez	a0,ffffffffc0203a60 <vmm_init+0x40>
        assert(vma != NULL);
ffffffffc0203a82:	00003697          	auipc	a3,0x3
ffffffffc0203a86:	53e68693          	addi	a3,a3,1342 # ffffffffc0206fc0 <default_pmm_manager+0x9e8>
ffffffffc0203a8a:	00002617          	auipc	a2,0x2
ffffffffc0203a8e:	79e60613          	addi	a2,a2,1950 # ffffffffc0206228 <commands+0x800>
ffffffffc0203a92:	12d00593          	li	a1,301
ffffffffc0203a96:	00003517          	auipc	a0,0x3
ffffffffc0203a9a:	2da50513          	addi	a0,a0,730 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203a9e:	9f1fc0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0203aa2:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203aa6:	1f900913          	li	s2,505
ffffffffc0203aaa:	a819                	j	ffffffffc0203ac0 <vmm_init+0xa0>
        vma->vm_start = vm_start;
ffffffffc0203aac:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0203aae:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203ab0:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ab4:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ab6:	8526                	mv	a0,s1
ffffffffc0203ab8:	c87ff0ef          	jal	ra,ffffffffc020373e <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203abc:	03240a63          	beq	s0,s2,ffffffffc0203af0 <vmm_init+0xd0>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ac0:	03000513          	li	a0,48
ffffffffc0203ac4:	a2afe0ef          	jal	ra,ffffffffc0201cee <kmalloc>
ffffffffc0203ac8:	85aa                	mv	a1,a0
ffffffffc0203aca:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0203ace:	fd79                	bnez	a0,ffffffffc0203aac <vmm_init+0x8c>
        assert(vma != NULL);
ffffffffc0203ad0:	00003697          	auipc	a3,0x3
ffffffffc0203ad4:	4f068693          	addi	a3,a3,1264 # ffffffffc0206fc0 <default_pmm_manager+0x9e8>
ffffffffc0203ad8:	00002617          	auipc	a2,0x2
ffffffffc0203adc:	75060613          	addi	a2,a2,1872 # ffffffffc0206228 <commands+0x800>
ffffffffc0203ae0:	13400593          	li	a1,308
ffffffffc0203ae4:	00003517          	auipc	a0,0x3
ffffffffc0203ae8:	28c50513          	addi	a0,a0,652 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203aec:	9a3fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return listelm->next;
ffffffffc0203af0:	649c                	ld	a5,8(s1)
ffffffffc0203af2:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203af4:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203af8:	16f48663          	beq	s1,a5,ffffffffc0203c64 <vmm_init+0x244>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203afc:	fe87b603          	ld	a2,-24(a5) # ffffffffffffefe8 <end+0x3fd54904>
ffffffffc0203b00:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b04:	10d61063          	bne	a2,a3,ffffffffc0203c04 <vmm_init+0x1e4>
ffffffffc0203b08:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b0c:	0ed71c63          	bne	a4,a3,ffffffffc0203c04 <vmm_init+0x1e4>
    for (i = 1; i <= step2; i++)
ffffffffc0203b10:	0715                	addi	a4,a4,5
ffffffffc0203b12:	679c                	ld	a5,8(a5)
ffffffffc0203b14:	feb712e3          	bne	a4,a1,ffffffffc0203af8 <vmm_init+0xd8>
ffffffffc0203b18:	4a1d                	li	s4,7
ffffffffc0203b1a:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b1c:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b20:	85a2                	mv	a1,s0
ffffffffc0203b22:	8526                	mv	a0,s1
ffffffffc0203b24:	bdbff0ef          	jal	ra,ffffffffc02036fe <find_vma>
ffffffffc0203b28:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0203b2a:	16050d63          	beqz	a0,ffffffffc0203ca4 <vmm_init+0x284>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b2e:	00140593          	addi	a1,s0,1
ffffffffc0203b32:	8526                	mv	a0,s1
ffffffffc0203b34:	bcbff0ef          	jal	ra,ffffffffc02036fe <find_vma>
ffffffffc0203b38:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b3a:	14050563          	beqz	a0,ffffffffc0203c84 <vmm_init+0x264>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b3e:	85d2                	mv	a1,s4
ffffffffc0203b40:	8526                	mv	a0,s1
ffffffffc0203b42:	bbdff0ef          	jal	ra,ffffffffc02036fe <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b46:	16051f63          	bnez	a0,ffffffffc0203cc4 <vmm_init+0x2a4>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b4a:	00340593          	addi	a1,s0,3
ffffffffc0203b4e:	8526                	mv	a0,s1
ffffffffc0203b50:	bafff0ef          	jal	ra,ffffffffc02036fe <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b54:	1a051863          	bnez	a0,ffffffffc0203d04 <vmm_init+0x2e4>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b58:	00440593          	addi	a1,s0,4
ffffffffc0203b5c:	8526                	mv	a0,s1
ffffffffc0203b5e:	ba1ff0ef          	jal	ra,ffffffffc02036fe <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b62:	18051163          	bnez	a0,ffffffffc0203ce4 <vmm_init+0x2c4>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b66:	00893783          	ld	a5,8(s2)
ffffffffc0203b6a:	0a879d63          	bne	a5,s0,ffffffffc0203c24 <vmm_init+0x204>
ffffffffc0203b6e:	01093783          	ld	a5,16(s2)
ffffffffc0203b72:	0b479963          	bne	a5,s4,ffffffffc0203c24 <vmm_init+0x204>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b76:	0089b783          	ld	a5,8(s3)
ffffffffc0203b7a:	0c879563          	bne	a5,s0,ffffffffc0203c44 <vmm_init+0x224>
ffffffffc0203b7e:	0109b783          	ld	a5,16(s3)
ffffffffc0203b82:	0d479163          	bne	a5,s4,ffffffffc0203c44 <vmm_init+0x224>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b86:	0415                	addi	s0,s0,5
ffffffffc0203b88:	0a15                	addi	s4,s4,5
ffffffffc0203b8a:	f9541be3          	bne	s0,s5,ffffffffc0203b20 <vmm_init+0x100>
ffffffffc0203b8e:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b90:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b92:	85a2                	mv	a1,s0
ffffffffc0203b94:	8526                	mv	a0,s1
ffffffffc0203b96:	b69ff0ef          	jal	ra,ffffffffc02036fe <find_vma>
ffffffffc0203b9a:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0203b9e:	c90d                	beqz	a0,ffffffffc0203bd0 <vmm_init+0x1b0>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203ba0:	6914                	ld	a3,16(a0)
ffffffffc0203ba2:	6510                	ld	a2,8(a0)
ffffffffc0203ba4:	00003517          	auipc	a0,0x3
ffffffffc0203ba8:	3a450513          	addi	a0,a0,932 # ffffffffc0206f48 <default_pmm_manager+0x970>
ffffffffc0203bac:	de8fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203bb0:	00003697          	auipc	a3,0x3
ffffffffc0203bb4:	3c068693          	addi	a3,a3,960 # ffffffffc0206f70 <default_pmm_manager+0x998>
ffffffffc0203bb8:	00002617          	auipc	a2,0x2
ffffffffc0203bbc:	67060613          	addi	a2,a2,1648 # ffffffffc0206228 <commands+0x800>
ffffffffc0203bc0:	15a00593          	li	a1,346
ffffffffc0203bc4:	00003517          	auipc	a0,0x3
ffffffffc0203bc8:	1ac50513          	addi	a0,a0,428 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203bcc:	8c3fc0ef          	jal	ra,ffffffffc020048e <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203bd0:	147d                	addi	s0,s0,-1
ffffffffc0203bd2:	fd2410e3          	bne	s0,s2,ffffffffc0203b92 <vmm_init+0x172>
    }

    mm_destroy(mm);
ffffffffc0203bd6:	8526                	mv	a0,s1
ffffffffc0203bd8:	c37ff0ef          	jal	ra,ffffffffc020380e <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bdc:	00003517          	auipc	a0,0x3
ffffffffc0203be0:	3ac50513          	addi	a0,a0,940 # ffffffffc0206f88 <default_pmm_manager+0x9b0>
ffffffffc0203be4:	db0fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203be8:	7442                	ld	s0,48(sp)
ffffffffc0203bea:	70e2                	ld	ra,56(sp)
ffffffffc0203bec:	74a2                	ld	s1,40(sp)
ffffffffc0203bee:	7902                	ld	s2,32(sp)
ffffffffc0203bf0:	69e2                	ld	s3,24(sp)
ffffffffc0203bf2:	6a42                	ld	s4,16(sp)
ffffffffc0203bf4:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bf6:	00003517          	auipc	a0,0x3
ffffffffc0203bfa:	3b250513          	addi	a0,a0,946 # ffffffffc0206fa8 <default_pmm_manager+0x9d0>
}
ffffffffc0203bfe:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c00:	d94fc06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c04:	00003697          	auipc	a3,0x3
ffffffffc0203c08:	25c68693          	addi	a3,a3,604 # ffffffffc0206e60 <default_pmm_manager+0x888>
ffffffffc0203c0c:	00002617          	auipc	a2,0x2
ffffffffc0203c10:	61c60613          	addi	a2,a2,1564 # ffffffffc0206228 <commands+0x800>
ffffffffc0203c14:	13e00593          	li	a1,318
ffffffffc0203c18:	00003517          	auipc	a0,0x3
ffffffffc0203c1c:	15850513          	addi	a0,a0,344 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203c20:	86ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c24:	00003697          	auipc	a3,0x3
ffffffffc0203c28:	2c468693          	addi	a3,a3,708 # ffffffffc0206ee8 <default_pmm_manager+0x910>
ffffffffc0203c2c:	00002617          	auipc	a2,0x2
ffffffffc0203c30:	5fc60613          	addi	a2,a2,1532 # ffffffffc0206228 <commands+0x800>
ffffffffc0203c34:	14f00593          	li	a1,335
ffffffffc0203c38:	00003517          	auipc	a0,0x3
ffffffffc0203c3c:	13850513          	addi	a0,a0,312 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203c40:	84ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c44:	00003697          	auipc	a3,0x3
ffffffffc0203c48:	2d468693          	addi	a3,a3,724 # ffffffffc0206f18 <default_pmm_manager+0x940>
ffffffffc0203c4c:	00002617          	auipc	a2,0x2
ffffffffc0203c50:	5dc60613          	addi	a2,a2,1500 # ffffffffc0206228 <commands+0x800>
ffffffffc0203c54:	15000593          	li	a1,336
ffffffffc0203c58:	00003517          	auipc	a0,0x3
ffffffffc0203c5c:	11850513          	addi	a0,a0,280 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203c60:	82ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203c64:	00003697          	auipc	a3,0x3
ffffffffc0203c68:	1e468693          	addi	a3,a3,484 # ffffffffc0206e48 <default_pmm_manager+0x870>
ffffffffc0203c6c:	00002617          	auipc	a2,0x2
ffffffffc0203c70:	5bc60613          	addi	a2,a2,1468 # ffffffffc0206228 <commands+0x800>
ffffffffc0203c74:	13c00593          	li	a1,316
ffffffffc0203c78:	00003517          	auipc	a0,0x3
ffffffffc0203c7c:	0f850513          	addi	a0,a0,248 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203c80:	80ffc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203c84:	00003697          	auipc	a3,0x3
ffffffffc0203c88:	22468693          	addi	a3,a3,548 # ffffffffc0206ea8 <default_pmm_manager+0x8d0>
ffffffffc0203c8c:	00002617          	auipc	a2,0x2
ffffffffc0203c90:	59c60613          	addi	a2,a2,1436 # ffffffffc0206228 <commands+0x800>
ffffffffc0203c94:	14700593          	li	a1,327
ffffffffc0203c98:	00003517          	auipc	a0,0x3
ffffffffc0203c9c:	0d850513          	addi	a0,a0,216 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203ca0:	feefc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203ca4:	00003697          	auipc	a3,0x3
ffffffffc0203ca8:	1f468693          	addi	a3,a3,500 # ffffffffc0206e98 <default_pmm_manager+0x8c0>
ffffffffc0203cac:	00002617          	auipc	a2,0x2
ffffffffc0203cb0:	57c60613          	addi	a2,a2,1404 # ffffffffc0206228 <commands+0x800>
ffffffffc0203cb4:	14500593          	li	a1,325
ffffffffc0203cb8:	00003517          	auipc	a0,0x3
ffffffffc0203cbc:	0b850513          	addi	a0,a0,184 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203cc0:	fcefc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203cc4:	00003697          	auipc	a3,0x3
ffffffffc0203cc8:	1f468693          	addi	a3,a3,500 # ffffffffc0206eb8 <default_pmm_manager+0x8e0>
ffffffffc0203ccc:	00002617          	auipc	a2,0x2
ffffffffc0203cd0:	55c60613          	addi	a2,a2,1372 # ffffffffc0206228 <commands+0x800>
ffffffffc0203cd4:	14900593          	li	a1,329
ffffffffc0203cd8:	00003517          	auipc	a0,0x3
ffffffffc0203cdc:	09850513          	addi	a0,a0,152 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203ce0:	faefc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203ce4:	00003697          	auipc	a3,0x3
ffffffffc0203ce8:	1f468693          	addi	a3,a3,500 # ffffffffc0206ed8 <default_pmm_manager+0x900>
ffffffffc0203cec:	00002617          	auipc	a2,0x2
ffffffffc0203cf0:	53c60613          	addi	a2,a2,1340 # ffffffffc0206228 <commands+0x800>
ffffffffc0203cf4:	14d00593          	li	a1,333
ffffffffc0203cf8:	00003517          	auipc	a0,0x3
ffffffffc0203cfc:	07850513          	addi	a0,a0,120 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203d00:	f8efc0ef          	jal	ra,ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203d04:	00003697          	auipc	a3,0x3
ffffffffc0203d08:	1c468693          	addi	a3,a3,452 # ffffffffc0206ec8 <default_pmm_manager+0x8f0>
ffffffffc0203d0c:	00002617          	auipc	a2,0x2
ffffffffc0203d10:	51c60613          	addi	a2,a2,1308 # ffffffffc0206228 <commands+0x800>
ffffffffc0203d14:	14b00593          	li	a1,331
ffffffffc0203d18:	00003517          	auipc	a0,0x3
ffffffffc0203d1c:	05850513          	addi	a0,a0,88 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203d20:	f6efc0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203d24:	00003697          	auipc	a3,0x3
ffffffffc0203d28:	0d468693          	addi	a3,a3,212 # ffffffffc0206df8 <default_pmm_manager+0x820>
ffffffffc0203d2c:	00002617          	auipc	a2,0x2
ffffffffc0203d30:	4fc60613          	addi	a2,a2,1276 # ffffffffc0206228 <commands+0x800>
ffffffffc0203d34:	12500593          	li	a1,293
ffffffffc0203d38:	00003517          	auipc	a0,0x3
ffffffffc0203d3c:	03850513          	addi	a0,a0,56 # ffffffffc0206d70 <default_pmm_manager+0x798>
ffffffffc0203d40:	f4efc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203d44 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d44:	7179                	addi	sp,sp,-48
ffffffffc0203d46:	f022                	sd	s0,32(sp)
ffffffffc0203d48:	f406                	sd	ra,40(sp)
ffffffffc0203d4a:	ec26                	sd	s1,24(sp)
ffffffffc0203d4c:	e84a                	sd	s2,16(sp)
ffffffffc0203d4e:	e44e                	sd	s3,8(sp)
ffffffffc0203d50:	e052                	sd	s4,0(sp)
ffffffffc0203d52:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d54:	c135                	beqz	a0,ffffffffc0203db8 <user_mem_check+0x74>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d56:	002007b7          	lui	a5,0x200
ffffffffc0203d5a:	04f5e663          	bltu	a1,a5,ffffffffc0203da6 <user_mem_check+0x62>
ffffffffc0203d5e:	00c584b3          	add	s1,a1,a2
ffffffffc0203d62:	0495f263          	bgeu	a1,s1,ffffffffc0203da6 <user_mem_check+0x62>
ffffffffc0203d66:	4785                	li	a5,1
ffffffffc0203d68:	07fe                	slli	a5,a5,0x1f
ffffffffc0203d6a:	0297ee63          	bltu	a5,s1,ffffffffc0203da6 <user_mem_check+0x62>
ffffffffc0203d6e:	892a                	mv	s2,a0
ffffffffc0203d70:	89b6                	mv	s3,a3
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d72:	6a05                	lui	s4,0x1
ffffffffc0203d74:	a821                	j	ffffffffc0203d8c <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d76:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d7a:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d7c:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d7e:	c685                	beqz	a3,ffffffffc0203da6 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203d80:	c399                	beqz	a5,ffffffffc0203d86 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d82:	02e46263          	bltu	s0,a4,ffffffffc0203da6 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203d86:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203d88:	04947663          	bgeu	s0,s1,ffffffffc0203dd4 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203d8c:	85a2                	mv	a1,s0
ffffffffc0203d8e:	854a                	mv	a0,s2
ffffffffc0203d90:	96fff0ef          	jal	ra,ffffffffc02036fe <find_vma>
ffffffffc0203d94:	c909                	beqz	a0,ffffffffc0203da6 <user_mem_check+0x62>
ffffffffc0203d96:	6518                	ld	a4,8(a0)
ffffffffc0203d98:	00e46763          	bltu	s0,a4,ffffffffc0203da6 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d9c:	4d1c                	lw	a5,24(a0)
ffffffffc0203d9e:	fc099ce3          	bnez	s3,ffffffffc0203d76 <user_mem_check+0x32>
ffffffffc0203da2:	8b85                	andi	a5,a5,1
ffffffffc0203da4:	f3ed                	bnez	a5,ffffffffc0203d86 <user_mem_check+0x42>
            return 0;
ffffffffc0203da6:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203da8:	70a2                	ld	ra,40(sp)
ffffffffc0203daa:	7402                	ld	s0,32(sp)
ffffffffc0203dac:	64e2                	ld	s1,24(sp)
ffffffffc0203dae:	6942                	ld	s2,16(sp)
ffffffffc0203db0:	69a2                	ld	s3,8(sp)
ffffffffc0203db2:	6a02                	ld	s4,0(sp)
ffffffffc0203db4:	6145                	addi	sp,sp,48
ffffffffc0203db6:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203db8:	c02007b7          	lui	a5,0xc0200
ffffffffc0203dbc:	4501                	li	a0,0
ffffffffc0203dbe:	fef5e5e3          	bltu	a1,a5,ffffffffc0203da8 <user_mem_check+0x64>
ffffffffc0203dc2:	962e                	add	a2,a2,a1
ffffffffc0203dc4:	fec5f2e3          	bgeu	a1,a2,ffffffffc0203da8 <user_mem_check+0x64>
ffffffffc0203dc8:	c8000537          	lui	a0,0xc8000
ffffffffc0203dcc:	0505                	addi	a0,a0,1
ffffffffc0203dce:	00a63533          	sltu	a0,a2,a0
ffffffffc0203dd2:	bfd9                	j	ffffffffc0203da8 <user_mem_check+0x64>
        return 1;
ffffffffc0203dd4:	4505                	li	a0,1
ffffffffc0203dd6:	bfc9                	j	ffffffffc0203da8 <user_mem_check+0x64>

ffffffffc0203dd8 <do_pgfault>:
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0203dd8:	7179                	addi	sp,sp,-48
ffffffffc0203dda:	f406                	sd	ra,40(sp)
ffffffffc0203ddc:	f022                	sd	s0,32(sp)
ffffffffc0203dde:	ec26                	sd	s1,24(sp)
ffffffffc0203de0:	e84a                	sd	s2,16(sp)
ffffffffc0203de2:	e44e                	sd	s3,8(sp)
    // 只处理用户态缺页
    if (mm == NULL) {
ffffffffc0203de4:	cd71                	beqz	a0,ffffffffc0203ec0 <do_pgfault+0xe8>
ffffffffc0203de6:	89ae                	mv	s3,a1
        return -E_INVAL;
    }

    // 在 vma 里找这个地址
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0203de8:	85b2                	mv	a1,a2
ffffffffc0203dea:	892a                	mv	s2,a0
ffffffffc0203dec:	84b2                	mv	s1,a2
ffffffffc0203dee:	911ff0ef          	jal	ra,ffffffffc02036fe <find_vma>
ffffffffc0203df2:	842a                	mv	s0,a0
    if (vma == NULL || addr < vma->vm_start) {
ffffffffc0203df4:	c571                	beqz	a0,ffffffffc0203ec0 <do_pgfault+0xe8>
ffffffffc0203df6:	651c                	ld	a5,8(a0)
ffffffffc0203df8:	0cf4e463          	bltu	s1,a5,ffffffffc0203ec0 <do_pgfault+0xe8>
        return -E_INVAL;
    }

    // 权限检查：写缺页必须 VM_WRITE
    bool write = (error_code == CAUSE_STORE_PAGE_FAULT);
    if (write && !(vma->vm_flags & VM_WRITE)) {
ffffffffc0203dfc:	473d                	li	a4,15
ffffffffc0203dfe:	4d1c                	lw	a5,24(a0)
ffffffffc0203e00:	0ae98e63          	beq	s3,a4,ffffffffc0203ebc <do_pgfault+0xe4>
        return -E_INVAL;
    }
    if (!write && !(vma->vm_flags & (VM_READ | VM_EXEC))) {
ffffffffc0203e04:	8b95                	andi	a5,a5,5
ffffffffc0203e06:	cfcd                	beqz	a5,ffffffffc0203ec0 <do_pgfault+0xe8>

    // 对齐到页
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);

    // 分配物理页并建立映射
    struct Page *page = alloc_page();
ffffffffc0203e08:	4505                	li	a0,1
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203e0a:	79fd                	lui	s3,0xfffff
    struct Page *page = alloc_page();
ffffffffc0203e0c:	8c0fe0ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
ffffffffc0203e10:	0134f9b3          	and	s3,s1,s3
    struct Page *page = alloc_page();
ffffffffc0203e14:	84aa                	mv	s1,a0
    if (page == NULL) {
ffffffffc0203e16:	c55d                	beqz	a0,ffffffffc0203ec4 <do_pgfault+0xec>
    return page - pages + nbase;
ffffffffc0203e18:	000a7697          	auipc	a3,0xa7
ffffffffc0203e1c:	8986b683          	ld	a3,-1896(a3) # ffffffffc02aa6b0 <pages>
ffffffffc0203e20:	40d506b3          	sub	a3,a0,a3
ffffffffc0203e24:	8699                	srai	a3,a3,0x6
ffffffffc0203e26:	00004517          	auipc	a0,0x4
ffffffffc0203e2a:	aaa53503          	ld	a0,-1366(a0) # ffffffffc02078d0 <nbase>
ffffffffc0203e2e:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0203e30:	00c69793          	slli	a5,a3,0xc
ffffffffc0203e34:	83b1                	srli	a5,a5,0xc
ffffffffc0203e36:	000a7717          	auipc	a4,0xa7
ffffffffc0203e3a:	87273703          	ld	a4,-1934(a4) # ffffffffc02aa6a8 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0203e3e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203e40:	08e7f463          	bgeu	a5,a4,ffffffffc0203ec8 <do_pgfault+0xf0>
        return -E_NO_MEM;
    }

    // 清零（bss 依赖这一步）
    void *kva = page2kva(page);
    memset(kva, 0, PGSIZE);
ffffffffc0203e44:	000a7517          	auipc	a0,0xa7
ffffffffc0203e48:	87c53503          	ld	a0,-1924(a0) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0203e4c:	9536                	add	a0,a0,a3
ffffffffc0203e4e:	6605                	lui	a2,0x1
ffffffffc0203e50:	4581                	li	a1,0
ffffffffc0203e52:	141010ef          	jal	ra,ffffffffc0205792 <memset>

    // 根据 vma flags 生成 PTE 权限
    uint32_t perm = PTE_U | PTE_V;
    if (vma->vm_flags & VM_READ)  perm |= PTE_R;
ffffffffc0203e56:	4c1c                	lw	a5,24(s0)
    uint32_t perm = PTE_U | PTE_V;
ffffffffc0203e58:	46c5                	li	a3,17
    if (vma->vm_flags & VM_READ)  perm |= PTE_R;
ffffffffc0203e5a:	0017f713          	andi	a4,a5,1
ffffffffc0203e5e:	c311                	beqz	a4,ffffffffc0203e62 <do_pgfault+0x8a>
ffffffffc0203e60:	46cd                	li	a3,19
    if (vma->vm_flags & VM_WRITE) perm |= PTE_W;
ffffffffc0203e62:	0027f713          	andi	a4,a5,2
ffffffffc0203e66:	c319                	beqz	a4,ffffffffc0203e6c <do_pgfault+0x94>
ffffffffc0203e68:	0046e693          	ori	a3,a3,4
    if (vma->vm_flags & VM_EXEC)  perm |= PTE_X;
ffffffffc0203e6c:	8b91                	andi	a5,a5,4
ffffffffc0203e6e:	e38d                	bnez	a5,ffffffffc0203e90 <do_pgfault+0xb8>

    int ret = page_insert(mm->pgdir, page, la, perm);
ffffffffc0203e70:	01893503          	ld	a0,24(s2)
ffffffffc0203e74:	864e                	mv	a2,s3
ffffffffc0203e76:	85a6                	mv	a1,s1
ffffffffc0203e78:	ffcfe0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc0203e7c:	842a                	mv	s0,a0
    if (ret != 0) {
ffffffffc0203e7e:	e11d                	bnez	a0,ffffffffc0203ea4 <do_pgfault+0xcc>
        free_page(page);
        return ret;
    }

    return 0;
}
ffffffffc0203e80:	70a2                	ld	ra,40(sp)
ffffffffc0203e82:	8522                	mv	a0,s0
ffffffffc0203e84:	7402                	ld	s0,32(sp)
ffffffffc0203e86:	64e2                	ld	s1,24(sp)
ffffffffc0203e88:	6942                	ld	s2,16(sp)
ffffffffc0203e8a:	69a2                	ld	s3,8(sp)
ffffffffc0203e8c:	6145                	addi	sp,sp,48
ffffffffc0203e8e:	8082                	ret
    int ret = page_insert(mm->pgdir, page, la, perm);
ffffffffc0203e90:	01893503          	ld	a0,24(s2)
    if (vma->vm_flags & VM_EXEC)  perm |= PTE_X;
ffffffffc0203e94:	0086e693          	ori	a3,a3,8
    int ret = page_insert(mm->pgdir, page, la, perm);
ffffffffc0203e98:	864e                	mv	a2,s3
ffffffffc0203e9a:	85a6                	mv	a1,s1
ffffffffc0203e9c:	fd8fe0ef          	jal	ra,ffffffffc0202674 <page_insert>
ffffffffc0203ea0:	842a                	mv	s0,a0
    if (ret != 0) {
ffffffffc0203ea2:	dd79                	beqz	a0,ffffffffc0203e80 <do_pgfault+0xa8>
        free_page(page);
ffffffffc0203ea4:	8526                	mv	a0,s1
ffffffffc0203ea6:	4585                	li	a1,1
ffffffffc0203ea8:	862fe0ef          	jal	ra,ffffffffc0201f0a <free_pages>
}
ffffffffc0203eac:	70a2                	ld	ra,40(sp)
ffffffffc0203eae:	8522                	mv	a0,s0
ffffffffc0203eb0:	7402                	ld	s0,32(sp)
ffffffffc0203eb2:	64e2                	ld	s1,24(sp)
ffffffffc0203eb4:	6942                	ld	s2,16(sp)
ffffffffc0203eb6:	69a2                	ld	s3,8(sp)
ffffffffc0203eb8:	6145                	addi	sp,sp,48
ffffffffc0203eba:	8082                	ret
    if (write && !(vma->vm_flags & VM_WRITE)) {
ffffffffc0203ebc:	8b89                	andi	a5,a5,2
ffffffffc0203ebe:	f7a9                	bnez	a5,ffffffffc0203e08 <do_pgfault+0x30>
        return -E_INVAL;
ffffffffc0203ec0:	5475                	li	s0,-3
ffffffffc0203ec2:	bf7d                	j	ffffffffc0203e80 <do_pgfault+0xa8>
        return -E_NO_MEM;
ffffffffc0203ec4:	5471                	li	s0,-4
ffffffffc0203ec6:	bf6d                	j	ffffffffc0203e80 <do_pgfault+0xa8>
ffffffffc0203ec8:	00002617          	auipc	a2,0x2
ffffffffc0203ecc:	74860613          	addi	a2,a2,1864 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0203ed0:	07100593          	li	a1,113
ffffffffc0203ed4:	00002517          	auipc	a0,0x2
ffffffffc0203ed8:	76450513          	addi	a0,a0,1892 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0203edc:	db2fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ee0 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203ee0:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203ee2:	9402                	jalr	s0

	jal do_exit
ffffffffc0203ee4:	5e2000ef          	jal	ra,ffffffffc02044c6 <do_exit>

ffffffffc0203ee8 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203ee8:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203eea:	10800513          	li	a0,264
{
ffffffffc0203eee:	e022                	sd	s0,0(sp)
ffffffffc0203ef0:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203ef2:	dfdfd0ef          	jal	ra,ffffffffc0201cee <kmalloc>
ffffffffc0203ef6:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203ef8:	c525                	beqz	a0,ffffffffc0203f60 <alloc_proc+0x78>
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        // 初始化进程控制块的所有字段
        // 初始化进程状态为未初始化
        proc->state = PROC_UNINIT;
ffffffffc0203efa:	57fd                	li	a5,-1
ffffffffc0203efc:	1782                	slli	a5,a5,0x20
ffffffffc0203efe:	e11c                	sd	a5,0(a0)
        // 父进程指针为空
        proc->parent = NULL;
        // 内存管理结构为空（内核线程无需独立mm）
        proc->mm = NULL;
        // 上下文寄存器全部清零
        memset(&proc->context, 0, sizeof(struct context));
ffffffffc0203f00:	07000613          	li	a2,112
ffffffffc0203f04:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0203f06:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203f0a:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203f0e:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203f12:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203f16:	02053423          	sd	zero,40(a0)
        memset(&proc->context, 0, sizeof(struct context));
ffffffffc0203f1a:	03050513          	addi	a0,a0,48
ffffffffc0203f1e:	075010ef          	jal	ra,ffffffffc0205792 <memset>
        // 中断帧指针为空
        proc->tf = NULL;
        // 页目录表基址复用内核页表（内核线程共享）
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203f22:	000a6797          	auipc	a5,0xa6
ffffffffc0203f26:	7767b783          	ld	a5,1910(a5) # ffffffffc02aa698 <boot_pgdir_pa>
ffffffffc0203f2a:	f45c                	sd	a5,168(s0)
        proc->tf = NULL;
ffffffffc0203f2c:	0a043023          	sd	zero,160(s0)
        // 进程标志位初始化为0
        proc->flags = 0;
ffffffffc0203f30:	0a042823          	sw	zero,176(s0)
        // 进程名称清零
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203f34:	4641                	li	a2,16
ffffffffc0203f36:	4581                	li	a1,0
ffffffffc0203f38:	0b440513          	addi	a0,s0,180
ffffffffc0203f3c:	057010ef          	jal	ra,ffffffffc0205792 <memset>
        // 初始化链表节点（进程链表和哈希表）
        list_init(&proc->list_link);
ffffffffc0203f40:	0c840713          	addi	a4,s0,200
        list_init(&proc->hash_link);
ffffffffc0203f44:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0203f48:	e878                	sd	a4,208(s0)
ffffffffc0203f4a:	e478                	sd	a4,200(s0)
ffffffffc0203f4c:	f07c                	sd	a5,224(s0)
ffffffffc0203f4e:	ec7c                	sd	a5,216(s0)
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        // Lab5 新增字段：等待状态 + 进程关系指针
        proc->exit_code = 0;
ffffffffc0203f50:	0e043423          	sd	zero,232(s0)
        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203f54:	0e043823          	sd	zero,240(s0)
ffffffffc0203f58:	0e043c23          	sd	zero,248(s0)
ffffffffc0203f5c:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0203f60:	60a2                	ld	ra,8(sp)
ffffffffc0203f62:	8522                	mv	a0,s0
ffffffffc0203f64:	6402                	ld	s0,0(sp)
ffffffffc0203f66:	0141                	addi	sp,sp,16
ffffffffc0203f68:	8082                	ret

ffffffffc0203f6a <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203f6a:	000a6797          	auipc	a5,0xa6
ffffffffc0203f6e:	75e7b783          	ld	a5,1886(a5) # ffffffffc02aa6c8 <current>
ffffffffc0203f72:	73c8                	ld	a0,160(a5)
ffffffffc0203f74:	feffc06f          	j	ffffffffc0200f62 <forkrets>

ffffffffc0203f78 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f78:	000a6797          	auipc	a5,0xa6
ffffffffc0203f7c:	7507b783          	ld	a5,1872(a5) # ffffffffc02aa6c8 <current>
ffffffffc0203f80:	43cc                	lw	a1,4(a5)
{
ffffffffc0203f82:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f84:	00003617          	auipc	a2,0x3
ffffffffc0203f88:	04c60613          	addi	a2,a2,76 # ffffffffc0206fd0 <default_pmm_manager+0x9f8>
ffffffffc0203f8c:	00003517          	auipc	a0,0x3
ffffffffc0203f90:	05450513          	addi	a0,a0,84 # ffffffffc0206fe0 <default_pmm_manager+0xa08>
{
ffffffffc0203f94:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f96:	9fefc0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0203f9a:	3fe07797          	auipc	a5,0x3fe07
ffffffffc0203f9e:	9c678793          	addi	a5,a5,-1594 # a960 <_binary_obj___user_forktest_out_size>
ffffffffc0203fa2:	e43e                	sd	a5,8(sp)
ffffffffc0203fa4:	00003517          	auipc	a0,0x3
ffffffffc0203fa8:	02c50513          	addi	a0,a0,44 # ffffffffc0206fd0 <default_pmm_manager+0x9f8>
ffffffffc0203fac:	00045797          	auipc	a5,0x45
ffffffffc0203fb0:	72478793          	addi	a5,a5,1828 # ffffffffc02496d0 <_binary_obj___user_forktest_out_start>
ffffffffc0203fb4:	f03e                	sd	a5,32(sp)
ffffffffc0203fb6:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203fb8:	e802                	sd	zero,16(sp)
ffffffffc0203fba:	736010ef          	jal	ra,ffffffffc02056f0 <strlen>
ffffffffc0203fbe:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203fc0:	4511                	li	a0,4
ffffffffc0203fc2:	55a2                	lw	a1,40(sp)
ffffffffc0203fc4:	4662                	lw	a2,24(sp)
ffffffffc0203fc6:	5682                	lw	a3,32(sp)
ffffffffc0203fc8:	4722                	lw	a4,8(sp)
ffffffffc0203fca:	48a9                	li	a7,10
ffffffffc0203fcc:	9002                	ebreak
ffffffffc0203fce:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203fd0:	65c2                	ld	a1,16(sp)
ffffffffc0203fd2:	00003517          	auipc	a0,0x3
ffffffffc0203fd6:	03650513          	addi	a0,a0,54 # ffffffffc0207008 <default_pmm_manager+0xa30>
ffffffffc0203fda:	9bafc0ef          	jal	ra,ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203fde:	00003617          	auipc	a2,0x3
ffffffffc0203fe2:	03a60613          	addi	a2,a2,58 # ffffffffc0207018 <default_pmm_manager+0xa40>
ffffffffc0203fe6:	3f000593          	li	a1,1008
ffffffffc0203fea:	00003517          	auipc	a0,0x3
ffffffffc0203fee:	04e50513          	addi	a0,a0,78 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0203ff2:	c9cfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0203ff6 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203ff6:	6d14                	ld	a3,24(a0)
{
ffffffffc0203ff8:	1141                	addi	sp,sp,-16
ffffffffc0203ffa:	e406                	sd	ra,8(sp)
ffffffffc0203ffc:	c02007b7          	lui	a5,0xc0200
ffffffffc0204000:	02f6ee63          	bltu	a3,a5,ffffffffc020403c <put_pgdir+0x46>
ffffffffc0204004:	000a6517          	auipc	a0,0xa6
ffffffffc0204008:	6bc53503          	ld	a0,1724(a0) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc020400c:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage)
ffffffffc020400e:	82b1                	srli	a3,a3,0xc
ffffffffc0204010:	000a6797          	auipc	a5,0xa6
ffffffffc0204014:	6987b783          	ld	a5,1688(a5) # ffffffffc02aa6a8 <npage>
ffffffffc0204018:	02f6fe63          	bgeu	a3,a5,ffffffffc0204054 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020401c:	00004517          	auipc	a0,0x4
ffffffffc0204020:	8b453503          	ld	a0,-1868(a0) # ffffffffc02078d0 <nbase>
}
ffffffffc0204024:	60a2                	ld	ra,8(sp)
ffffffffc0204026:	8e89                	sub	a3,a3,a0
ffffffffc0204028:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc020402a:	000a6517          	auipc	a0,0xa6
ffffffffc020402e:	68653503          	ld	a0,1670(a0) # ffffffffc02aa6b0 <pages>
ffffffffc0204032:	4585                	li	a1,1
ffffffffc0204034:	9536                	add	a0,a0,a3
}
ffffffffc0204036:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204038:	ed3fd06f          	j	ffffffffc0201f0a <free_pages>
    return pa2page(PADDR(kva));
ffffffffc020403c:	00002617          	auipc	a2,0x2
ffffffffc0204040:	67c60613          	addi	a2,a2,1660 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc0204044:	07700593          	li	a1,119
ffffffffc0204048:	00002517          	auipc	a0,0x2
ffffffffc020404c:	5f050513          	addi	a0,a0,1520 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0204050:	c3efc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204054:	00002617          	auipc	a2,0x2
ffffffffc0204058:	68c60613          	addi	a2,a2,1676 # ffffffffc02066e0 <default_pmm_manager+0x108>
ffffffffc020405c:	06900593          	li	a1,105
ffffffffc0204060:	00002517          	auipc	a0,0x2
ffffffffc0204064:	5d850513          	addi	a0,a0,1496 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0204068:	c26fc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020406c <proc_run>:
{
ffffffffc020406c:	7179                	addi	sp,sp,-48
ffffffffc020406e:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc0204070:	000a6497          	auipc	s1,0xa6
ffffffffc0204074:	65848493          	addi	s1,s1,1624 # ffffffffc02aa6c8 <current>
ffffffffc0204078:	6098                	ld	a4,0(s1)
{
ffffffffc020407a:	f406                	sd	ra,40(sp)
ffffffffc020407c:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc020407e:	02a70763          	beq	a4,a0,ffffffffc02040ac <proc_run+0x40>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204082:	100027f3          	csrr	a5,sstatus
ffffffffc0204086:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204088:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020408a:	ef85                	bnez	a5,ffffffffc02040c2 <proc_run+0x56>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc020408c:	755c                	ld	a5,168(a0)
ffffffffc020408e:	56fd                	li	a3,-1
ffffffffc0204090:	16fe                	slli	a3,a3,0x3f
ffffffffc0204092:	83b1                	srli	a5,a5,0xc
        current = proc;
ffffffffc0204094:	e088                	sd	a0,0(s1)
ffffffffc0204096:	8fd5                	or	a5,a5,a3
ffffffffc0204098:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &proc->context);
ffffffffc020409c:	03050593          	addi	a1,a0,48
ffffffffc02040a0:	03070513          	addi	a0,a4,48
ffffffffc02040a4:	7f3000ef          	jal	ra,ffffffffc0205096 <switch_to>
    if (flag)
ffffffffc02040a8:	00091763          	bnez	s2,ffffffffc02040b6 <proc_run+0x4a>
}
ffffffffc02040ac:	70a2                	ld	ra,40(sp)
ffffffffc02040ae:	7482                	ld	s1,32(sp)
ffffffffc02040b0:	6962                	ld	s2,24(sp)
ffffffffc02040b2:	6145                	addi	sp,sp,48
ffffffffc02040b4:	8082                	ret
ffffffffc02040b6:	70a2                	ld	ra,40(sp)
ffffffffc02040b8:	7482                	ld	s1,32(sp)
ffffffffc02040ba:	6962                	ld	s2,24(sp)
ffffffffc02040bc:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02040be:	8f1fc06f          	j	ffffffffc02009ae <intr_enable>
ffffffffc02040c2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02040c4:	8f1fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc02040c8:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02040ca:	6522                	ld	a0,8(sp)
ffffffffc02040cc:	4905                	li	s2,1
ffffffffc02040ce:	bf7d                	j	ffffffffc020408c <proc_run+0x20>

ffffffffc02040d0 <do_fork>:
{
ffffffffc02040d0:	7119                	addi	sp,sp,-128
ffffffffc02040d2:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02040d4:	000a6917          	auipc	s2,0xa6
ffffffffc02040d8:	60c90913          	addi	s2,s2,1548 # ffffffffc02aa6e0 <nr_process>
ffffffffc02040dc:	00092703          	lw	a4,0(s2)
{
ffffffffc02040e0:	fc86                	sd	ra,120(sp)
ffffffffc02040e2:	f8a2                	sd	s0,112(sp)
ffffffffc02040e4:	f4a6                	sd	s1,104(sp)
ffffffffc02040e6:	ecce                	sd	s3,88(sp)
ffffffffc02040e8:	e8d2                	sd	s4,80(sp)
ffffffffc02040ea:	e4d6                	sd	s5,72(sp)
ffffffffc02040ec:	e0da                	sd	s6,64(sp)
ffffffffc02040ee:	fc5e                	sd	s7,56(sp)
ffffffffc02040f0:	f862                	sd	s8,48(sp)
ffffffffc02040f2:	f466                	sd	s9,40(sp)
ffffffffc02040f4:	f06a                	sd	s10,32(sp)
ffffffffc02040f6:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc02040f8:	6785                	lui	a5,0x1
ffffffffc02040fa:	2ef75c63          	bge	a4,a5,ffffffffc02043f2 <do_fork+0x322>
ffffffffc02040fe:	8a2a                	mv	s4,a0
ffffffffc0204100:	89ae                	mv	s3,a1
ffffffffc0204102:	8432                	mv	s0,a2
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0204104:	de5ff0ef          	jal	ra,ffffffffc0203ee8 <alloc_proc>
ffffffffc0204108:	84aa                	mv	s1,a0
ffffffffc020410a:	2c050863          	beqz	a0,ffffffffc02043da <do_fork+0x30a>
    proc->parent = current;             // 设置父进程指针
ffffffffc020410e:	000a6c17          	auipc	s8,0xa6
ffffffffc0204112:	5bac0c13          	addi	s8,s8,1466 # ffffffffc02aa6c8 <current>
ffffffffc0204116:	000c3783          	ld	a5,0(s8)
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020411a:	4509                	li	a0,2
    proc->parent = current;             // 设置父进程指针
ffffffffc020411c:	f09c                	sd	a5,32(s1)
    current->wait_state = 0;            // 清除父进程的等待状态
ffffffffc020411e:	0e07a623          	sw	zero,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8ab4>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204122:	dabfd0ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
    if (page != NULL)
ffffffffc0204126:	2a050763          	beqz	a0,ffffffffc02043d4 <do_fork+0x304>
    return page - pages + nbase;
ffffffffc020412a:	000a6a97          	auipc	s5,0xa6
ffffffffc020412e:	586a8a93          	addi	s5,s5,1414 # ffffffffc02aa6b0 <pages>
ffffffffc0204132:	000ab683          	ld	a3,0(s5)
ffffffffc0204136:	00003b17          	auipc	s6,0x3
ffffffffc020413a:	79ab0b13          	addi	s6,s6,1946 # ffffffffc02078d0 <nbase>
ffffffffc020413e:	000b3783          	ld	a5,0(s6)
ffffffffc0204142:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204146:	000a6b97          	auipc	s7,0xa6
ffffffffc020414a:	562b8b93          	addi	s7,s7,1378 # ffffffffc02aa6a8 <npage>
    return page - pages + nbase;
ffffffffc020414e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204150:	5dfd                	li	s11,-1
ffffffffc0204152:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204156:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204158:	00cddd93          	srli	s11,s11,0xc
ffffffffc020415c:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204160:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204162:	2ce67563          	bgeu	a2,a4,ffffffffc020442c <do_fork+0x35c>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204166:	000c3603          	ld	a2,0(s8)
ffffffffc020416a:	000a6c17          	auipc	s8,0xa6
ffffffffc020416e:	556c0c13          	addi	s8,s8,1366 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc0204172:	000c3703          	ld	a4,0(s8)
ffffffffc0204176:	02863d03          	ld	s10,40(a2)
ffffffffc020417a:	e43e                	sd	a5,8(sp)
ffffffffc020417c:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020417e:	e894                	sd	a3,16(s1)
    if (oldmm == NULL)
ffffffffc0204180:	020d0863          	beqz	s10,ffffffffc02041b0 <do_fork+0xe0>
    if (clone_flags & CLONE_VM)
ffffffffc0204184:	100a7a13          	andi	s4,s4,256
ffffffffc0204188:	180a0863          	beqz	s4,ffffffffc0204318 <do_fork+0x248>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc020418c:	030d2703          	lw	a4,48(s10)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204190:	018d3783          	ld	a5,24(s10)
ffffffffc0204194:	c02006b7          	lui	a3,0xc0200
ffffffffc0204198:	2705                	addiw	a4,a4,1
ffffffffc020419a:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc020419e:	03a4b423          	sd	s10,40(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02041a2:	2ad7e163          	bltu	a5,a3,ffffffffc0204444 <do_fork+0x374>
ffffffffc02041a6:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02041aa:	6894                	ld	a3,16(s1)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02041ac:	8f99                	sub	a5,a5,a4
ffffffffc02041ae:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02041b0:	6789                	lui	a5,0x2
ffffffffc02041b2:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cc0>
ffffffffc02041b6:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02041b8:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02041ba:	f0d4                	sd	a3,160(s1)
    *(proc->tf) = *tf;
ffffffffc02041bc:	87b6                	mv	a5,a3
ffffffffc02041be:	12040893          	addi	a7,s0,288
ffffffffc02041c2:	00063803          	ld	a6,0(a2)
ffffffffc02041c6:	6608                	ld	a0,8(a2)
ffffffffc02041c8:	6a0c                	ld	a1,16(a2)
ffffffffc02041ca:	6e18                	ld	a4,24(a2)
ffffffffc02041cc:	0107b023          	sd	a6,0(a5)
ffffffffc02041d0:	e788                	sd	a0,8(a5)
ffffffffc02041d2:	eb8c                	sd	a1,16(a5)
ffffffffc02041d4:	ef98                	sd	a4,24(a5)
ffffffffc02041d6:	02060613          	addi	a2,a2,32
ffffffffc02041da:	02078793          	addi	a5,a5,32
ffffffffc02041de:	ff1612e3          	bne	a2,a7,ffffffffc02041c2 <do_fork+0xf2>
    proc->tf->gpr.a0 = 0;
ffffffffc02041e2:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02041e6:	12098763          	beqz	s3,ffffffffc0204314 <do_fork+0x244>
    if (++last_pid >= MAX_PID)
ffffffffc02041ea:	000a2817          	auipc	a6,0xa2
ffffffffc02041ee:	04e80813          	addi	a6,a6,78 # ffffffffc02a6238 <last_pid.1>
ffffffffc02041f2:	00082783          	lw	a5,0(a6)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02041f6:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02041fa:	00000717          	auipc	a4,0x0
ffffffffc02041fe:	d7070713          	addi	a4,a4,-656 # ffffffffc0203f6a <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0204202:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204206:	f898                	sd	a4,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204208:	fc94                	sd	a3,56(s1)
    if (++last_pid >= MAX_PID)
ffffffffc020420a:	00a82023          	sw	a0,0(a6)
ffffffffc020420e:	6789                	lui	a5,0x2
ffffffffc0204210:	08f55b63          	bge	a0,a5,ffffffffc02042a6 <do_fork+0x1d6>
    if (last_pid >= next_safe)
ffffffffc0204214:	000a2317          	auipc	t1,0xa2
ffffffffc0204218:	02830313          	addi	t1,t1,40 # ffffffffc02a623c <next_safe.0>
ffffffffc020421c:	00032783          	lw	a5,0(t1)
ffffffffc0204220:	000a6417          	auipc	s0,0xa6
ffffffffc0204224:	43840413          	addi	s0,s0,1080 # ffffffffc02aa658 <proc_list>
ffffffffc0204228:	08f55763          	bge	a0,a5,ffffffffc02042b6 <do_fork+0x1e6>
    proc->pid = get_pid();              // 为子进程分配唯一PID
ffffffffc020422c:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020422e:	45a9                	li	a1,10
ffffffffc0204230:	2501                	sext.w	a0,a0
ffffffffc0204232:	0ba010ef          	jal	ra,ffffffffc02052ec <hash32>
ffffffffc0204236:	02051793          	slli	a5,a0,0x20
ffffffffc020423a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020423e:	000a2797          	auipc	a5,0xa2
ffffffffc0204242:	41a78793          	addi	a5,a5,1050 # ffffffffc02a6658 <hash_list>
ffffffffc0204246:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204248:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020424a:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020424c:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0204250:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204252:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204254:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204256:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204258:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc020425c:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc020425e:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0204260:	e21c                	sd	a5,0(a2)
ffffffffc0204262:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204264:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204266:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204268:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020426c:	10e4b023          	sd	a4,256(s1)
ffffffffc0204270:	c311                	beqz	a4,ffffffffc0204274 <do_fork+0x1a4>
        proc->optr->yptr = proc;
ffffffffc0204272:	ff64                	sd	s1,248(a4)
    nr_process++;
ffffffffc0204274:	00092783          	lw	a5,0(s2)
    wakeup_proc(proc);                  // 设置state = PROC_RUNNABLE
ffffffffc0204278:	8526                	mv	a0,s1
    proc->parent->cptr = proc;
ffffffffc020427a:	fae4                	sd	s1,240(a3)
    nr_process++;
ffffffffc020427c:	2785                	addiw	a5,a5,1
ffffffffc020427e:	00f92023          	sw	a5,0(s2)
    wakeup_proc(proc);                  // 设置state = PROC_RUNNABLE
ffffffffc0204282:	67f000ef          	jal	ra,ffffffffc0205100 <wakeup_proc>
    ret = proc->pid;                    // 返回子进程ID
ffffffffc0204286:	40c8                	lw	a0,4(s1)
}
ffffffffc0204288:	70e6                	ld	ra,120(sp)
ffffffffc020428a:	7446                	ld	s0,112(sp)
ffffffffc020428c:	74a6                	ld	s1,104(sp)
ffffffffc020428e:	7906                	ld	s2,96(sp)
ffffffffc0204290:	69e6                	ld	s3,88(sp)
ffffffffc0204292:	6a46                	ld	s4,80(sp)
ffffffffc0204294:	6aa6                	ld	s5,72(sp)
ffffffffc0204296:	6b06                	ld	s6,64(sp)
ffffffffc0204298:	7be2                	ld	s7,56(sp)
ffffffffc020429a:	7c42                	ld	s8,48(sp)
ffffffffc020429c:	7ca2                	ld	s9,40(sp)
ffffffffc020429e:	7d02                	ld	s10,32(sp)
ffffffffc02042a0:	6de2                	ld	s11,24(sp)
ffffffffc02042a2:	6109                	addi	sp,sp,128
ffffffffc02042a4:	8082                	ret
        last_pid = 1;
ffffffffc02042a6:	4785                	li	a5,1
ffffffffc02042a8:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc02042ac:	4505                	li	a0,1
ffffffffc02042ae:	000a2317          	auipc	t1,0xa2
ffffffffc02042b2:	f8e30313          	addi	t1,t1,-114 # ffffffffc02a623c <next_safe.0>
    return listelm->next;
ffffffffc02042b6:	000a6417          	auipc	s0,0xa6
ffffffffc02042ba:	3a240413          	addi	s0,s0,930 # ffffffffc02aa658 <proc_list>
ffffffffc02042be:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc02042c2:	6789                	lui	a5,0x2
ffffffffc02042c4:	00f32023          	sw	a5,0(t1)
ffffffffc02042c8:	86aa                	mv	a3,a0
ffffffffc02042ca:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02042cc:	6e89                	lui	t4,0x2
ffffffffc02042ce:	108e0d63          	beq	t3,s0,ffffffffc02043e8 <do_fork+0x318>
ffffffffc02042d2:	88ae                	mv	a7,a1
ffffffffc02042d4:	87f2                	mv	a5,t3
ffffffffc02042d6:	6609                	lui	a2,0x2
ffffffffc02042d8:	a811                	j	ffffffffc02042ec <do_fork+0x21c>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02042da:	00e6d663          	bge	a3,a4,ffffffffc02042e6 <do_fork+0x216>
ffffffffc02042de:	00c75463          	bge	a4,a2,ffffffffc02042e6 <do_fork+0x216>
ffffffffc02042e2:	863a                	mv	a2,a4
ffffffffc02042e4:	4885                	li	a7,1
ffffffffc02042e6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02042e8:	00878d63          	beq	a5,s0,ffffffffc0204302 <do_fork+0x232>
            if (proc->pid == last_pid)
ffffffffc02042ec:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c64>
ffffffffc02042f0:	fed715e3          	bne	a4,a3,ffffffffc02042da <do_fork+0x20a>
                if (++last_pid >= next_safe)
ffffffffc02042f4:	2685                	addiw	a3,a3,1
ffffffffc02042f6:	0ec6d463          	bge	a3,a2,ffffffffc02043de <do_fork+0x30e>
ffffffffc02042fa:	679c                	ld	a5,8(a5)
ffffffffc02042fc:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02042fe:	fe8797e3          	bne	a5,s0,ffffffffc02042ec <do_fork+0x21c>
ffffffffc0204302:	c581                	beqz	a1,ffffffffc020430a <do_fork+0x23a>
ffffffffc0204304:	00d82023          	sw	a3,0(a6)
ffffffffc0204308:	8536                	mv	a0,a3
ffffffffc020430a:	f20881e3          	beqz	a7,ffffffffc020422c <do_fork+0x15c>
ffffffffc020430e:	00c32023          	sw	a2,0(t1)
ffffffffc0204312:	bf29                	j	ffffffffc020422c <do_fork+0x15c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204314:	89b6                	mv	s3,a3
ffffffffc0204316:	bdd1                	j	ffffffffc02041ea <do_fork+0x11a>
    if ((mm = mm_create()) == NULL)
ffffffffc0204318:	bb6ff0ef          	jal	ra,ffffffffc02036ce <mm_create>
ffffffffc020431c:	8caa                	mv	s9,a0
ffffffffc020431e:	c159                	beqz	a0,ffffffffc02043a4 <do_fork+0x2d4>
    if ((page = alloc_page()) == NULL)
ffffffffc0204320:	4505                	li	a0,1
ffffffffc0204322:	babfd0ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc0204326:	cd25                	beqz	a0,ffffffffc020439e <do_fork+0x2ce>
    return page - pages + nbase;
ffffffffc0204328:	000ab683          	ld	a3,0(s5)
ffffffffc020432c:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc020432e:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204332:	40d506b3          	sub	a3,a0,a3
ffffffffc0204336:	8699                	srai	a3,a3,0x6
ffffffffc0204338:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020433a:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020433e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204340:	0eedf663          	bgeu	s11,a4,ffffffffc020442c <do_fork+0x35c>
ffffffffc0204344:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204348:	6605                	lui	a2,0x1
ffffffffc020434a:	000a6597          	auipc	a1,0xa6
ffffffffc020434e:	3565b583          	ld	a1,854(a1) # ffffffffc02aa6a0 <boot_pgdir_va>
ffffffffc0204352:	9a36                	add	s4,s4,a3
ffffffffc0204354:	8552                	mv	a0,s4
ffffffffc0204356:	44e010ef          	jal	ra,ffffffffc02057a4 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc020435a:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc020435e:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204362:	4785                	li	a5,1
ffffffffc0204364:	40fdb7af          	amoor.d	a5,a5,(s11)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204368:	8b85                	andi	a5,a5,1
ffffffffc020436a:	4a05                	li	s4,1
ffffffffc020436c:	c799                	beqz	a5,ffffffffc020437a <do_fork+0x2aa>
    {
        schedule();
ffffffffc020436e:	613000ef          	jal	ra,ffffffffc0205180 <schedule>
ffffffffc0204372:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock))
ffffffffc0204376:	8b85                	andi	a5,a5,1
ffffffffc0204378:	fbfd                	bnez	a5,ffffffffc020436e <do_fork+0x29e>
        ret = dup_mmap(mm, oldmm);
ffffffffc020437a:	85ea                	mv	a1,s10
ffffffffc020437c:	8566                	mv	a0,s9
ffffffffc020437e:	d92ff0ef          	jal	ra,ffffffffc0203910 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0204382:	57f9                	li	a5,-2
ffffffffc0204384:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0204388:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc020438a:	cbad                	beqz	a5,ffffffffc02043fc <do_fork+0x32c>
good_mm:
ffffffffc020438c:	8d66                	mv	s10,s9
    if (ret != 0)
ffffffffc020438e:	de050fe3          	beqz	a0,ffffffffc020418c <do_fork+0xbc>
    exit_mmap(mm);
ffffffffc0204392:	8566                	mv	a0,s9
ffffffffc0204394:	e16ff0ef          	jal	ra,ffffffffc02039aa <exit_mmap>
    put_pgdir(mm);
ffffffffc0204398:	8566                	mv	a0,s9
ffffffffc020439a:	c5dff0ef          	jal	ra,ffffffffc0203ff6 <put_pgdir>
    mm_destroy(mm);
ffffffffc020439e:	8566                	mv	a0,s9
ffffffffc02043a0:	c6eff0ef          	jal	ra,ffffffffc020380e <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02043a4:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc02043a6:	c02007b7          	lui	a5,0xc0200
ffffffffc02043aa:	0af6ea63          	bltu	a3,a5,ffffffffc020445e <do_fork+0x38e>
ffffffffc02043ae:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage)
ffffffffc02043b2:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02043b6:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02043ba:	83b1                	srli	a5,a5,0xc
ffffffffc02043bc:	04e7fc63          	bgeu	a5,a4,ffffffffc0204414 <do_fork+0x344>
    return &pages[PPN(pa) - nbase];
ffffffffc02043c0:	000b3703          	ld	a4,0(s6)
ffffffffc02043c4:	000ab503          	ld	a0,0(s5)
ffffffffc02043c8:	4589                	li	a1,2
ffffffffc02043ca:	8f99                	sub	a5,a5,a4
ffffffffc02043cc:	079a                	slli	a5,a5,0x6
ffffffffc02043ce:	953e                	add	a0,a0,a5
ffffffffc02043d0:	b3bfd0ef          	jal	ra,ffffffffc0201f0a <free_pages>
    kfree(proc);                        // 释放proc结构体内存
ffffffffc02043d4:	8526                	mv	a0,s1
ffffffffc02043d6:	9c9fd0ef          	jal	ra,ffffffffc0201d9e <kfree>
    ret = -E_NO_MEM;                    // 设置错误码为"内存不足"
ffffffffc02043da:	5571                	li	a0,-4
    return ret;                         // 返回结果(成功: PID, 失败: 错误码)
ffffffffc02043dc:	b575                	j	ffffffffc0204288 <do_fork+0x1b8>
                    if (last_pid >= MAX_PID)
ffffffffc02043de:	01d6c363          	blt	a3,t4,ffffffffc02043e4 <do_fork+0x314>
                        last_pid = 1;
ffffffffc02043e2:	4685                	li	a3,1
                    goto repeat;
ffffffffc02043e4:	4585                	li	a1,1
ffffffffc02043e6:	b5e5                	j	ffffffffc02042ce <do_fork+0x1fe>
ffffffffc02043e8:	c599                	beqz	a1,ffffffffc02043f6 <do_fork+0x326>
ffffffffc02043ea:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc02043ee:	8536                	mv	a0,a3
ffffffffc02043f0:	bd35                	j	ffffffffc020422c <do_fork+0x15c>
    int ret = -E_NO_FREE_PROC;          // 默认返回"无空闲进程"错误
ffffffffc02043f2:	556d                	li	a0,-5
ffffffffc02043f4:	bd51                	j	ffffffffc0204288 <do_fork+0x1b8>
    return last_pid;
ffffffffc02043f6:	00082503          	lw	a0,0(a6)
ffffffffc02043fa:	bd0d                	j	ffffffffc020422c <do_fork+0x15c>
    {
        panic("Unlock failed.\n");
ffffffffc02043fc:	00003617          	auipc	a2,0x3
ffffffffc0204400:	c5460613          	addi	a2,a2,-940 # ffffffffc0207050 <default_pmm_manager+0xa78>
ffffffffc0204404:	03f00593          	li	a1,63
ffffffffc0204408:	00003517          	auipc	a0,0x3
ffffffffc020440c:	c5850513          	addi	a0,a0,-936 # ffffffffc0207060 <default_pmm_manager+0xa88>
ffffffffc0204410:	87efc0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204414:	00002617          	auipc	a2,0x2
ffffffffc0204418:	2cc60613          	addi	a2,a2,716 # ffffffffc02066e0 <default_pmm_manager+0x108>
ffffffffc020441c:	06900593          	li	a1,105
ffffffffc0204420:	00002517          	auipc	a0,0x2
ffffffffc0204424:	21850513          	addi	a0,a0,536 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0204428:	866fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020442c:	00002617          	auipc	a2,0x2
ffffffffc0204430:	1e460613          	addi	a2,a2,484 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0204434:	07100593          	li	a1,113
ffffffffc0204438:	00002517          	auipc	a0,0x2
ffffffffc020443c:	20050513          	addi	a0,a0,512 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0204440:	84efc0ef          	jal	ra,ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204444:	86be                	mv	a3,a5
ffffffffc0204446:	00002617          	auipc	a2,0x2
ffffffffc020444a:	27260613          	addi	a2,a2,626 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc020444e:	1a200593          	li	a1,418
ffffffffc0204452:	00003517          	auipc	a0,0x3
ffffffffc0204456:	be650513          	addi	a0,a0,-1050 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc020445a:	834fc0ef          	jal	ra,ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc020445e:	00002617          	auipc	a2,0x2
ffffffffc0204462:	25a60613          	addi	a2,a2,602 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc0204466:	07700593          	li	a1,119
ffffffffc020446a:	00002517          	auipc	a0,0x2
ffffffffc020446e:	1ce50513          	addi	a0,a0,462 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0204472:	81cfc0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204476 <kernel_thread>:
{
ffffffffc0204476:	7129                	addi	sp,sp,-320
ffffffffc0204478:	fa22                	sd	s0,304(sp)
ffffffffc020447a:	f626                	sd	s1,296(sp)
ffffffffc020447c:	f24a                	sd	s2,288(sp)
ffffffffc020447e:	84ae                	mv	s1,a1
ffffffffc0204480:	892a                	mv	s2,a0
ffffffffc0204482:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204484:	4581                	li	a1,0
ffffffffc0204486:	12000613          	li	a2,288
ffffffffc020448a:	850a                	mv	a0,sp
{
ffffffffc020448c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020448e:	304010ef          	jal	ra,ffffffffc0205792 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204492:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204494:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204496:	100027f3          	csrr	a5,sstatus
ffffffffc020449a:	edd7f793          	andi	a5,a5,-291
ffffffffc020449e:	1207e793          	ori	a5,a5,288
ffffffffc02044a2:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02044a4:	860a                	mv	a2,sp
ffffffffc02044a6:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02044aa:	00000797          	auipc	a5,0x0
ffffffffc02044ae:	a3678793          	addi	a5,a5,-1482 # ffffffffc0203ee0 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02044b2:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02044b4:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02044b6:	c1bff0ef          	jal	ra,ffffffffc02040d0 <do_fork>
}
ffffffffc02044ba:	70f2                	ld	ra,312(sp)
ffffffffc02044bc:	7452                	ld	s0,304(sp)
ffffffffc02044be:	74b2                	ld	s1,296(sp)
ffffffffc02044c0:	7912                	ld	s2,288(sp)
ffffffffc02044c2:	6131                	addi	sp,sp,320
ffffffffc02044c4:	8082                	ret

ffffffffc02044c6 <do_exit>:
{
ffffffffc02044c6:	7179                	addi	sp,sp,-48
ffffffffc02044c8:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02044ca:	000a6417          	auipc	s0,0xa6
ffffffffc02044ce:	1fe40413          	addi	s0,s0,510 # ffffffffc02aa6c8 <current>
ffffffffc02044d2:	601c                	ld	a5,0(s0)
{
ffffffffc02044d4:	f406                	sd	ra,40(sp)
ffffffffc02044d6:	ec26                	sd	s1,24(sp)
ffffffffc02044d8:	e84a                	sd	s2,16(sp)
ffffffffc02044da:	e44e                	sd	s3,8(sp)
ffffffffc02044dc:	e052                	sd	s4,0(sp)
    if (current == idleproc)
ffffffffc02044de:	000a6717          	auipc	a4,0xa6
ffffffffc02044e2:	1f273703          	ld	a4,498(a4) # ffffffffc02aa6d0 <idleproc>
ffffffffc02044e6:	0ce78c63          	beq	a5,a4,ffffffffc02045be <do_exit+0xf8>
    if (current == initproc)
ffffffffc02044ea:	000a6497          	auipc	s1,0xa6
ffffffffc02044ee:	1ee48493          	addi	s1,s1,494 # ffffffffc02aa6d8 <initproc>
ffffffffc02044f2:	6098                	ld	a4,0(s1)
ffffffffc02044f4:	0ee78b63          	beq	a5,a4,ffffffffc02045ea <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02044f8:	0287b983          	ld	s3,40(a5)
ffffffffc02044fc:	892a                	mv	s2,a0
    if (mm != NULL)  // 如果进程有独立的内存空间（用户进程）
ffffffffc02044fe:	02098663          	beqz	s3,ffffffffc020452a <do_exit+0x64>
ffffffffc0204502:	000a6797          	auipc	a5,0xa6
ffffffffc0204506:	1967b783          	ld	a5,406(a5) # ffffffffc02aa698 <boot_pgdir_pa>
ffffffffc020450a:	577d                	li	a4,-1
ffffffffc020450c:	177e                	slli	a4,a4,0x3f
ffffffffc020450e:	83b1                	srli	a5,a5,0xc
ffffffffc0204510:	8fd9                	or	a5,a5,a4
ffffffffc0204512:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204516:	0309a783          	lw	a5,48(s3) # fffffffffffff030 <end+0x3fd5494c>
ffffffffc020451a:	fff7871b          	addiw	a4,a5,-1
ffffffffc020451e:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204522:	cb55                	beqz	a4,ffffffffc02045d6 <do_exit+0x110>
        current->mm = NULL;    // 清空当前进程的内存指针
ffffffffc0204524:	601c                	ld	a5,0(s0)
ffffffffc0204526:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020452a:	601c                	ld	a5,0(s0)
ffffffffc020452c:	470d                	li	a4,3
ffffffffc020452e:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;  // 保存退出码供父进程查询
ffffffffc0204530:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204534:	100027f3          	csrr	a5,sstatus
ffffffffc0204538:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020453a:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020453c:	e3f9                	bnez	a5,ffffffffc0204602 <do_exit+0x13c>
        proc = current->parent;
ffffffffc020453e:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)  // 如果父进程正在等待子进程
ffffffffc0204540:	800007b7          	lui	a5,0x80000
ffffffffc0204544:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0204546:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)  // 如果父进程正在等待子进程
ffffffffc0204548:	0ec52703          	lw	a4,236(a0)
ffffffffc020454c:	0af70f63          	beq	a4,a5,ffffffffc020460a <do_exit+0x144>
        while (current->cptr != NULL)  // cptr指向当前进程的第一个子进程
ffffffffc0204550:	6018                	ld	a4,0(s0)
ffffffffc0204552:	7b7c                	ld	a5,240(a4)
ffffffffc0204554:	c3a1                	beqz	a5,ffffffffc0204594 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD)  // init进程在等待子进程
ffffffffc0204556:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE)
ffffffffc020455a:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD)  // init进程在等待子进程
ffffffffc020455c:	0985                	addi	s3,s3,1
ffffffffc020455e:	a021                	j	ffffffffc0204566 <do_exit+0xa0>
        while (current->cptr != NULL)  // cptr指向当前进程的第一个子进程
ffffffffc0204560:	6018                	ld	a4,0(s0)
ffffffffc0204562:	7b7c                	ld	a5,240(a4)
ffffffffc0204564:	cb85                	beqz	a5,ffffffffc0204594 <do_exit+0xce>
            current->cptr = proc->optr;          // 从当前进程的子进程链表中移除
ffffffffc0204566:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fe8>
            if ((proc->optr = initproc->cptr) != NULL)  // 如果init进程已有子进程
ffffffffc020456a:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;          // 从当前进程的子进程链表中移除
ffffffffc020456c:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL)  // 如果init进程已有子进程
ffffffffc020456e:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;  // 清空younger sibling指针
ffffffffc0204570:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)  // 如果init进程已有子进程
ffffffffc0204574:	10e7b023          	sd	a4,256(a5)
ffffffffc0204578:	c311                	beqz	a4,ffffffffc020457c <do_exit+0xb6>
                initproc->cptr->yptr = proc;  // 设置原第一个子进程的yptr指向新子进程
ffffffffc020457a:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020457c:	4398                	lw	a4,0(a5)
            proc->parent = initproc;          // 更改父进程为init进程
ffffffffc020457e:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;            // 设为init进程的第一个子进程
ffffffffc0204580:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204582:	fd271fe3          	bne	a4,s2,ffffffffc0204560 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD)  // init进程在等待子进程
ffffffffc0204586:	0ec52783          	lw	a5,236(a0)
ffffffffc020458a:	fd379be3          	bne	a5,s3,ffffffffc0204560 <do_exit+0x9a>
                    wakeup_proc(initproc);  // 唤醒init进程
ffffffffc020458e:	373000ef          	jal	ra,ffffffffc0205100 <wakeup_proc>
ffffffffc0204592:	b7f9                	j	ffffffffc0204560 <do_exit+0x9a>
    if (flag)
ffffffffc0204594:	020a1263          	bnez	s4,ffffffffc02045b8 <do_exit+0xf2>
    schedule();
ffffffffc0204598:	3e9000ef          	jal	ra,ffffffffc0205180 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020459c:	601c                	ld	a5,0(s0)
ffffffffc020459e:	00003617          	auipc	a2,0x3
ffffffffc02045a2:	afa60613          	addi	a2,a2,-1286 # ffffffffc0207098 <default_pmm_manager+0xac0>
ffffffffc02045a6:	27400593          	li	a1,628
ffffffffc02045aa:	43d4                	lw	a3,4(a5)
ffffffffc02045ac:	00003517          	auipc	a0,0x3
ffffffffc02045b0:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc02045b4:	edbfb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_enable();
ffffffffc02045b8:	bf6fc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc02045bc:	bff1                	j	ffffffffc0204598 <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc02045be:	00003617          	auipc	a2,0x3
ffffffffc02045c2:	aba60613          	addi	a2,a2,-1350 # ffffffffc0207078 <default_pmm_manager+0xaa0>
ffffffffc02045c6:	22800593          	li	a1,552
ffffffffc02045ca:	00003517          	auipc	a0,0x3
ffffffffc02045ce:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc02045d2:	ebdfb0ef          	jal	ra,ffffffffc020048e <__panic>
            exit_mmap(mm);     // 释放内存映射（页表和物理页）
ffffffffc02045d6:	854e                	mv	a0,s3
ffffffffc02045d8:	bd2ff0ef          	jal	ra,ffffffffc02039aa <exit_mmap>
            put_pgdir(mm);     // 释放页目录
ffffffffc02045dc:	854e                	mv	a0,s3
ffffffffc02045de:	a19ff0ef          	jal	ra,ffffffffc0203ff6 <put_pgdir>
            mm_destroy(mm);    // 销毁mm_struct结构
ffffffffc02045e2:	854e                	mv	a0,s3
ffffffffc02045e4:	a2aff0ef          	jal	ra,ffffffffc020380e <mm_destroy>
ffffffffc02045e8:	bf35                	j	ffffffffc0204524 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc02045ea:	00003617          	auipc	a2,0x3
ffffffffc02045ee:	a9e60613          	addi	a2,a2,-1378 # ffffffffc0207088 <default_pmm_manager+0xab0>
ffffffffc02045f2:	22e00593          	li	a1,558
ffffffffc02045f6:	00003517          	auipc	a0,0x3
ffffffffc02045fa:	a4250513          	addi	a0,a0,-1470 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc02045fe:	e91fb0ef          	jal	ra,ffffffffc020048e <__panic>
        intr_disable();
ffffffffc0204602:	bb2fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204606:	4a05                	li	s4,1
ffffffffc0204608:	bf1d                	j	ffffffffc020453e <do_exit+0x78>
            wakeup_proc(proc);  // 唤醒父进程
ffffffffc020460a:	2f7000ef          	jal	ra,ffffffffc0205100 <wakeup_proc>
ffffffffc020460e:	b789                	j	ffffffffc0204550 <do_exit+0x8a>

ffffffffc0204610 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204610:	715d                	addi	sp,sp,-80
ffffffffc0204612:	f84a                	sd	s2,48(sp)
ffffffffc0204614:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc0204616:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID)
ffffffffc020461a:	6989                	lui	s3,0x2
int do_wait(int pid, int *code_store)
ffffffffc020461c:	fc26                	sd	s1,56(sp)
ffffffffc020461e:	f052                	sd	s4,32(sp)
ffffffffc0204620:	ec56                	sd	s5,24(sp)
ffffffffc0204622:	e85a                	sd	s6,16(sp)
ffffffffc0204624:	e45e                	sd	s7,8(sp)
ffffffffc0204626:	e486                	sd	ra,72(sp)
ffffffffc0204628:	e0a2                	sd	s0,64(sp)
ffffffffc020462a:	84aa                	mv	s1,a0
ffffffffc020462c:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc020462e:	000a6b97          	auipc	s7,0xa6
ffffffffc0204632:	09ab8b93          	addi	s7,s7,154 # ffffffffc02aa6c8 <current>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204636:	00050b1b          	sext.w	s6,a0
ffffffffc020463a:	fff50a9b          	addiw	s5,a0,-1
ffffffffc020463e:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0204640:	0905                	addi	s2,s2,1
    if (pid != 0)
ffffffffc0204642:	ccbd                	beqz	s1,ffffffffc02046c0 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204644:	0359e863          	bltu	s3,s5,ffffffffc0204674 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204648:	45a9                	li	a1,10
ffffffffc020464a:	855a                	mv	a0,s6
ffffffffc020464c:	4a1000ef          	jal	ra,ffffffffc02052ec <hash32>
ffffffffc0204650:	02051793          	slli	a5,a0,0x20
ffffffffc0204654:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204658:	000a2797          	auipc	a5,0xa2
ffffffffc020465c:	00078793          	mv	a5,a5
ffffffffc0204660:	953e                	add	a0,a0,a5
ffffffffc0204662:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list)
ffffffffc0204664:	a029                	j	ffffffffc020466e <do_wait.part.0+0x5e>
            if (proc->pid == pid)
ffffffffc0204666:	f2c42783          	lw	a5,-212(s0)
ffffffffc020466a:	02978163          	beq	a5,s1,ffffffffc020468c <do_wait.part.0+0x7c>
ffffffffc020466e:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list)
ffffffffc0204670:	fe851be3          	bne	a0,s0,ffffffffc0204666 <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc0204674:	5579                	li	a0,-2
}
ffffffffc0204676:	60a6                	ld	ra,72(sp)
ffffffffc0204678:	6406                	ld	s0,64(sp)
ffffffffc020467a:	74e2                	ld	s1,56(sp)
ffffffffc020467c:	7942                	ld	s2,48(sp)
ffffffffc020467e:	79a2                	ld	s3,40(sp)
ffffffffc0204680:	7a02                	ld	s4,32(sp)
ffffffffc0204682:	6ae2                	ld	s5,24(sp)
ffffffffc0204684:	6b42                	ld	s6,16(sp)
ffffffffc0204686:	6ba2                	ld	s7,8(sp)
ffffffffc0204688:	6161                	addi	sp,sp,80
ffffffffc020468a:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020468c:	000bb683          	ld	a3,0(s7)
ffffffffc0204690:	f4843783          	ld	a5,-184(s0)
ffffffffc0204694:	fed790e3          	bne	a5,a3,ffffffffc0204674 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204698:	f2842703          	lw	a4,-216(s0)
ffffffffc020469c:	478d                	li	a5,3
ffffffffc020469e:	0ef70b63          	beq	a4,a5,ffffffffc0204794 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02046a2:	4785                	li	a5,1
ffffffffc02046a4:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02046a6:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02046aa:	2d7000ef          	jal	ra,ffffffffc0205180 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc02046ae:	000bb783          	ld	a5,0(s7)
ffffffffc02046b2:	0b07a783          	lw	a5,176(a5) # ffffffffc02a6708 <hash_list+0xb0>
ffffffffc02046b6:	8b85                	andi	a5,a5,1
ffffffffc02046b8:	d7c9                	beqz	a5,ffffffffc0204642 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02046ba:	555d                	li	a0,-9
ffffffffc02046bc:	e0bff0ef          	jal	ra,ffffffffc02044c6 <do_exit>
        proc = current->cptr;
ffffffffc02046c0:	000bb683          	ld	a3,0(s7)
ffffffffc02046c4:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr)
ffffffffc02046c6:	d45d                	beqz	s0,ffffffffc0204674 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046c8:	470d                	li	a4,3
ffffffffc02046ca:	a021                	j	ffffffffc02046d2 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02046cc:	10043403          	ld	s0,256(s0)
ffffffffc02046d0:	d869                	beqz	s0,ffffffffc02046a2 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046d2:	401c                	lw	a5,0(s0)
ffffffffc02046d4:	fee79ce3          	bne	a5,a4,ffffffffc02046cc <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc)
ffffffffc02046d8:	000a6797          	auipc	a5,0xa6
ffffffffc02046dc:	ff87b783          	ld	a5,-8(a5) # ffffffffc02aa6d0 <idleproc>
ffffffffc02046e0:	0c878963          	beq	a5,s0,ffffffffc02047b2 <do_wait.part.0+0x1a2>
ffffffffc02046e4:	000a6797          	auipc	a5,0xa6
ffffffffc02046e8:	ff47b783          	ld	a5,-12(a5) # ffffffffc02aa6d8 <initproc>
ffffffffc02046ec:	0cf40363          	beq	s0,a5,ffffffffc02047b2 <do_wait.part.0+0x1a2>
    if (code_store != NULL)
ffffffffc02046f0:	000a0663          	beqz	s4,ffffffffc02046fc <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02046f4:	0e842783          	lw	a5,232(s0)
ffffffffc02046f8:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8ba0>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046fc:	100027f3          	csrr	a5,sstatus
ffffffffc0204700:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204702:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204704:	e7c1                	bnez	a5,ffffffffc020478c <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204706:	6c70                	ld	a2,216(s0)
ffffffffc0204708:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL)
ffffffffc020470a:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc020470e:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0204710:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0204712:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204714:	6470                	ld	a2,200(s0)
ffffffffc0204716:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0204718:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020471a:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL)
ffffffffc020471c:	c319                	beqz	a4,ffffffffc0204722 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc020471e:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL)
ffffffffc0204720:	7c7c                	ld	a5,248(s0)
ffffffffc0204722:	c3b5                	beqz	a5,ffffffffc0204786 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0204724:	10e7b023          	sd	a4,256(a5)
    nr_process--;
ffffffffc0204728:	000a6717          	auipc	a4,0xa6
ffffffffc020472c:	fb870713          	addi	a4,a4,-72 # ffffffffc02aa6e0 <nr_process>
ffffffffc0204730:	431c                	lw	a5,0(a4)
ffffffffc0204732:	37fd                	addiw	a5,a5,-1
ffffffffc0204734:	c31c                	sw	a5,0(a4)
    if (flag)
ffffffffc0204736:	e5a9                	bnez	a1,ffffffffc0204780 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc0204738:	6814                	ld	a3,16(s0)
ffffffffc020473a:	c02007b7          	lui	a5,0xc0200
ffffffffc020473e:	04f6ee63          	bltu	a3,a5,ffffffffc020479a <do_wait.part.0+0x18a>
ffffffffc0204742:	000a6797          	auipc	a5,0xa6
ffffffffc0204746:	f7e7b783          	ld	a5,-130(a5) # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc020474a:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage)
ffffffffc020474c:	82b1                	srli	a3,a3,0xc
ffffffffc020474e:	000a6797          	auipc	a5,0xa6
ffffffffc0204752:	f5a7b783          	ld	a5,-166(a5) # ffffffffc02aa6a8 <npage>
ffffffffc0204756:	06f6fa63          	bgeu	a3,a5,ffffffffc02047ca <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020475a:	00003517          	auipc	a0,0x3
ffffffffc020475e:	17653503          	ld	a0,374(a0) # ffffffffc02078d0 <nbase>
ffffffffc0204762:	8e89                	sub	a3,a3,a0
ffffffffc0204764:	069a                	slli	a3,a3,0x6
ffffffffc0204766:	000a6517          	auipc	a0,0xa6
ffffffffc020476a:	f4a53503          	ld	a0,-182(a0) # ffffffffc02aa6b0 <pages>
ffffffffc020476e:	9536                	add	a0,a0,a3
ffffffffc0204770:	4589                	li	a1,2
ffffffffc0204772:	f98fd0ef          	jal	ra,ffffffffc0201f0a <free_pages>
    kfree(proc);
ffffffffc0204776:	8522                	mv	a0,s0
ffffffffc0204778:	e26fd0ef          	jal	ra,ffffffffc0201d9e <kfree>
    return 0;
ffffffffc020477c:	4501                	li	a0,0
ffffffffc020477e:	bde5                	j	ffffffffc0204676 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0204780:	a2efc0ef          	jal	ra,ffffffffc02009ae <intr_enable>
ffffffffc0204784:	bf55                	j	ffffffffc0204738 <do_wait.part.0+0x128>
        proc->parent->cptr = proc->optr;
ffffffffc0204786:	701c                	ld	a5,32(s0)
ffffffffc0204788:	fbf8                	sd	a4,240(a5)
ffffffffc020478a:	bf79                	j	ffffffffc0204728 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020478c:	a28fc0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0204790:	4585                	li	a1,1
ffffffffc0204792:	bf95                	j	ffffffffc0204706 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204794:	f2840413          	addi	s0,s0,-216
ffffffffc0204798:	b781                	j	ffffffffc02046d8 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc020479a:	00002617          	auipc	a2,0x2
ffffffffc020479e:	f1e60613          	addi	a2,a2,-226 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc02047a2:	07700593          	li	a1,119
ffffffffc02047a6:	00002517          	auipc	a0,0x2
ffffffffc02047aa:	e9250513          	addi	a0,a0,-366 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc02047ae:	ce1fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02047b2:	00003617          	auipc	a2,0x3
ffffffffc02047b6:	90660613          	addi	a2,a2,-1786 # ffffffffc02070b8 <default_pmm_manager+0xae0>
ffffffffc02047ba:	39800593          	li	a1,920
ffffffffc02047be:	00003517          	auipc	a0,0x3
ffffffffc02047c2:	87a50513          	addi	a0,a0,-1926 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc02047c6:	cc9fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02047ca:	00002617          	auipc	a2,0x2
ffffffffc02047ce:	f1660613          	addi	a2,a2,-234 # ffffffffc02066e0 <default_pmm_manager+0x108>
ffffffffc02047d2:	06900593          	li	a1,105
ffffffffc02047d6:	00002517          	auipc	a0,0x2
ffffffffc02047da:	e6250513          	addi	a0,a0,-414 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc02047de:	cb1fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02047e2 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02047e2:	1141                	addi	sp,sp,-16
ffffffffc02047e4:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02047e6:	f64fd0ef          	jal	ra,ffffffffc0201f4a <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02047ea:	d00fd0ef          	jal	ra,ffffffffc0201cea <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02047ee:	4601                	li	a2,0
ffffffffc02047f0:	4581                	li	a1,0
ffffffffc02047f2:	fffff517          	auipc	a0,0xfffff
ffffffffc02047f6:	78650513          	addi	a0,a0,1926 # ffffffffc0203f78 <user_main>
ffffffffc02047fa:	c7dff0ef          	jal	ra,ffffffffc0204476 <kernel_thread>
    if (pid <= 0)
ffffffffc02047fe:	00a04563          	bgtz	a0,ffffffffc0204808 <init_main+0x26>
ffffffffc0204802:	a071                	j	ffffffffc020488e <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204804:	17d000ef          	jal	ra,ffffffffc0205180 <schedule>
    if (code_store != NULL)
ffffffffc0204808:	4581                	li	a1,0
ffffffffc020480a:	4501                	li	a0,0
ffffffffc020480c:	e05ff0ef          	jal	ra,ffffffffc0204610 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204810:	d975                	beqz	a0,ffffffffc0204804 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204812:	00003517          	auipc	a0,0x3
ffffffffc0204816:	8e650513          	addi	a0,a0,-1818 # ffffffffc02070f8 <default_pmm_manager+0xb20>
ffffffffc020481a:	97bfb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020481e:	000a6797          	auipc	a5,0xa6
ffffffffc0204822:	eba7b783          	ld	a5,-326(a5) # ffffffffc02aa6d8 <initproc>
ffffffffc0204826:	7bf8                	ld	a4,240(a5)
ffffffffc0204828:	e339                	bnez	a4,ffffffffc020486e <init_main+0x8c>
ffffffffc020482a:	7ff8                	ld	a4,248(a5)
ffffffffc020482c:	e329                	bnez	a4,ffffffffc020486e <init_main+0x8c>
ffffffffc020482e:	1007b703          	ld	a4,256(a5)
ffffffffc0204832:	ef15                	bnez	a4,ffffffffc020486e <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204834:	000a6697          	auipc	a3,0xa6
ffffffffc0204838:	eac6a683          	lw	a3,-340(a3) # ffffffffc02aa6e0 <nr_process>
ffffffffc020483c:	4709                	li	a4,2
ffffffffc020483e:	0ae69463          	bne	a3,a4,ffffffffc02048e6 <init_main+0x104>
    return listelm->next;
ffffffffc0204842:	000a6697          	auipc	a3,0xa6
ffffffffc0204846:	e1668693          	addi	a3,a3,-490 # ffffffffc02aa658 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020484a:	6698                	ld	a4,8(a3)
ffffffffc020484c:	0c878793          	addi	a5,a5,200
ffffffffc0204850:	06f71b63          	bne	a4,a5,ffffffffc02048c6 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204854:	629c                	ld	a5,0(a3)
ffffffffc0204856:	04f71863          	bne	a4,a5,ffffffffc02048a6 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020485a:	00003517          	auipc	a0,0x3
ffffffffc020485e:	98650513          	addi	a0,a0,-1658 # ffffffffc02071e0 <default_pmm_manager+0xc08>
ffffffffc0204862:	933fb0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204866:	60a2                	ld	ra,8(sp)
ffffffffc0204868:	4501                	li	a0,0
ffffffffc020486a:	0141                	addi	sp,sp,16
ffffffffc020486c:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020486e:	00003697          	auipc	a3,0x3
ffffffffc0204872:	8b268693          	addi	a3,a3,-1870 # ffffffffc0207120 <default_pmm_manager+0xb48>
ffffffffc0204876:	00002617          	auipc	a2,0x2
ffffffffc020487a:	9b260613          	addi	a2,a2,-1614 # ffffffffc0206228 <commands+0x800>
ffffffffc020487e:	40600593          	li	a1,1030
ffffffffc0204882:	00002517          	auipc	a0,0x2
ffffffffc0204886:	7b650513          	addi	a0,a0,1974 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc020488a:	c05fb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc020488e:	00003617          	auipc	a2,0x3
ffffffffc0204892:	84a60613          	addi	a2,a2,-1974 # ffffffffc02070d8 <default_pmm_manager+0xb00>
ffffffffc0204896:	3fd00593          	li	a1,1021
ffffffffc020489a:	00002517          	auipc	a0,0x2
ffffffffc020489e:	79e50513          	addi	a0,a0,1950 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc02048a2:	bedfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02048a6:	00003697          	auipc	a3,0x3
ffffffffc02048aa:	90a68693          	addi	a3,a3,-1782 # ffffffffc02071b0 <default_pmm_manager+0xbd8>
ffffffffc02048ae:	00002617          	auipc	a2,0x2
ffffffffc02048b2:	97a60613          	addi	a2,a2,-1670 # ffffffffc0206228 <commands+0x800>
ffffffffc02048b6:	40900593          	li	a1,1033
ffffffffc02048ba:	00002517          	auipc	a0,0x2
ffffffffc02048be:	77e50513          	addi	a0,a0,1918 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc02048c2:	bcdfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048c6:	00003697          	auipc	a3,0x3
ffffffffc02048ca:	8ba68693          	addi	a3,a3,-1862 # ffffffffc0207180 <default_pmm_manager+0xba8>
ffffffffc02048ce:	00002617          	auipc	a2,0x2
ffffffffc02048d2:	95a60613          	addi	a2,a2,-1702 # ffffffffc0206228 <commands+0x800>
ffffffffc02048d6:	40800593          	li	a1,1032
ffffffffc02048da:	00002517          	auipc	a0,0x2
ffffffffc02048de:	75e50513          	addi	a0,a0,1886 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc02048e2:	badfb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc02048e6:	00003697          	auipc	a3,0x3
ffffffffc02048ea:	88a68693          	addi	a3,a3,-1910 # ffffffffc0207170 <default_pmm_manager+0xb98>
ffffffffc02048ee:	00002617          	auipc	a2,0x2
ffffffffc02048f2:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206228 <commands+0x800>
ffffffffc02048f6:	40700593          	li	a1,1031
ffffffffc02048fa:	00002517          	auipc	a0,0x2
ffffffffc02048fe:	73e50513          	addi	a0,a0,1854 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204902:	b8dfb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204906 <do_execve>:
{
ffffffffc0204906:	7171                	addi	sp,sp,-176
ffffffffc0204908:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020490a:	000a6d97          	auipc	s11,0xa6
ffffffffc020490e:	dbed8d93          	addi	s11,s11,-578 # ffffffffc02aa6c8 <current>
ffffffffc0204912:	000db783          	ld	a5,0(s11)
{
ffffffffc0204916:	e54e                	sd	s3,136(sp)
ffffffffc0204918:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020491a:	0287b983          	ld	s3,40(a5)
{
ffffffffc020491e:	e94a                	sd	s2,144(sp)
ffffffffc0204920:	f4de                	sd	s7,104(sp)
ffffffffc0204922:	892a                	mv	s2,a0
ffffffffc0204924:	8bb2                	mv	s7,a2
ffffffffc0204926:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204928:	862e                	mv	a2,a1
ffffffffc020492a:	4681                	li	a3,0
ffffffffc020492c:	85aa                	mv	a1,a0
ffffffffc020492e:	854e                	mv	a0,s3
{
ffffffffc0204930:	f506                	sd	ra,168(sp)
ffffffffc0204932:	f122                	sd	s0,160(sp)
ffffffffc0204934:	e152                	sd	s4,128(sp)
ffffffffc0204936:	fcd6                	sd	s5,120(sp)
ffffffffc0204938:	f8da                	sd	s6,112(sp)
ffffffffc020493a:	f0e2                	sd	s8,96(sp)
ffffffffc020493c:	ece6                	sd	s9,88(sp)
ffffffffc020493e:	e8ea                	sd	s10,80(sp)
ffffffffc0204940:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204942:	c02ff0ef          	jal	ra,ffffffffc0203d44 <user_mem_check>
ffffffffc0204946:	40050a63          	beqz	a0,ffffffffc0204d5a <do_execve+0x454>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020494a:	4641                	li	a2,16
ffffffffc020494c:	4581                	li	a1,0
ffffffffc020494e:	1808                	addi	a0,sp,48
ffffffffc0204950:	643000ef          	jal	ra,ffffffffc0205792 <memset>
    memcpy(local_name, name, len);
ffffffffc0204954:	47bd                	li	a5,15
ffffffffc0204956:	8626                	mv	a2,s1
ffffffffc0204958:	1e97e263          	bltu	a5,s1,ffffffffc0204b3c <do_execve+0x236>
ffffffffc020495c:	85ca                	mv	a1,s2
ffffffffc020495e:	1808                	addi	a0,sp,48
ffffffffc0204960:	645000ef          	jal	ra,ffffffffc02057a4 <memcpy>
    if (mm != NULL)
ffffffffc0204964:	1e098363          	beqz	s3,ffffffffc0204b4a <do_execve+0x244>
        cputs("mm != NULL");
ffffffffc0204968:	00002517          	auipc	a0,0x2
ffffffffc020496c:	49050513          	addi	a0,a0,1168 # ffffffffc0206df8 <default_pmm_manager+0x820>
ffffffffc0204970:	85dfb0ef          	jal	ra,ffffffffc02001cc <cputs>
ffffffffc0204974:	000a6797          	auipc	a5,0xa6
ffffffffc0204978:	d247b783          	ld	a5,-732(a5) # ffffffffc02aa698 <boot_pgdir_pa>
ffffffffc020497c:	577d                	li	a4,-1
ffffffffc020497e:	177e                	slli	a4,a4,0x3f
ffffffffc0204980:	83b1                	srli	a5,a5,0xc
ffffffffc0204982:	8fd9                	or	a5,a5,a4
ffffffffc0204984:	18079073          	csrw	satp,a5
ffffffffc0204988:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b70>
ffffffffc020498c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0204990:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0)
ffffffffc0204994:	2c070463          	beqz	a4,ffffffffc0204c5c <do_execve+0x356>
        current->mm = NULL;
ffffffffc0204998:	000db783          	ld	a5,0(s11)
ffffffffc020499c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02049a0:	d2ffe0ef          	jal	ra,ffffffffc02036ce <mm_create>
ffffffffc02049a4:	84aa                	mv	s1,a0
ffffffffc02049a6:	1c050d63          	beqz	a0,ffffffffc0204b80 <do_execve+0x27a>
    if ((page = alloc_page()) == NULL)
ffffffffc02049aa:	4505                	li	a0,1
ffffffffc02049ac:	d20fd0ef          	jal	ra,ffffffffc0201ecc <alloc_pages>
ffffffffc02049b0:	3a050963          	beqz	a0,ffffffffc0204d62 <do_execve+0x45c>
    return page - pages + nbase;
ffffffffc02049b4:	000a6c97          	auipc	s9,0xa6
ffffffffc02049b8:	cfcc8c93          	addi	s9,s9,-772 # ffffffffc02aa6b0 <pages>
ffffffffc02049bc:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc02049c0:	000a6c17          	auipc	s8,0xa6
ffffffffc02049c4:	ce8c0c13          	addi	s8,s8,-792 # ffffffffc02aa6a8 <npage>
    return page - pages + nbase;
ffffffffc02049c8:	00003717          	auipc	a4,0x3
ffffffffc02049cc:	f0873703          	ld	a4,-248(a4) # ffffffffc02078d0 <nbase>
ffffffffc02049d0:	40d506b3          	sub	a3,a0,a3
ffffffffc02049d4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02049d6:	5afd                	li	s5,-1
ffffffffc02049d8:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc02049dc:	96ba                	add	a3,a3,a4
ffffffffc02049de:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02049e0:	00cad713          	srli	a4,s5,0xc
ffffffffc02049e4:	ec3a                	sd	a4,24(sp)
ffffffffc02049e6:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02049e8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049ea:	38f77063          	bgeu	a4,a5,ffffffffc0204d6a <do_execve+0x464>
ffffffffc02049ee:	000a6b17          	auipc	s6,0xa6
ffffffffc02049f2:	cd2b0b13          	addi	s6,s6,-814 # ffffffffc02aa6c0 <va_pa_offset>
ffffffffc02049f6:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02049fa:	6605                	lui	a2,0x1
ffffffffc02049fc:	000a6597          	auipc	a1,0xa6
ffffffffc0204a00:	ca45b583          	ld	a1,-860(a1) # ffffffffc02aa6a0 <boot_pgdir_va>
ffffffffc0204a04:	9936                	add	s2,s2,a3
ffffffffc0204a06:	854a                	mv	a0,s2
ffffffffc0204a08:	59d000ef          	jal	ra,ffffffffc02057a4 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a0c:	7782                	ld	a5,32(sp)
ffffffffc0204a0e:	4398                	lw	a4,0(a5)
ffffffffc0204a10:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204a14:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a18:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9467>
ffffffffc0204a1c:	14f71863          	bne	a4,a5,ffffffffc0204b6c <do_execve+0x266>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a20:	7682                	ld	a3,32(sp)
ffffffffc0204a22:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a26:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a2a:	00371793          	slli	a5,a4,0x3
ffffffffc0204a2e:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a30:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a32:	078e                	slli	a5,a5,0x3
ffffffffc0204a34:	97ce                	add	a5,a5,s3
ffffffffc0204a36:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204a38:	00f9fc63          	bgeu	s3,a5,ffffffffc0204a50 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204a3c:	0009a783          	lw	a5,0(s3)
ffffffffc0204a40:	4705                	li	a4,1
ffffffffc0204a42:	14e78163          	beq	a5,a4,ffffffffc0204b84 <do_execve+0x27e>
    for (; ph < ph_end; ph++)
ffffffffc0204a46:	77a2                	ld	a5,40(sp)
ffffffffc0204a48:	03898993          	addi	s3,s3,56
ffffffffc0204a4c:	fef9e8e3          	bltu	s3,a5,ffffffffc0204a3c <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204a50:	4701                	li	a4,0
ffffffffc0204a52:	46ad                	li	a3,11
ffffffffc0204a54:	00100637          	lui	a2,0x100
ffffffffc0204a58:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204a5c:	8526                	mv	a0,s1
ffffffffc0204a5e:	e03fe0ef          	jal	ra,ffffffffc0203860 <mm_map>
ffffffffc0204a62:	8a2a                	mv	s4,a0
ffffffffc0204a64:	1e051263          	bnez	a0,ffffffffc0204c48 <do_execve+0x342>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204a68:	6c88                	ld	a0,24(s1)
ffffffffc0204a6a:	467d                	li	a2,31
ffffffffc0204a6c:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204a70:	b79fe0ef          	jal	ra,ffffffffc02035e8 <pgdir_alloc_page>
ffffffffc0204a74:	38050363          	beqz	a0,ffffffffc0204dfa <do_execve+0x4f4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a78:	6c88                	ld	a0,24(s1)
ffffffffc0204a7a:	467d                	li	a2,31
ffffffffc0204a7c:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204a80:	b69fe0ef          	jal	ra,ffffffffc02035e8 <pgdir_alloc_page>
ffffffffc0204a84:	34050b63          	beqz	a0,ffffffffc0204dda <do_execve+0x4d4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a88:	6c88                	ld	a0,24(s1)
ffffffffc0204a8a:	467d                	li	a2,31
ffffffffc0204a8c:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204a90:	b59fe0ef          	jal	ra,ffffffffc02035e8 <pgdir_alloc_page>
ffffffffc0204a94:	32050363          	beqz	a0,ffffffffc0204dba <do_execve+0x4b4>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204a98:	6c88                	ld	a0,24(s1)
ffffffffc0204a9a:	467d                	li	a2,31
ffffffffc0204a9c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204aa0:	b49fe0ef          	jal	ra,ffffffffc02035e8 <pgdir_alloc_page>
ffffffffc0204aa4:	2e050b63          	beqz	a0,ffffffffc0204d9a <do_execve+0x494>
    mm->mm_count += 1;
ffffffffc0204aa8:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc0204aaa:	000db603          	ld	a2,0(s11)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204aae:	6c94                	ld	a3,24(s1)
ffffffffc0204ab0:	2785                	addiw	a5,a5,1
ffffffffc0204ab2:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0204ab4:	f604                	sd	s1,40(a2)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204ab6:	c02007b7          	lui	a5,0xc0200
ffffffffc0204aba:	2cf6e463          	bltu	a3,a5,ffffffffc0204d82 <do_execve+0x47c>
ffffffffc0204abe:	000b3783          	ld	a5,0(s6)
ffffffffc0204ac2:	577d                	li	a4,-1
ffffffffc0204ac4:	177e                	slli	a4,a4,0x3f
ffffffffc0204ac6:	8e9d                	sub	a3,a3,a5
ffffffffc0204ac8:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204acc:	f654                	sd	a3,168(a2)
ffffffffc0204ace:	8fd9                	or	a5,a5,a4
ffffffffc0204ad0:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204ad4:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204ad6:	4581                	li	a1,0
ffffffffc0204ad8:	12000613          	li	a2,288
ffffffffc0204adc:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204ade:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204ae2:	4b1000ef          	jal	ra,ffffffffc0205792 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204ae6:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ae8:	000db903          	ld	s2,0(s11)
    tf->status = (sstatus & ~(SSTATUS_SPP | SSTATUS_SIE)) | SSTATUS_SPIE;
ffffffffc0204aec:	edd4f493          	andi	s1,s1,-291
    tf->epc = elf->e_entry;
ffffffffc0204af0:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204af2:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204af4:	0b490913          	addi	s2,s2,180 # ffffffff800000b4 <_binary_obj___user_exit_out_size+0xffffffff7fff4f9c>
    tf->gpr.sp = USTACKTOP;
ffffffffc0204af8:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~(SSTATUS_SPP | SSTATUS_SIE)) | SSTATUS_SPIE;
ffffffffc0204afa:	0204e493          	ori	s1,s1,32
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204afe:	4641                	li	a2,16
ffffffffc0204b00:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b02:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0204b04:	10e43423          	sd	a4,264(s0)
    tf->status = (sstatus & ~(SSTATUS_SPP | SSTATUS_SIE)) | SSTATUS_SPIE;
ffffffffc0204b08:	10943023          	sd	s1,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b0c:	854a                	mv	a0,s2
ffffffffc0204b0e:	485000ef          	jal	ra,ffffffffc0205792 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b12:	463d                	li	a2,15
ffffffffc0204b14:	180c                	addi	a1,sp,48
ffffffffc0204b16:	854a                	mv	a0,s2
ffffffffc0204b18:	48d000ef          	jal	ra,ffffffffc02057a4 <memcpy>
}
ffffffffc0204b1c:	70aa                	ld	ra,168(sp)
ffffffffc0204b1e:	740a                	ld	s0,160(sp)
ffffffffc0204b20:	64ea                	ld	s1,152(sp)
ffffffffc0204b22:	694a                	ld	s2,144(sp)
ffffffffc0204b24:	69aa                	ld	s3,136(sp)
ffffffffc0204b26:	7ae6                	ld	s5,120(sp)
ffffffffc0204b28:	7b46                	ld	s6,112(sp)
ffffffffc0204b2a:	7ba6                	ld	s7,104(sp)
ffffffffc0204b2c:	7c06                	ld	s8,96(sp)
ffffffffc0204b2e:	6ce6                	ld	s9,88(sp)
ffffffffc0204b30:	6d46                	ld	s10,80(sp)
ffffffffc0204b32:	6da6                	ld	s11,72(sp)
ffffffffc0204b34:	8552                	mv	a0,s4
ffffffffc0204b36:	6a0a                	ld	s4,128(sp)
ffffffffc0204b38:	614d                	addi	sp,sp,176
ffffffffc0204b3a:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc0204b3c:	463d                	li	a2,15
ffffffffc0204b3e:	85ca                	mv	a1,s2
ffffffffc0204b40:	1808                	addi	a0,sp,48
ffffffffc0204b42:	463000ef          	jal	ra,ffffffffc02057a4 <memcpy>
    if (mm != NULL)
ffffffffc0204b46:	e20991e3          	bnez	s3,ffffffffc0204968 <do_execve+0x62>
    if (current->mm != NULL)
ffffffffc0204b4a:	000db783          	ld	a5,0(s11)
ffffffffc0204b4e:	779c                	ld	a5,40(a5)
ffffffffc0204b50:	e40788e3          	beqz	a5,ffffffffc02049a0 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204b54:	00002617          	auipc	a2,0x2
ffffffffc0204b58:	6ac60613          	addi	a2,a2,1708 # ffffffffc0207200 <default_pmm_manager+0xc28>
ffffffffc0204b5c:	28000593          	li	a1,640
ffffffffc0204b60:	00002517          	auipc	a0,0x2
ffffffffc0204b64:	4d850513          	addi	a0,a0,1240 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204b68:	927fb0ef          	jal	ra,ffffffffc020048e <__panic>
    put_pgdir(mm);
ffffffffc0204b6c:	8526                	mv	a0,s1
ffffffffc0204b6e:	c88ff0ef          	jal	ra,ffffffffc0203ff6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204b72:	8526                	mv	a0,s1
ffffffffc0204b74:	c9bfe0ef          	jal	ra,ffffffffc020380e <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc0204b78:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0204b7a:	8552                	mv	a0,s4
ffffffffc0204b7c:	94bff0ef          	jal	ra,ffffffffc02044c6 <do_exit>
    int ret = -E_NO_MEM;
ffffffffc0204b80:	5a71                	li	s4,-4
ffffffffc0204b82:	bfe5                	j	ffffffffc0204b7a <do_execve+0x274>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204b84:	0289b603          	ld	a2,40(s3)
ffffffffc0204b88:	0209b783          	ld	a5,32(s3)
ffffffffc0204b8c:	1cf66d63          	bltu	a2,a5,ffffffffc0204d66 <do_execve+0x460>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b90:	0049a783          	lw	a5,4(s3)
ffffffffc0204b94:	0017f693          	andi	a3,a5,1
ffffffffc0204b98:	c291                	beqz	a3,ffffffffc0204b9c <do_execve+0x296>
            vm_flags |= VM_EXEC;
ffffffffc0204b9a:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b9c:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ba0:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204ba2:	e779                	bnez	a4,ffffffffc0204c70 <do_execve+0x36a>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204ba4:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204ba6:	c781                	beqz	a5,ffffffffc0204bae <do_execve+0x2a8>
            vm_flags |= VM_READ;
ffffffffc0204ba8:	0016e693          	ori	a3,a3,1
            perm |= PTE_R;
ffffffffc0204bac:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE)
ffffffffc0204bae:	0026f793          	andi	a5,a3,2
ffffffffc0204bb2:	e3f1                	bnez	a5,ffffffffc0204c76 <do_execve+0x370>
        if (vm_flags & VM_EXEC)
ffffffffc0204bb4:	0046f793          	andi	a5,a3,4
ffffffffc0204bb8:	c399                	beqz	a5,ffffffffc0204bbe <do_execve+0x2b8>
            perm |= PTE_X;
ffffffffc0204bba:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204bbe:	0109b583          	ld	a1,16(s3)
ffffffffc0204bc2:	4701                	li	a4,0
ffffffffc0204bc4:	8526                	mv	a0,s1
ffffffffc0204bc6:	c9bfe0ef          	jal	ra,ffffffffc0203860 <mm_map>
ffffffffc0204bca:	8a2a                	mv	s4,a0
ffffffffc0204bcc:	ed35                	bnez	a0,ffffffffc0204c48 <do_execve+0x342>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bce:	0109bb83          	ld	s7,16(s3)
ffffffffc0204bd2:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bd4:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204bd8:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bdc:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204be0:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204be2:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204be4:	993e                	add	s2,s2,a5
        while (start < end)
ffffffffc0204be6:	054be963          	bltu	s7,s4,ffffffffc0204c38 <do_execve+0x332>
ffffffffc0204bea:	aa95                	j	ffffffffc0204d5e <do_execve+0x458>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204bec:	6785                	lui	a5,0x1
ffffffffc0204bee:	415b8533          	sub	a0,s7,s5
ffffffffc0204bf2:	9abe                	add	s5,s5,a5
ffffffffc0204bf4:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204bf8:	015a7463          	bgeu	s4,s5,ffffffffc0204c00 <do_execve+0x2fa>
                size -= la - end;
ffffffffc0204bfc:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0204c00:	000cb683          	ld	a3,0(s9)
ffffffffc0204c04:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204c06:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204c0a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c0e:	8699                	srai	a3,a3,0x6
ffffffffc0204c10:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204c12:	67e2                	ld	a5,24(sp)
ffffffffc0204c14:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c18:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c1a:	14b87863          	bgeu	a6,a1,ffffffffc0204d6a <do_execve+0x464>
ffffffffc0204c1e:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c22:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0204c24:	9bb2                	add	s7,s7,a2
ffffffffc0204c26:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c28:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0204c2a:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c2c:	379000ef          	jal	ra,ffffffffc02057a4 <memcpy>
            start += size, from += size;
ffffffffc0204c30:	6622                	ld	a2,8(sp)
ffffffffc0204c32:	9932                	add	s2,s2,a2
        while (start < end)
ffffffffc0204c34:	054bf363          	bgeu	s7,s4,ffffffffc0204c7a <do_execve+0x374>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c38:	6c88                	ld	a0,24(s1)
ffffffffc0204c3a:	866a                	mv	a2,s10
ffffffffc0204c3c:	85d6                	mv	a1,s5
ffffffffc0204c3e:	9abfe0ef          	jal	ra,ffffffffc02035e8 <pgdir_alloc_page>
ffffffffc0204c42:	842a                	mv	s0,a0
ffffffffc0204c44:	f545                	bnez	a0,ffffffffc0204bec <do_execve+0x2e6>
        ret = -E_NO_MEM;
ffffffffc0204c46:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0204c48:	8526                	mv	a0,s1
ffffffffc0204c4a:	d61fe0ef          	jal	ra,ffffffffc02039aa <exit_mmap>
    put_pgdir(mm);
ffffffffc0204c4e:	8526                	mv	a0,s1
ffffffffc0204c50:	ba6ff0ef          	jal	ra,ffffffffc0203ff6 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204c54:	8526                	mv	a0,s1
ffffffffc0204c56:	bb9fe0ef          	jal	ra,ffffffffc020380e <mm_destroy>
    return ret;
ffffffffc0204c5a:	b705                	j	ffffffffc0204b7a <do_execve+0x274>
            exit_mmap(mm);
ffffffffc0204c5c:	854e                	mv	a0,s3
ffffffffc0204c5e:	d4dfe0ef          	jal	ra,ffffffffc02039aa <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c62:	854e                	mv	a0,s3
ffffffffc0204c64:	b92ff0ef          	jal	ra,ffffffffc0203ff6 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c68:	854e                	mv	a0,s3
ffffffffc0204c6a:	ba5fe0ef          	jal	ra,ffffffffc020380e <mm_destroy>
ffffffffc0204c6e:	b32d                	j	ffffffffc0204998 <do_execve+0x92>
            vm_flags |= VM_WRITE;
ffffffffc0204c70:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c74:	fb95                	bnez	a5,ffffffffc0204ba8 <do_execve+0x2a2>
            perm |= (PTE_W | PTE_R);
ffffffffc0204c76:	4d5d                	li	s10,23
ffffffffc0204c78:	bf35                	j	ffffffffc0204bb4 <do_execve+0x2ae>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204c7a:	0109b683          	ld	a3,16(s3)
ffffffffc0204c7e:	0289b903          	ld	s2,40(s3)
ffffffffc0204c82:	9936                	add	s2,s2,a3
        if (start < la)
ffffffffc0204c84:	075bfd63          	bgeu	s7,s5,ffffffffc0204cfe <do_execve+0x3f8>
            if (start == end)
ffffffffc0204c88:	db790fe3          	beq	s2,s7,ffffffffc0204a46 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204c8c:	6785                	lui	a5,0x1
ffffffffc0204c8e:	00fb8533          	add	a0,s7,a5
ffffffffc0204c92:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0204c96:	41790a33          	sub	s4,s2,s7
            if (end < la)
ffffffffc0204c9a:	0b597d63          	bgeu	s2,s5,ffffffffc0204d54 <do_execve+0x44e>
    return page - pages + nbase;
ffffffffc0204c9e:	000cb683          	ld	a3,0(s9)
ffffffffc0204ca2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204ca4:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0204ca8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cac:	8699                	srai	a3,a3,0x6
ffffffffc0204cae:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204cb0:	67e2                	ld	a5,24(sp)
ffffffffc0204cb2:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cb6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cb8:	0ac5f963          	bgeu	a1,a2,ffffffffc0204d6a <do_execve+0x464>
ffffffffc0204cbc:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cc0:	8652                	mv	a2,s4
ffffffffc0204cc2:	4581                	li	a1,0
ffffffffc0204cc4:	96c2                	add	a3,a3,a6
ffffffffc0204cc6:	9536                	add	a0,a0,a3
ffffffffc0204cc8:	2cb000ef          	jal	ra,ffffffffc0205792 <memset>
            start += size;
ffffffffc0204ccc:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204cd0:	03597463          	bgeu	s2,s5,ffffffffc0204cf8 <do_execve+0x3f2>
ffffffffc0204cd4:	d6e909e3          	beq	s2,a4,ffffffffc0204a46 <do_execve+0x140>
ffffffffc0204cd8:	00002697          	auipc	a3,0x2
ffffffffc0204cdc:	55068693          	addi	a3,a3,1360 # ffffffffc0207228 <default_pmm_manager+0xc50>
ffffffffc0204ce0:	00001617          	auipc	a2,0x1
ffffffffc0204ce4:	54860613          	addi	a2,a2,1352 # ffffffffc0206228 <commands+0x800>
ffffffffc0204ce8:	2e900593          	li	a1,745
ffffffffc0204cec:	00002517          	auipc	a0,0x2
ffffffffc0204cf0:	34c50513          	addi	a0,a0,844 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204cf4:	f9afb0ef          	jal	ra,ffffffffc020048e <__panic>
ffffffffc0204cf8:	ff5710e3          	bne	a4,s5,ffffffffc0204cd8 <do_execve+0x3d2>
ffffffffc0204cfc:	8bd6                	mv	s7,s5
        while (start < end)
ffffffffc0204cfe:	d52bf4e3          	bgeu	s7,s2,ffffffffc0204a46 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d02:	6c88                	ld	a0,24(s1)
ffffffffc0204d04:	866a                	mv	a2,s10
ffffffffc0204d06:	85d6                	mv	a1,s5
ffffffffc0204d08:	8e1fe0ef          	jal	ra,ffffffffc02035e8 <pgdir_alloc_page>
ffffffffc0204d0c:	842a                	mv	s0,a0
ffffffffc0204d0e:	dd05                	beqz	a0,ffffffffc0204c46 <do_execve+0x340>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d10:	6785                	lui	a5,0x1
ffffffffc0204d12:	415b8533          	sub	a0,s7,s5
ffffffffc0204d16:	9abe                	add	s5,s5,a5
ffffffffc0204d18:	417a8633          	sub	a2,s5,s7
            if (end < la)
ffffffffc0204d1c:	01597463          	bgeu	s2,s5,ffffffffc0204d24 <do_execve+0x41e>
                size -= la - end;
ffffffffc0204d20:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0204d24:	000cb683          	ld	a3,0(s9)
ffffffffc0204d28:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0204d2a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0204d2e:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d32:	8699                	srai	a3,a3,0x6
ffffffffc0204d34:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204d36:	67e2                	ld	a5,24(sp)
ffffffffc0204d38:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d3c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d3e:	02b87663          	bgeu	a6,a1,ffffffffc0204d6a <do_execve+0x464>
ffffffffc0204d42:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d46:	4581                	li	a1,0
            start += size;
ffffffffc0204d48:	9bb2                	add	s7,s7,a2
ffffffffc0204d4a:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d4c:	9536                	add	a0,a0,a3
ffffffffc0204d4e:	245000ef          	jal	ra,ffffffffc0205792 <memset>
ffffffffc0204d52:	b775                	j	ffffffffc0204cfe <do_execve+0x3f8>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d54:	417a8a33          	sub	s4,s5,s7
ffffffffc0204d58:	b799                	j	ffffffffc0204c9e <do_execve+0x398>
        return -E_INVAL;
ffffffffc0204d5a:	5a75                	li	s4,-3
ffffffffc0204d5c:	b3c1                	j	ffffffffc0204b1c <do_execve+0x216>
        while (start < end)
ffffffffc0204d5e:	86de                	mv	a3,s7
ffffffffc0204d60:	bf39                	j	ffffffffc0204c7e <do_execve+0x378>
    int ret = -E_NO_MEM;
ffffffffc0204d62:	5a71                	li	s4,-4
ffffffffc0204d64:	bdc5                	j	ffffffffc0204c54 <do_execve+0x34e>
            ret = -E_INVAL_ELF;
ffffffffc0204d66:	5a61                	li	s4,-8
ffffffffc0204d68:	b5c5                	j	ffffffffc0204c48 <do_execve+0x342>
ffffffffc0204d6a:	00002617          	auipc	a2,0x2
ffffffffc0204d6e:	8a660613          	addi	a2,a2,-1882 # ffffffffc0206610 <default_pmm_manager+0x38>
ffffffffc0204d72:	07100593          	li	a1,113
ffffffffc0204d76:	00002517          	auipc	a0,0x2
ffffffffc0204d7a:	8c250513          	addi	a0,a0,-1854 # ffffffffc0206638 <default_pmm_manager+0x60>
ffffffffc0204d7e:	f10fb0ef          	jal	ra,ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204d82:	00002617          	auipc	a2,0x2
ffffffffc0204d86:	93660613          	addi	a2,a2,-1738 # ffffffffc02066b8 <default_pmm_manager+0xe0>
ffffffffc0204d8a:	30800593          	li	a1,776
ffffffffc0204d8e:	00002517          	auipc	a0,0x2
ffffffffc0204d92:	2aa50513          	addi	a0,a0,682 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204d96:	ef8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204d9a:	00002697          	auipc	a3,0x2
ffffffffc0204d9e:	5a668693          	addi	a3,a3,1446 # ffffffffc0207340 <default_pmm_manager+0xd68>
ffffffffc0204da2:	00001617          	auipc	a2,0x1
ffffffffc0204da6:	48660613          	addi	a2,a2,1158 # ffffffffc0206228 <commands+0x800>
ffffffffc0204daa:	30300593          	li	a1,771
ffffffffc0204dae:	00002517          	auipc	a0,0x2
ffffffffc0204db2:	28a50513          	addi	a0,a0,650 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204db6:	ed8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204dba:	00002697          	auipc	a3,0x2
ffffffffc0204dbe:	53e68693          	addi	a3,a3,1342 # ffffffffc02072f8 <default_pmm_manager+0xd20>
ffffffffc0204dc2:	00001617          	auipc	a2,0x1
ffffffffc0204dc6:	46660613          	addi	a2,a2,1126 # ffffffffc0206228 <commands+0x800>
ffffffffc0204dca:	30200593          	li	a1,770
ffffffffc0204dce:	00002517          	auipc	a0,0x2
ffffffffc0204dd2:	26a50513          	addi	a0,a0,618 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204dd6:	eb8fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204dda:	00002697          	auipc	a3,0x2
ffffffffc0204dde:	4d668693          	addi	a3,a3,1238 # ffffffffc02072b0 <default_pmm_manager+0xcd8>
ffffffffc0204de2:	00001617          	auipc	a2,0x1
ffffffffc0204de6:	44660613          	addi	a2,a2,1094 # ffffffffc0206228 <commands+0x800>
ffffffffc0204dea:	30100593          	li	a1,769
ffffffffc0204dee:	00002517          	auipc	a0,0x2
ffffffffc0204df2:	24a50513          	addi	a0,a0,586 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204df6:	e98fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204dfa:	00002697          	auipc	a3,0x2
ffffffffc0204dfe:	46e68693          	addi	a3,a3,1134 # ffffffffc0207268 <default_pmm_manager+0xc90>
ffffffffc0204e02:	00001617          	auipc	a2,0x1
ffffffffc0204e06:	42660613          	addi	a2,a2,1062 # ffffffffc0206228 <commands+0x800>
ffffffffc0204e0a:	30000593          	li	a1,768
ffffffffc0204e0e:	00002517          	auipc	a0,0x2
ffffffffc0204e12:	22a50513          	addi	a0,a0,554 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0204e16:	e78fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0204e1a <do_yield>:
    current->need_resched = 1;
ffffffffc0204e1a:	000a6797          	auipc	a5,0xa6
ffffffffc0204e1e:	8ae7b783          	ld	a5,-1874(a5) # ffffffffc02aa6c8 <current>
ffffffffc0204e22:	4705                	li	a4,1
ffffffffc0204e24:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e26:	4501                	li	a0,0
ffffffffc0204e28:	8082                	ret

ffffffffc0204e2a <do_wait>:
{
ffffffffc0204e2a:	1101                	addi	sp,sp,-32
ffffffffc0204e2c:	e822                	sd	s0,16(sp)
ffffffffc0204e2e:	e426                	sd	s1,8(sp)
ffffffffc0204e30:	ec06                	sd	ra,24(sp)
ffffffffc0204e32:	842e                	mv	s0,a1
ffffffffc0204e34:	84aa                	mv	s1,a0
    if (code_store != NULL)
ffffffffc0204e36:	c999                	beqz	a1,ffffffffc0204e4c <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0204e38:	000a6797          	auipc	a5,0xa6
ffffffffc0204e3c:	8907b783          	ld	a5,-1904(a5) # ffffffffc02aa6c8 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e40:	7788                	ld	a0,40(a5)
ffffffffc0204e42:	4685                	li	a3,1
ffffffffc0204e44:	4611                	li	a2,4
ffffffffc0204e46:	efffe0ef          	jal	ra,ffffffffc0203d44 <user_mem_check>
ffffffffc0204e4a:	c909                	beqz	a0,ffffffffc0204e5c <do_wait+0x32>
ffffffffc0204e4c:	85a2                	mv	a1,s0
}
ffffffffc0204e4e:	6442                	ld	s0,16(sp)
ffffffffc0204e50:	60e2                	ld	ra,24(sp)
ffffffffc0204e52:	8526                	mv	a0,s1
ffffffffc0204e54:	64a2                	ld	s1,8(sp)
ffffffffc0204e56:	6105                	addi	sp,sp,32
ffffffffc0204e58:	fb8ff06f          	j	ffffffffc0204610 <do_wait.part.0>
ffffffffc0204e5c:	60e2                	ld	ra,24(sp)
ffffffffc0204e5e:	6442                	ld	s0,16(sp)
ffffffffc0204e60:	64a2                	ld	s1,8(sp)
ffffffffc0204e62:	5575                	li	a0,-3
ffffffffc0204e64:	6105                	addi	sp,sp,32
ffffffffc0204e66:	8082                	ret

ffffffffc0204e68 <do_kill>:
{
ffffffffc0204e68:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e6a:	6789                	lui	a5,0x2
{
ffffffffc0204e6c:	e406                	sd	ra,8(sp)
ffffffffc0204e6e:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID)
ffffffffc0204e70:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204e74:	17f9                	addi	a5,a5,-2
ffffffffc0204e76:	02e7e963          	bltu	a5,a4,ffffffffc0204ea8 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204e7a:	842a                	mv	s0,a0
ffffffffc0204e7c:	45a9                	li	a1,10
ffffffffc0204e7e:	2501                	sext.w	a0,a0
ffffffffc0204e80:	46c000ef          	jal	ra,ffffffffc02052ec <hash32>
ffffffffc0204e84:	02051793          	slli	a5,a0,0x20
ffffffffc0204e88:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204e8c:	000a1797          	auipc	a5,0xa1
ffffffffc0204e90:	7cc78793          	addi	a5,a5,1996 # ffffffffc02a6658 <hash_list>
ffffffffc0204e94:	953e                	add	a0,a0,a5
ffffffffc0204e96:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204e98:	a029                	j	ffffffffc0204ea2 <do_kill+0x3a>
            if (proc->pid == pid)
ffffffffc0204e9a:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204e9e:	00870b63          	beq	a4,s0,ffffffffc0204eb4 <do_kill+0x4c>
ffffffffc0204ea2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ea4:	fef51be3          	bne	a0,a5,ffffffffc0204e9a <do_kill+0x32>
    return -E_INVAL;
ffffffffc0204ea8:	5475                	li	s0,-3
}
ffffffffc0204eaa:	60a2                	ld	ra,8(sp)
ffffffffc0204eac:	8522                	mv	a0,s0
ffffffffc0204eae:	6402                	ld	s0,0(sp)
ffffffffc0204eb0:	0141                	addi	sp,sp,16
ffffffffc0204eb2:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204eb4:	fd87a703          	lw	a4,-40(a5)
ffffffffc0204eb8:	00177693          	andi	a3,a4,1
ffffffffc0204ebc:	e295                	bnez	a3,ffffffffc0204ee0 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204ebe:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0204ec0:	00176713          	ori	a4,a4,1
ffffffffc0204ec4:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0204ec8:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204eca:	fe06d0e3          	bgez	a3,ffffffffc0204eaa <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0204ece:	f2878513          	addi	a0,a5,-216
ffffffffc0204ed2:	22e000ef          	jal	ra,ffffffffc0205100 <wakeup_proc>
}
ffffffffc0204ed6:	60a2                	ld	ra,8(sp)
ffffffffc0204ed8:	8522                	mv	a0,s0
ffffffffc0204eda:	6402                	ld	s0,0(sp)
ffffffffc0204edc:	0141                	addi	sp,sp,16
ffffffffc0204ede:	8082                	ret
        return -E_KILLED;
ffffffffc0204ee0:	545d                	li	s0,-9
ffffffffc0204ee2:	b7e1                	j	ffffffffc0204eaa <do_kill+0x42>

ffffffffc0204ee4 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204ee4:	1101                	addi	sp,sp,-32
ffffffffc0204ee6:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204ee8:	000a5797          	auipc	a5,0xa5
ffffffffc0204eec:	77078793          	addi	a5,a5,1904 # ffffffffc02aa658 <proc_list>
ffffffffc0204ef0:	ec06                	sd	ra,24(sp)
ffffffffc0204ef2:	e822                	sd	s0,16(sp)
ffffffffc0204ef4:	e04a                	sd	s2,0(sp)
ffffffffc0204ef6:	000a1497          	auipc	s1,0xa1
ffffffffc0204efa:	76248493          	addi	s1,s1,1890 # ffffffffc02a6658 <hash_list>
ffffffffc0204efe:	e79c                	sd	a5,8(a5)
ffffffffc0204f00:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f02:	000a5717          	auipc	a4,0xa5
ffffffffc0204f06:	75670713          	addi	a4,a4,1878 # ffffffffc02aa658 <proc_list>
ffffffffc0204f0a:	87a6                	mv	a5,s1
ffffffffc0204f0c:	e79c                	sd	a5,8(a5)
ffffffffc0204f0e:	e39c                	sd	a5,0(a5)
ffffffffc0204f10:	07c1                	addi	a5,a5,16
ffffffffc0204f12:	fef71de3          	bne	a4,a5,ffffffffc0204f0c <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f16:	fd3fe0ef          	jal	ra,ffffffffc0203ee8 <alloc_proc>
ffffffffc0204f1a:	000a5917          	auipc	s2,0xa5
ffffffffc0204f1e:	7b690913          	addi	s2,s2,1974 # ffffffffc02aa6d0 <idleproc>
ffffffffc0204f22:	00a93023          	sd	a0,0(s2)
ffffffffc0204f26:	0e050f63          	beqz	a0,ffffffffc0205024 <proc_init+0x140>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f2a:	4789                	li	a5,2
ffffffffc0204f2c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f2e:	00003797          	auipc	a5,0x3
ffffffffc0204f32:	0d278793          	addi	a5,a5,210 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f36:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f3a:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204f3c:	4785                	li	a5,1
ffffffffc0204f3e:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f40:	4641                	li	a2,16
ffffffffc0204f42:	4581                	li	a1,0
ffffffffc0204f44:	8522                	mv	a0,s0
ffffffffc0204f46:	04d000ef          	jal	ra,ffffffffc0205792 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f4a:	463d                	li	a2,15
ffffffffc0204f4c:	00002597          	auipc	a1,0x2
ffffffffc0204f50:	45458593          	addi	a1,a1,1108 # ffffffffc02073a0 <default_pmm_manager+0xdc8>
ffffffffc0204f54:	8522                	mv	a0,s0
ffffffffc0204f56:	04f000ef          	jal	ra,ffffffffc02057a4 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f5a:	000a5717          	auipc	a4,0xa5
ffffffffc0204f5e:	78670713          	addi	a4,a4,1926 # ffffffffc02aa6e0 <nr_process>
ffffffffc0204f62:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0204f64:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f68:	4601                	li	a2,0
    nr_process++;
ffffffffc0204f6a:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f6c:	4581                	li	a1,0
ffffffffc0204f6e:	00000517          	auipc	a0,0x0
ffffffffc0204f72:	87450513          	addi	a0,a0,-1932 # ffffffffc02047e2 <init_main>
    nr_process++;
ffffffffc0204f76:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0204f78:	000a5797          	auipc	a5,0xa5
ffffffffc0204f7c:	74d7b823          	sd	a3,1872(a5) # ffffffffc02aa6c8 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204f80:	cf6ff0ef          	jal	ra,ffffffffc0204476 <kernel_thread>
ffffffffc0204f84:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204f86:	08a05363          	blez	a0,ffffffffc020500c <proc_init+0x128>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f8a:	6789                	lui	a5,0x2
ffffffffc0204f8c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f90:	17f9                	addi	a5,a5,-2
ffffffffc0204f92:	2501                	sext.w	a0,a0
ffffffffc0204f94:	02e7e363          	bltu	a5,a4,ffffffffc0204fba <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f98:	45a9                	li	a1,10
ffffffffc0204f9a:	352000ef          	jal	ra,ffffffffc02052ec <hash32>
ffffffffc0204f9e:	02051793          	slli	a5,a0,0x20
ffffffffc0204fa2:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204fa6:	96a6                	add	a3,a3,s1
ffffffffc0204fa8:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204faa:	a029                	j	ffffffffc0204fb4 <proc_init+0xd0>
            if (proc->pid == pid)
ffffffffc0204fac:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c74>
ffffffffc0204fb0:	04870b63          	beq	a4,s0,ffffffffc0205006 <proc_init+0x122>
    return listelm->next;
ffffffffc0204fb4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204fb6:	fef69be3          	bne	a3,a5,ffffffffc0204fac <proc_init+0xc8>
    return NULL;
ffffffffc0204fba:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fbc:	0b478493          	addi	s1,a5,180
ffffffffc0204fc0:	4641                	li	a2,16
ffffffffc0204fc2:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0204fc4:	000a5417          	auipc	s0,0xa5
ffffffffc0204fc8:	71440413          	addi	s0,s0,1812 # ffffffffc02aa6d8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fcc:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0204fce:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fd0:	7c2000ef          	jal	ra,ffffffffc0205792 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fd4:	463d                	li	a2,15
ffffffffc0204fd6:	00002597          	auipc	a1,0x2
ffffffffc0204fda:	3f258593          	addi	a1,a1,1010 # ffffffffc02073c8 <default_pmm_manager+0xdf0>
ffffffffc0204fde:	8526                	mv	a0,s1
ffffffffc0204fe0:	7c4000ef          	jal	ra,ffffffffc02057a4 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0204fe4:	00093783          	ld	a5,0(s2)
ffffffffc0204fe8:	cbb5                	beqz	a5,ffffffffc020505c <proc_init+0x178>
ffffffffc0204fea:	43dc                	lw	a5,4(a5)
ffffffffc0204fec:	eba5                	bnez	a5,ffffffffc020505c <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0204fee:	601c                	ld	a5,0(s0)
ffffffffc0204ff0:	c7b1                	beqz	a5,ffffffffc020503c <proc_init+0x158>
ffffffffc0204ff2:	43d8                	lw	a4,4(a5)
ffffffffc0204ff4:	4785                	li	a5,1
ffffffffc0204ff6:	04f71363          	bne	a4,a5,ffffffffc020503c <proc_init+0x158>
}
ffffffffc0204ffa:	60e2                	ld	ra,24(sp)
ffffffffc0204ffc:	6442                	ld	s0,16(sp)
ffffffffc0204ffe:	64a2                	ld	s1,8(sp)
ffffffffc0205000:	6902                	ld	s2,0(sp)
ffffffffc0205002:	6105                	addi	sp,sp,32
ffffffffc0205004:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205006:	f2878793          	addi	a5,a5,-216
ffffffffc020500a:	bf4d                	j	ffffffffc0204fbc <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc020500c:	00002617          	auipc	a2,0x2
ffffffffc0205010:	39c60613          	addi	a2,a2,924 # ffffffffc02073a8 <default_pmm_manager+0xdd0>
ffffffffc0205014:	42c00593          	li	a1,1068
ffffffffc0205018:	00002517          	auipc	a0,0x2
ffffffffc020501c:	02050513          	addi	a0,a0,32 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0205020:	c6efb0ef          	jal	ra,ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205024:	00002617          	auipc	a2,0x2
ffffffffc0205028:	36460613          	addi	a2,a2,868 # ffffffffc0207388 <default_pmm_manager+0xdb0>
ffffffffc020502c:	41d00593          	li	a1,1053
ffffffffc0205030:	00002517          	auipc	a0,0x2
ffffffffc0205034:	00850513          	addi	a0,a0,8 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0205038:	c56fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020503c:	00002697          	auipc	a3,0x2
ffffffffc0205040:	3bc68693          	addi	a3,a3,956 # ffffffffc02073f8 <default_pmm_manager+0xe20>
ffffffffc0205044:	00001617          	auipc	a2,0x1
ffffffffc0205048:	1e460613          	addi	a2,a2,484 # ffffffffc0206228 <commands+0x800>
ffffffffc020504c:	43300593          	li	a1,1075
ffffffffc0205050:	00002517          	auipc	a0,0x2
ffffffffc0205054:	fe850513          	addi	a0,a0,-24 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0205058:	c36fb0ef          	jal	ra,ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020505c:	00002697          	auipc	a3,0x2
ffffffffc0205060:	37468693          	addi	a3,a3,884 # ffffffffc02073d0 <default_pmm_manager+0xdf8>
ffffffffc0205064:	00001617          	auipc	a2,0x1
ffffffffc0205068:	1c460613          	addi	a2,a2,452 # ffffffffc0206228 <commands+0x800>
ffffffffc020506c:	43200593          	li	a1,1074
ffffffffc0205070:	00002517          	auipc	a0,0x2
ffffffffc0205074:	fc850513          	addi	a0,a0,-56 # ffffffffc0207038 <default_pmm_manager+0xa60>
ffffffffc0205078:	c16fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc020507c <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc020507c:	1141                	addi	sp,sp,-16
ffffffffc020507e:	e022                	sd	s0,0(sp)
ffffffffc0205080:	e406                	sd	ra,8(sp)
ffffffffc0205082:	000a5417          	auipc	s0,0xa5
ffffffffc0205086:	64640413          	addi	s0,s0,1606 # ffffffffc02aa6c8 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020508a:	6018                	ld	a4,0(s0)
ffffffffc020508c:	6f1c                	ld	a5,24(a4)
ffffffffc020508e:	dffd                	beqz	a5,ffffffffc020508c <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205090:	0f0000ef          	jal	ra,ffffffffc0205180 <schedule>
ffffffffc0205094:	bfdd                	j	ffffffffc020508a <cpu_idle+0xe>

ffffffffc0205096 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205096:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020509a:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020509e:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02050a0:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02050a2:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02050a6:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02050aa:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02050ae:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02050b2:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02050b6:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02050ba:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02050be:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02050c2:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02050c6:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02050ca:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02050ce:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02050d2:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02050d4:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02050d6:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02050da:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02050de:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02050e2:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02050e6:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02050ea:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02050ee:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02050f2:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02050f6:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02050fa:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02050fe:	8082                	ret

ffffffffc0205100 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205100:	4118                	lw	a4,0(a0)
{
ffffffffc0205102:	1101                	addi	sp,sp,-32
ffffffffc0205104:	ec06                	sd	ra,24(sp)
ffffffffc0205106:	e822                	sd	s0,16(sp)
ffffffffc0205108:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020510a:	478d                	li	a5,3
ffffffffc020510c:	04f70b63          	beq	a4,a5,ffffffffc0205162 <wakeup_proc+0x62>
ffffffffc0205110:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205112:	100027f3          	csrr	a5,sstatus
ffffffffc0205116:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205118:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020511a:	ef9d                	bnez	a5,ffffffffc0205158 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc020511c:	4789                	li	a5,2
ffffffffc020511e:	02f70163          	beq	a4,a5,ffffffffc0205140 <wakeup_proc+0x40>
        {
            proc->state = PROC_RUNNABLE;
ffffffffc0205122:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205124:	0e042623          	sw	zero,236(s0)
    if (flag)
ffffffffc0205128:	e491                	bnez	s1,ffffffffc0205134 <wakeup_proc+0x34>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020512a:	60e2                	ld	ra,24(sp)
ffffffffc020512c:	6442                	ld	s0,16(sp)
ffffffffc020512e:	64a2                	ld	s1,8(sp)
ffffffffc0205130:	6105                	addi	sp,sp,32
ffffffffc0205132:	8082                	ret
ffffffffc0205134:	6442                	ld	s0,16(sp)
ffffffffc0205136:	60e2                	ld	ra,24(sp)
ffffffffc0205138:	64a2                	ld	s1,8(sp)
ffffffffc020513a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020513c:	873fb06f          	j	ffffffffc02009ae <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205140:	00002617          	auipc	a2,0x2
ffffffffc0205144:	31860613          	addi	a2,a2,792 # ffffffffc0207458 <default_pmm_manager+0xe80>
ffffffffc0205148:	45d1                	li	a1,20
ffffffffc020514a:	00002517          	auipc	a0,0x2
ffffffffc020514e:	2f650513          	addi	a0,a0,758 # ffffffffc0207440 <default_pmm_manager+0xe68>
ffffffffc0205152:	ba4fb0ef          	jal	ra,ffffffffc02004f6 <__warn>
ffffffffc0205156:	bfc9                	j	ffffffffc0205128 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205158:	85dfb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc020515c:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc020515e:	4485                	li	s1,1
ffffffffc0205160:	bf75                	j	ffffffffc020511c <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205162:	00002697          	auipc	a3,0x2
ffffffffc0205166:	2be68693          	addi	a3,a3,702 # ffffffffc0207420 <default_pmm_manager+0xe48>
ffffffffc020516a:	00001617          	auipc	a2,0x1
ffffffffc020516e:	0be60613          	addi	a2,a2,190 # ffffffffc0206228 <commands+0x800>
ffffffffc0205172:	45a5                	li	a1,9
ffffffffc0205174:	00002517          	auipc	a0,0x2
ffffffffc0205178:	2cc50513          	addi	a0,a0,716 # ffffffffc0207440 <default_pmm_manager+0xe68>
ffffffffc020517c:	b12fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc0205180 <schedule>:

void schedule(void)
{
ffffffffc0205180:	1141                	addi	sp,sp,-16
ffffffffc0205182:	e406                	sd	ra,8(sp)
ffffffffc0205184:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205186:	100027f3          	csrr	a5,sstatus
ffffffffc020518a:	8b89                	andi	a5,a5,2
ffffffffc020518c:	4401                	li	s0,0
ffffffffc020518e:	efbd                	bnez	a5,ffffffffc020520c <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205190:	000a5897          	auipc	a7,0xa5
ffffffffc0205194:	5388b883          	ld	a7,1336(a7) # ffffffffc02aa6c8 <current>
ffffffffc0205198:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020519c:	000a5517          	auipc	a0,0xa5
ffffffffc02051a0:	53453503          	ld	a0,1332(a0) # ffffffffc02aa6d0 <idleproc>
ffffffffc02051a4:	04a88e63          	beq	a7,a0,ffffffffc0205200 <schedule+0x80>
ffffffffc02051a8:	0c888693          	addi	a3,a7,200
ffffffffc02051ac:	000a5617          	auipc	a2,0xa5
ffffffffc02051b0:	4ac60613          	addi	a2,a2,1196 # ffffffffc02aa658 <proc_list>
        le = last;
ffffffffc02051b4:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02051b6:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02051b8:	4809                	li	a6,2
ffffffffc02051ba:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02051bc:	00c78863          	beq	a5,a2,ffffffffc02051cc <schedule+0x4c>
                if (next->state == PROC_RUNNABLE)
ffffffffc02051c0:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02051c4:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02051c8:	03070163          	beq	a4,a6,ffffffffc02051ea <schedule+0x6a>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02051cc:	fef697e3          	bne	a3,a5,ffffffffc02051ba <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051d0:	ed89                	bnez	a1,ffffffffc02051ea <schedule+0x6a>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02051d2:	451c                	lw	a5,8(a0)
ffffffffc02051d4:	2785                	addiw	a5,a5,1
ffffffffc02051d6:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02051d8:	00a88463          	beq	a7,a0,ffffffffc02051e0 <schedule+0x60>
        {
            proc_run(next);
ffffffffc02051dc:	e91fe0ef          	jal	ra,ffffffffc020406c <proc_run>
    if (flag)
ffffffffc02051e0:	e819                	bnez	s0,ffffffffc02051f6 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02051e2:	60a2                	ld	ra,8(sp)
ffffffffc02051e4:	6402                	ld	s0,0(sp)
ffffffffc02051e6:	0141                	addi	sp,sp,16
ffffffffc02051e8:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02051ea:	4198                	lw	a4,0(a1)
ffffffffc02051ec:	4789                	li	a5,2
ffffffffc02051ee:	fef712e3          	bne	a4,a5,ffffffffc02051d2 <schedule+0x52>
ffffffffc02051f2:	852e                	mv	a0,a1
ffffffffc02051f4:	bff9                	j	ffffffffc02051d2 <schedule+0x52>
}
ffffffffc02051f6:	6402                	ld	s0,0(sp)
ffffffffc02051f8:	60a2                	ld	ra,8(sp)
ffffffffc02051fa:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02051fc:	fb2fb06f          	j	ffffffffc02009ae <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205200:	000a5617          	auipc	a2,0xa5
ffffffffc0205204:	45860613          	addi	a2,a2,1112 # ffffffffc02aa658 <proc_list>
ffffffffc0205208:	86b2                	mv	a3,a2
ffffffffc020520a:	b76d                	j	ffffffffc02051b4 <schedule+0x34>
        intr_disable();
ffffffffc020520c:	fa8fb0ef          	jal	ra,ffffffffc02009b4 <intr_disable>
        return 1;
ffffffffc0205210:	4405                	li	s0,1
ffffffffc0205212:	bfbd                	j	ffffffffc0205190 <schedule+0x10>

ffffffffc0205214 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205214:	000a5797          	auipc	a5,0xa5
ffffffffc0205218:	4b47b783          	ld	a5,1204(a5) # ffffffffc02aa6c8 <current>
}
ffffffffc020521c:	43c8                	lw	a0,4(a5)
ffffffffc020521e:	8082                	ret

ffffffffc0205220 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205220:	4501                	li	a0,0
ffffffffc0205222:	8082                	ret

ffffffffc0205224 <sys_putc>:
    cputchar(c);
ffffffffc0205224:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205226:	1141                	addi	sp,sp,-16
ffffffffc0205228:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020522a:	fa1fa0ef          	jal	ra,ffffffffc02001ca <cputchar>
}
ffffffffc020522e:	60a2                	ld	ra,8(sp)
ffffffffc0205230:	4501                	li	a0,0
ffffffffc0205232:	0141                	addi	sp,sp,16
ffffffffc0205234:	8082                	ret

ffffffffc0205236 <sys_kill>:
    return do_kill(pid);
ffffffffc0205236:	4108                	lw	a0,0(a0)
ffffffffc0205238:	c31ff06f          	j	ffffffffc0204e68 <do_kill>

ffffffffc020523c <sys_yield>:
    return do_yield();
ffffffffc020523c:	bdfff06f          	j	ffffffffc0204e1a <do_yield>

ffffffffc0205240 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205240:	6d14                	ld	a3,24(a0)
ffffffffc0205242:	6910                	ld	a2,16(a0)
ffffffffc0205244:	650c                	ld	a1,8(a0)
ffffffffc0205246:	6108                	ld	a0,0(a0)
ffffffffc0205248:	ebeff06f          	j	ffffffffc0204906 <do_execve>

ffffffffc020524c <sys_wait>:
    return do_wait(pid, store);
ffffffffc020524c:	650c                	ld	a1,8(a0)
ffffffffc020524e:	4108                	lw	a0,0(a0)
ffffffffc0205250:	bdbff06f          	j	ffffffffc0204e2a <do_wait>

ffffffffc0205254 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205254:	000a5797          	auipc	a5,0xa5
ffffffffc0205258:	4747b783          	ld	a5,1140(a5) # ffffffffc02aa6c8 <current>
ffffffffc020525c:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc020525e:	4501                	li	a0,0
ffffffffc0205260:	6a0c                	ld	a1,16(a2)
ffffffffc0205262:	e6ffe06f          	j	ffffffffc02040d0 <do_fork>

ffffffffc0205266 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205266:	4108                	lw	a0,0(a0)
ffffffffc0205268:	a5eff06f          	j	ffffffffc02044c6 <do_exit>

ffffffffc020526c <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc020526c:	715d                	addi	sp,sp,-80
ffffffffc020526e:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205270:	000a5497          	auipc	s1,0xa5
ffffffffc0205274:	45848493          	addi	s1,s1,1112 # ffffffffc02aa6c8 <current>
ffffffffc0205278:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc020527a:	e0a2                	sd	s0,64(sp)
ffffffffc020527c:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc020527e:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205280:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205282:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205284:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205288:	0327ee63          	bltu	a5,s2,ffffffffc02052c4 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc020528c:	00391713          	slli	a4,s2,0x3
ffffffffc0205290:	00002797          	auipc	a5,0x2
ffffffffc0205294:	23078793          	addi	a5,a5,560 # ffffffffc02074c0 <syscalls>
ffffffffc0205298:	97ba                	add	a5,a5,a4
ffffffffc020529a:	639c                	ld	a5,0(a5)
ffffffffc020529c:	c785                	beqz	a5,ffffffffc02052c4 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc020529e:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02052a0:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02052a2:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02052a4:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02052a6:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02052a8:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02052aa:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02052ac:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc02052ae:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc02052b0:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02052b2:	0028                	addi	a0,sp,8
ffffffffc02052b4:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02052b6:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02052b8:	e828                	sd	a0,80(s0)
}
ffffffffc02052ba:	6406                	ld	s0,64(sp)
ffffffffc02052bc:	74e2                	ld	s1,56(sp)
ffffffffc02052be:	7942                	ld	s2,48(sp)
ffffffffc02052c0:	6161                	addi	sp,sp,80
ffffffffc02052c2:	8082                	ret
    print_trapframe(tf);
ffffffffc02052c4:	8522                	mv	a0,s0
ffffffffc02052c6:	8dffb0ef          	jal	ra,ffffffffc0200ba4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02052ca:	609c                	ld	a5,0(s1)
ffffffffc02052cc:	86ca                	mv	a3,s2
ffffffffc02052ce:	00002617          	auipc	a2,0x2
ffffffffc02052d2:	1aa60613          	addi	a2,a2,426 # ffffffffc0207478 <default_pmm_manager+0xea0>
ffffffffc02052d6:	43d8                	lw	a4,4(a5)
ffffffffc02052d8:	06200593          	li	a1,98
ffffffffc02052dc:	0b478793          	addi	a5,a5,180
ffffffffc02052e0:	00002517          	auipc	a0,0x2
ffffffffc02052e4:	1c850513          	addi	a0,a0,456 # ffffffffc02074a8 <default_pmm_manager+0xed0>
ffffffffc02052e8:	9a6fb0ef          	jal	ra,ffffffffc020048e <__panic>

ffffffffc02052ec <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02052ec:	9e3707b7          	lui	a5,0x9e370
ffffffffc02052f0:	2785                	addiw	a5,a5,1
ffffffffc02052f2:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02052f6:	02000793          	li	a5,32
ffffffffc02052fa:	9f8d                	subw	a5,a5,a1
}
ffffffffc02052fc:	00f5553b          	srlw	a0,a0,a5
ffffffffc0205300:	8082                	ret

ffffffffc0205302 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205302:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205306:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0205308:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020530c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020530e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205312:	f022                	sd	s0,32(sp)
ffffffffc0205314:	ec26                	sd	s1,24(sp)
ffffffffc0205316:	e84a                	sd	s2,16(sp)
ffffffffc0205318:	f406                	sd	ra,40(sp)
ffffffffc020531a:	e44e                	sd	s3,8(sp)
ffffffffc020531c:	84aa                	mv	s1,a0
ffffffffc020531e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205320:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0205324:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0205326:	03067e63          	bgeu	a2,a6,ffffffffc0205362 <printnum+0x60>
ffffffffc020532a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020532c:	00805763          	blez	s0,ffffffffc020533a <printnum+0x38>
ffffffffc0205330:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205332:	85ca                	mv	a1,s2
ffffffffc0205334:	854e                	mv	a0,s3
ffffffffc0205336:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205338:	fc65                	bnez	s0,ffffffffc0205330 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020533a:	1a02                	slli	s4,s4,0x20
ffffffffc020533c:	00002797          	auipc	a5,0x2
ffffffffc0205340:	28478793          	addi	a5,a5,644 # ffffffffc02075c0 <syscalls+0x100>
ffffffffc0205344:	020a5a13          	srli	s4,s4,0x20
ffffffffc0205348:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020534a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020534c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0205350:	70a2                	ld	ra,40(sp)
ffffffffc0205352:	69a2                	ld	s3,8(sp)
ffffffffc0205354:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205356:	85ca                	mv	a1,s2
ffffffffc0205358:	87a6                	mv	a5,s1
}
ffffffffc020535a:	6942                	ld	s2,16(sp)
ffffffffc020535c:	64e2                	ld	s1,24(sp)
ffffffffc020535e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205360:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205362:	03065633          	divu	a2,a2,a6
ffffffffc0205366:	8722                	mv	a4,s0
ffffffffc0205368:	f9bff0ef          	jal	ra,ffffffffc0205302 <printnum>
ffffffffc020536c:	b7f9                	j	ffffffffc020533a <printnum+0x38>

ffffffffc020536e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020536e:	7119                	addi	sp,sp,-128
ffffffffc0205370:	f4a6                	sd	s1,104(sp)
ffffffffc0205372:	f0ca                	sd	s2,96(sp)
ffffffffc0205374:	ecce                	sd	s3,88(sp)
ffffffffc0205376:	e8d2                	sd	s4,80(sp)
ffffffffc0205378:	e4d6                	sd	s5,72(sp)
ffffffffc020537a:	e0da                	sd	s6,64(sp)
ffffffffc020537c:	fc5e                	sd	s7,56(sp)
ffffffffc020537e:	f06a                	sd	s10,32(sp)
ffffffffc0205380:	fc86                	sd	ra,120(sp)
ffffffffc0205382:	f8a2                	sd	s0,112(sp)
ffffffffc0205384:	f862                	sd	s8,48(sp)
ffffffffc0205386:	f466                	sd	s9,40(sp)
ffffffffc0205388:	ec6e                	sd	s11,24(sp)
ffffffffc020538a:	892a                	mv	s2,a0
ffffffffc020538c:	84ae                	mv	s1,a1
ffffffffc020538e:	8d32                	mv	s10,a2
ffffffffc0205390:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205392:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0205396:	5b7d                	li	s6,-1
ffffffffc0205398:	00002a97          	auipc	s5,0x2
ffffffffc020539c:	254a8a93          	addi	s5,s5,596 # ffffffffc02075ec <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02053a0:	00002b97          	auipc	s7,0x2
ffffffffc02053a4:	468b8b93          	addi	s7,s7,1128 # ffffffffc0207808 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02053a8:	000d4503          	lbu	a0,0(s10)
ffffffffc02053ac:	001d0413          	addi	s0,s10,1
ffffffffc02053b0:	01350a63          	beq	a0,s3,ffffffffc02053c4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02053b4:	c121                	beqz	a0,ffffffffc02053f4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02053b6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02053b8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02053ba:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02053bc:	fff44503          	lbu	a0,-1(s0)
ffffffffc02053c0:	ff351ae3          	bne	a0,s3,ffffffffc02053b4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053c4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02053c8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02053cc:	4c81                	li	s9,0
ffffffffc02053ce:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02053d0:	5c7d                	li	s8,-1
ffffffffc02053d2:	5dfd                	li	s11,-1
ffffffffc02053d4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02053d8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053da:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02053de:	0ff5f593          	zext.b	a1,a1
ffffffffc02053e2:	00140d13          	addi	s10,s0,1
ffffffffc02053e6:	04b56263          	bltu	a0,a1,ffffffffc020542a <vprintfmt+0xbc>
ffffffffc02053ea:	058a                	slli	a1,a1,0x2
ffffffffc02053ec:	95d6                	add	a1,a1,s5
ffffffffc02053ee:	4194                	lw	a3,0(a1)
ffffffffc02053f0:	96d6                	add	a3,a3,s5
ffffffffc02053f2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02053f4:	70e6                	ld	ra,120(sp)
ffffffffc02053f6:	7446                	ld	s0,112(sp)
ffffffffc02053f8:	74a6                	ld	s1,104(sp)
ffffffffc02053fa:	7906                	ld	s2,96(sp)
ffffffffc02053fc:	69e6                	ld	s3,88(sp)
ffffffffc02053fe:	6a46                	ld	s4,80(sp)
ffffffffc0205400:	6aa6                	ld	s5,72(sp)
ffffffffc0205402:	6b06                	ld	s6,64(sp)
ffffffffc0205404:	7be2                	ld	s7,56(sp)
ffffffffc0205406:	7c42                	ld	s8,48(sp)
ffffffffc0205408:	7ca2                	ld	s9,40(sp)
ffffffffc020540a:	7d02                	ld	s10,32(sp)
ffffffffc020540c:	6de2                	ld	s11,24(sp)
ffffffffc020540e:	6109                	addi	sp,sp,128
ffffffffc0205410:	8082                	ret
            padc = '0';
ffffffffc0205412:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0205414:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205418:	846a                	mv	s0,s10
ffffffffc020541a:	00140d13          	addi	s10,s0,1
ffffffffc020541e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0205422:	0ff5f593          	zext.b	a1,a1
ffffffffc0205426:	fcb572e3          	bgeu	a0,a1,ffffffffc02053ea <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020542a:	85a6                	mv	a1,s1
ffffffffc020542c:	02500513          	li	a0,37
ffffffffc0205430:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205432:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205436:	8d22                	mv	s10,s0
ffffffffc0205438:	f73788e3          	beq	a5,s3,ffffffffc02053a8 <vprintfmt+0x3a>
ffffffffc020543c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0205440:	1d7d                	addi	s10,s10,-1
ffffffffc0205442:	ff379de3          	bne	a5,s3,ffffffffc020543c <vprintfmt+0xce>
ffffffffc0205446:	b78d                	j	ffffffffc02053a8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0205448:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020544c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205450:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0205452:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0205456:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020545a:	02d86463          	bltu	a6,a3,ffffffffc0205482 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020545e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205462:	002c169b          	slliw	a3,s8,0x2
ffffffffc0205466:	0186873b          	addw	a4,a3,s8
ffffffffc020546a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020546e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0205470:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205474:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205476:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020547a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020547e:	fed870e3          	bgeu	a6,a3,ffffffffc020545e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0205482:	f40ddce3          	bgez	s11,ffffffffc02053da <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0205486:	8de2                	mv	s11,s8
ffffffffc0205488:	5c7d                	li	s8,-1
ffffffffc020548a:	bf81                	j	ffffffffc02053da <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020548c:	fffdc693          	not	a3,s11
ffffffffc0205490:	96fd                	srai	a3,a3,0x3f
ffffffffc0205492:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205496:	00144603          	lbu	a2,1(s0)
ffffffffc020549a:	2d81                	sext.w	s11,s11
ffffffffc020549c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020549e:	bf35                	j	ffffffffc02053da <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02054a0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054a4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02054a8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054aa:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02054ac:	bfd9                	j	ffffffffc0205482 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02054ae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054b0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02054b4:	01174463          	blt	a4,a7,ffffffffc02054bc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02054b8:	1a088e63          	beqz	a7,ffffffffc0205674 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02054bc:	000a3603          	ld	a2,0(s4)
ffffffffc02054c0:	46c1                	li	a3,16
ffffffffc02054c2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02054c4:	2781                	sext.w	a5,a5
ffffffffc02054c6:	876e                	mv	a4,s11
ffffffffc02054c8:	85a6                	mv	a1,s1
ffffffffc02054ca:	854a                	mv	a0,s2
ffffffffc02054cc:	e37ff0ef          	jal	ra,ffffffffc0205302 <printnum>
            break;
ffffffffc02054d0:	bde1                	j	ffffffffc02053a8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02054d2:	000a2503          	lw	a0,0(s4)
ffffffffc02054d6:	85a6                	mv	a1,s1
ffffffffc02054d8:	0a21                	addi	s4,s4,8
ffffffffc02054da:	9902                	jalr	s2
            break;
ffffffffc02054dc:	b5f1                	j	ffffffffc02053a8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02054de:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054e0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02054e4:	01174463          	blt	a4,a7,ffffffffc02054ec <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02054e8:	18088163          	beqz	a7,ffffffffc020566a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02054ec:	000a3603          	ld	a2,0(s4)
ffffffffc02054f0:	46a9                	li	a3,10
ffffffffc02054f2:	8a2e                	mv	s4,a1
ffffffffc02054f4:	bfc1                	j	ffffffffc02054c4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054f6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02054fa:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02054fe:	bdf1                	j	ffffffffc02053da <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0205500:	85a6                	mv	a1,s1
ffffffffc0205502:	02500513          	li	a0,37
ffffffffc0205506:	9902                	jalr	s2
            break;
ffffffffc0205508:	b545                	j	ffffffffc02053a8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020550a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020550e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205510:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0205512:	b5e1                	j	ffffffffc02053da <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0205514:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205516:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020551a:	01174463          	blt	a4,a7,ffffffffc0205522 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020551e:	14088163          	beqz	a7,ffffffffc0205660 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0205522:	000a3603          	ld	a2,0(s4)
ffffffffc0205526:	46a1                	li	a3,8
ffffffffc0205528:	8a2e                	mv	s4,a1
ffffffffc020552a:	bf69                	j	ffffffffc02054c4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020552c:	03000513          	li	a0,48
ffffffffc0205530:	85a6                	mv	a1,s1
ffffffffc0205532:	e03e                	sd	a5,0(sp)
ffffffffc0205534:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0205536:	85a6                	mv	a1,s1
ffffffffc0205538:	07800513          	li	a0,120
ffffffffc020553c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020553e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205540:	6782                	ld	a5,0(sp)
ffffffffc0205542:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205544:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0205548:	bfb5                	j	ffffffffc02054c4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020554a:	000a3403          	ld	s0,0(s4)
ffffffffc020554e:	008a0713          	addi	a4,s4,8
ffffffffc0205552:	e03a                	sd	a4,0(sp)
ffffffffc0205554:	14040263          	beqz	s0,ffffffffc0205698 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0205558:	0fb05763          	blez	s11,ffffffffc0205646 <vprintfmt+0x2d8>
ffffffffc020555c:	02d00693          	li	a3,45
ffffffffc0205560:	0cd79163          	bne	a5,a3,ffffffffc0205622 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205564:	00044783          	lbu	a5,0(s0)
ffffffffc0205568:	0007851b          	sext.w	a0,a5
ffffffffc020556c:	cf85                	beqz	a5,ffffffffc02055a4 <vprintfmt+0x236>
ffffffffc020556e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205572:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205576:	000c4563          	bltz	s8,ffffffffc0205580 <vprintfmt+0x212>
ffffffffc020557a:	3c7d                	addiw	s8,s8,-1
ffffffffc020557c:	036c0263          	beq	s8,s6,ffffffffc02055a0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0205580:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205582:	0e0c8e63          	beqz	s9,ffffffffc020567e <vprintfmt+0x310>
ffffffffc0205586:	3781                	addiw	a5,a5,-32
ffffffffc0205588:	0ef47b63          	bgeu	s0,a5,ffffffffc020567e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020558c:	03f00513          	li	a0,63
ffffffffc0205590:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205592:	000a4783          	lbu	a5,0(s4)
ffffffffc0205596:	3dfd                	addiw	s11,s11,-1
ffffffffc0205598:	0a05                	addi	s4,s4,1
ffffffffc020559a:	0007851b          	sext.w	a0,a5
ffffffffc020559e:	ffe1                	bnez	a5,ffffffffc0205576 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02055a0:	01b05963          	blez	s11,ffffffffc02055b2 <vprintfmt+0x244>
ffffffffc02055a4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02055a6:	85a6                	mv	a1,s1
ffffffffc02055a8:	02000513          	li	a0,32
ffffffffc02055ac:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02055ae:	fe0d9be3          	bnez	s11,ffffffffc02055a4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055b2:	6a02                	ld	s4,0(sp)
ffffffffc02055b4:	bbd5                	j	ffffffffc02053a8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02055b6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055b8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02055bc:	01174463          	blt	a4,a7,ffffffffc02055c4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02055c0:	08088d63          	beqz	a7,ffffffffc020565a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02055c4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02055c8:	0a044d63          	bltz	s0,ffffffffc0205682 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02055cc:	8622                	mv	a2,s0
ffffffffc02055ce:	8a66                	mv	s4,s9
ffffffffc02055d0:	46a9                	li	a3,10
ffffffffc02055d2:	bdcd                	j	ffffffffc02054c4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02055d4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02055d8:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02055da:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02055dc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02055e0:	8fb5                	xor	a5,a5,a3
ffffffffc02055e2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02055e6:	02d74163          	blt	a4,a3,ffffffffc0205608 <vprintfmt+0x29a>
ffffffffc02055ea:	00369793          	slli	a5,a3,0x3
ffffffffc02055ee:	97de                	add	a5,a5,s7
ffffffffc02055f0:	639c                	ld	a5,0(a5)
ffffffffc02055f2:	cb99                	beqz	a5,ffffffffc0205608 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02055f4:	86be                	mv	a3,a5
ffffffffc02055f6:	00000617          	auipc	a2,0x0
ffffffffc02055fa:	1f260613          	addi	a2,a2,498 # ffffffffc02057e8 <etext+0x2c>
ffffffffc02055fe:	85a6                	mv	a1,s1
ffffffffc0205600:	854a                	mv	a0,s2
ffffffffc0205602:	0ce000ef          	jal	ra,ffffffffc02056d0 <printfmt>
ffffffffc0205606:	b34d                	j	ffffffffc02053a8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205608:	00002617          	auipc	a2,0x2
ffffffffc020560c:	fd860613          	addi	a2,a2,-40 # ffffffffc02075e0 <syscalls+0x120>
ffffffffc0205610:	85a6                	mv	a1,s1
ffffffffc0205612:	854a                	mv	a0,s2
ffffffffc0205614:	0bc000ef          	jal	ra,ffffffffc02056d0 <printfmt>
ffffffffc0205618:	bb41                	j	ffffffffc02053a8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020561a:	00002417          	auipc	s0,0x2
ffffffffc020561e:	fbe40413          	addi	s0,s0,-66 # ffffffffc02075d8 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205622:	85e2                	mv	a1,s8
ffffffffc0205624:	8522                	mv	a0,s0
ffffffffc0205626:	e43e                	sd	a5,8(sp)
ffffffffc0205628:	0e2000ef          	jal	ra,ffffffffc020570a <strnlen>
ffffffffc020562c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0205630:	01b05b63          	blez	s11,ffffffffc0205646 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0205634:	67a2                	ld	a5,8(sp)
ffffffffc0205636:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020563a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020563c:	85a6                	mv	a1,s1
ffffffffc020563e:	8552                	mv	a0,s4
ffffffffc0205640:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205642:	fe0d9ce3          	bnez	s11,ffffffffc020563a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205646:	00044783          	lbu	a5,0(s0)
ffffffffc020564a:	00140a13          	addi	s4,s0,1
ffffffffc020564e:	0007851b          	sext.w	a0,a5
ffffffffc0205652:	d3a5                	beqz	a5,ffffffffc02055b2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205654:	05e00413          	li	s0,94
ffffffffc0205658:	bf39                	j	ffffffffc0205576 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020565a:	000a2403          	lw	s0,0(s4)
ffffffffc020565e:	b7ad                	j	ffffffffc02055c8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0205660:	000a6603          	lwu	a2,0(s4)
ffffffffc0205664:	46a1                	li	a3,8
ffffffffc0205666:	8a2e                	mv	s4,a1
ffffffffc0205668:	bdb1                	j	ffffffffc02054c4 <vprintfmt+0x156>
ffffffffc020566a:	000a6603          	lwu	a2,0(s4)
ffffffffc020566e:	46a9                	li	a3,10
ffffffffc0205670:	8a2e                	mv	s4,a1
ffffffffc0205672:	bd89                	j	ffffffffc02054c4 <vprintfmt+0x156>
ffffffffc0205674:	000a6603          	lwu	a2,0(s4)
ffffffffc0205678:	46c1                	li	a3,16
ffffffffc020567a:	8a2e                	mv	s4,a1
ffffffffc020567c:	b5a1                	j	ffffffffc02054c4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020567e:	9902                	jalr	s2
ffffffffc0205680:	bf09                	j	ffffffffc0205592 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0205682:	85a6                	mv	a1,s1
ffffffffc0205684:	02d00513          	li	a0,45
ffffffffc0205688:	e03e                	sd	a5,0(sp)
ffffffffc020568a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020568c:	6782                	ld	a5,0(sp)
ffffffffc020568e:	8a66                	mv	s4,s9
ffffffffc0205690:	40800633          	neg	a2,s0
ffffffffc0205694:	46a9                	li	a3,10
ffffffffc0205696:	b53d                	j	ffffffffc02054c4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0205698:	03b05163          	blez	s11,ffffffffc02056ba <vprintfmt+0x34c>
ffffffffc020569c:	02d00693          	li	a3,45
ffffffffc02056a0:	f6d79de3          	bne	a5,a3,ffffffffc020561a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02056a4:	00002417          	auipc	s0,0x2
ffffffffc02056a8:	f3440413          	addi	s0,s0,-204 # ffffffffc02075d8 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056ac:	02800793          	li	a5,40
ffffffffc02056b0:	02800513          	li	a0,40
ffffffffc02056b4:	00140a13          	addi	s4,s0,1
ffffffffc02056b8:	bd6d                	j	ffffffffc0205572 <vprintfmt+0x204>
ffffffffc02056ba:	00002a17          	auipc	s4,0x2
ffffffffc02056be:	f1fa0a13          	addi	s4,s4,-225 # ffffffffc02075d9 <syscalls+0x119>
ffffffffc02056c2:	02800513          	li	a0,40
ffffffffc02056c6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02056ca:	05e00413          	li	s0,94
ffffffffc02056ce:	b565                	j	ffffffffc0205576 <vprintfmt+0x208>

ffffffffc02056d0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02056d0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02056d2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02056d6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02056d8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02056da:	ec06                	sd	ra,24(sp)
ffffffffc02056dc:	f83a                	sd	a4,48(sp)
ffffffffc02056de:	fc3e                	sd	a5,56(sp)
ffffffffc02056e0:	e0c2                	sd	a6,64(sp)
ffffffffc02056e2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02056e4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02056e6:	c89ff0ef          	jal	ra,ffffffffc020536e <vprintfmt>
}
ffffffffc02056ea:	60e2                	ld	ra,24(sp)
ffffffffc02056ec:	6161                	addi	sp,sp,80
ffffffffc02056ee:	8082                	ret

ffffffffc02056f0 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02056f0:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02056f4:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02056f6:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02056f8:	cb81                	beqz	a5,ffffffffc0205708 <strlen+0x18>
        cnt ++;
ffffffffc02056fa:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02056fc:	00a707b3          	add	a5,a4,a0
ffffffffc0205700:	0007c783          	lbu	a5,0(a5)
ffffffffc0205704:	fbfd                	bnez	a5,ffffffffc02056fa <strlen+0xa>
ffffffffc0205706:	8082                	ret
    }
    return cnt;
}
ffffffffc0205708:	8082                	ret

ffffffffc020570a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020570a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020570c:	e589                	bnez	a1,ffffffffc0205716 <strnlen+0xc>
ffffffffc020570e:	a811                	j	ffffffffc0205722 <strnlen+0x18>
        cnt ++;
ffffffffc0205710:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205712:	00f58863          	beq	a1,a5,ffffffffc0205722 <strnlen+0x18>
ffffffffc0205716:	00f50733          	add	a4,a0,a5
ffffffffc020571a:	00074703          	lbu	a4,0(a4)
ffffffffc020571e:	fb6d                	bnez	a4,ffffffffc0205710 <strnlen+0x6>
ffffffffc0205720:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205722:	852e                	mv	a0,a1
ffffffffc0205724:	8082                	ret

ffffffffc0205726 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205726:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205728:	0005c703          	lbu	a4,0(a1)
ffffffffc020572c:	0785                	addi	a5,a5,1
ffffffffc020572e:	0585                	addi	a1,a1,1
ffffffffc0205730:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205734:	fb75                	bnez	a4,ffffffffc0205728 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205736:	8082                	ret

ffffffffc0205738 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205738:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020573c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205740:	cb89                	beqz	a5,ffffffffc0205752 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0205742:	0505                	addi	a0,a0,1
ffffffffc0205744:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205746:	fee789e3          	beq	a5,a4,ffffffffc0205738 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020574a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020574e:	9d19                	subw	a0,a0,a4
ffffffffc0205750:	8082                	ret
ffffffffc0205752:	4501                	li	a0,0
ffffffffc0205754:	bfed                	j	ffffffffc020574e <strcmp+0x16>

ffffffffc0205756 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205756:	c20d                	beqz	a2,ffffffffc0205778 <strncmp+0x22>
ffffffffc0205758:	962e                	add	a2,a2,a1
ffffffffc020575a:	a031                	j	ffffffffc0205766 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020575c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020575e:	00e79a63          	bne	a5,a4,ffffffffc0205772 <strncmp+0x1c>
ffffffffc0205762:	00b60b63          	beq	a2,a1,ffffffffc0205778 <strncmp+0x22>
ffffffffc0205766:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020576a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020576c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0205770:	f7f5                	bnez	a5,ffffffffc020575c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205772:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0205776:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205778:	4501                	li	a0,0
ffffffffc020577a:	8082                	ret

ffffffffc020577c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020577c:	00054783          	lbu	a5,0(a0)
ffffffffc0205780:	c799                	beqz	a5,ffffffffc020578e <strchr+0x12>
        if (*s == c) {
ffffffffc0205782:	00f58763          	beq	a1,a5,ffffffffc0205790 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0205786:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020578a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020578c:	fbfd                	bnez	a5,ffffffffc0205782 <strchr+0x6>
    }
    return NULL;
ffffffffc020578e:	4501                	li	a0,0
}
ffffffffc0205790:	8082                	ret

ffffffffc0205792 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205792:	ca01                	beqz	a2,ffffffffc02057a2 <memset+0x10>
ffffffffc0205794:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205796:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205798:	0785                	addi	a5,a5,1
ffffffffc020579a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020579e:	fec79de3          	bne	a5,a2,ffffffffc0205798 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02057a2:	8082                	ret

ffffffffc02057a4 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02057a4:	ca19                	beqz	a2,ffffffffc02057ba <memcpy+0x16>
ffffffffc02057a6:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02057a8:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02057aa:	0005c703          	lbu	a4,0(a1)
ffffffffc02057ae:	0585                	addi	a1,a1,1
ffffffffc02057b0:	0785                	addi	a5,a5,1
ffffffffc02057b2:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02057b6:	fec59ae3          	bne	a1,a2,ffffffffc02057aa <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02057ba:	8082                	ret
