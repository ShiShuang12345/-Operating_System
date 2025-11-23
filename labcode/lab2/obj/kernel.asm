
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	abc50513          	addi	a0,a0,-1348 # ffffffffc0201b08 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	ac650513          	addi	a0,a0,-1338 # ffffffffc0201b28 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	a9458593          	addi	a1,a1,-1388 # ffffffffc0201b02 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	ad250513          	addi	a0,a0,-1326 # ffffffffc0201b48 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	ade50513          	addi	a0,a0,-1314 # ffffffffc0201b68 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	ff258593          	addi	a1,a1,-14 # ffffffffc0206088 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	aea50513          	addi	a0,a0,-1302 # ffffffffc0201b88 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	3dd58593          	addi	a1,a1,989 # ffffffffc0206487 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	adc50513          	addi	a0,a0,-1316 # ffffffffc0201ba8 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <free_area>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	fa860613          	addi	a2,a2,-88 # ffffffffc0206088 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	201010ef          	jal	ra,ffffffffc0201af0 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	adc50513          	addi	a0,a0,-1316 # ffffffffc0201bd8 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	38a010ef          	jal	ra,ffffffffc0201496 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	59a010ef          	jal	ra,ffffffffc02016da <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	564010ef          	jal	ra,ffffffffc02016da <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	e6e30313          	addi	t1,t1,-402 # ffffffffc0206030 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	a0650513          	addi	a0,a0,-1530 # ffffffffc0201bf8 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	9c850513          	addi	a0,a0,-1592 # ffffffffc0201bd0 <etext+0xce>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	0410106f          	j	ffffffffc0201a5c <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	9f650513          	addi	a0,a0,-1546 # ffffffffc0201c18 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	9d850513          	addi	a0,a0,-1576 # ffffffffc0201c28 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201c38 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	9da50513          	addi	a0,a0,-1574 # ffffffffc0201c50 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9e65>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	97090913          	addi	s2,s2,-1680 # ffffffffc0201ca0 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	95a48493          	addi	s1,s1,-1702 # ffffffffc0201c98 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	98650513          	addi	a0,a0,-1658 # ffffffffc0201d18 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	9b250513          	addi	a0,a0,-1614 # ffffffffc0201d50 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	89250513          	addi	a0,a0,-1902 # ffffffffc0201c70 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	68a010ef          	jal	ra,ffffffffc0201a76 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	6d0010ef          	jal	ra,ffffffffc0201aca <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	61c010ef          	jal	ra,ffffffffc0201aac <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	80450513          	addi	a0,a0,-2044 # ffffffffc0201ca8 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	75650513          	addi	a0,a0,1878 # ffffffffc0201cc8 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	75c50513          	addi	a0,a0,1884 # ffffffffc0201ce0 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	76a50513          	addi	a0,a0,1898 # ffffffffc0201d00 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	7ae50513          	addi	a0,a0,1966 # ffffffffc0201d50 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	a887b723          	sd	s0,-1394(a5) # ffffffffc0206038 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	a967b723          	sd	s6,-1394(a5) # ffffffffc0206040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	a7c53503          	ld	a0,-1412(a0) # ffffffffc0206038 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	a7a53503          	ld	a0,-1414(a0) # ffffffffc0206040 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0206018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
}

static void
buddy_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
    buddy_manager = NULL;
ffffffffc02005e0:	00006797          	auipc	a5,0x6
ffffffffc02005e4:	a607b823          	sd	zero,-1424(a5) # ffffffffc0206050 <buddy_manager>
    buddy_base = NULL;
ffffffffc02005e8:	00006797          	auipc	a5,0x6
ffffffffc02005ec:	a607b023          	sd	zero,-1440(a5) # ffffffffc0206048 <buddy_base>
}
ffffffffc02005f0:	8082                	ret

ffffffffc02005f2 <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005f2:	00006517          	auipc	a0,0x6
ffffffffc02005f6:	a3656503          	lwu	a0,-1482(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <buddy_alloc_pages>:
buddy_alloc_pages(size_t n) {
ffffffffc02005fc:	715d                	addi	sp,sp,-80
ffffffffc02005fe:	e486                	sd	ra,72(sp)
ffffffffc0200600:	e0a2                	sd	s0,64(sp)
ffffffffc0200602:	fc26                	sd	s1,56(sp)
ffffffffc0200604:	f84a                	sd	s2,48(sp)
ffffffffc0200606:	f44e                	sd	s3,40(sp)
ffffffffc0200608:	f052                	sd	s4,32(sp)
ffffffffc020060a:	ec56                	sd	s5,24(sp)
ffffffffc020060c:	e85a                	sd	s6,16(sp)
ffffffffc020060e:	e45e                	sd	s7,8(sp)
    assert(n > 0);
ffffffffc0200610:	2a050863          	beqz	a0,ffffffffc02008c0 <buddy_alloc_pages+0x2c4>
    cprintf("buddy_alloc_pages: request %lu pages, nr_free = %lu\n", n, nr_free);
ffffffffc0200614:	00006a17          	auipc	s4,0x6
ffffffffc0200618:	a04a0a13          	addi	s4,s4,-1532 # ffffffffc0206018 <free_area>
ffffffffc020061c:	010a2603          	lw	a2,16(s4)
ffffffffc0200620:	85aa                	mv	a1,a0
ffffffffc0200622:	842a                	mv	s0,a0
ffffffffc0200624:	00001517          	auipc	a0,0x1
ffffffffc0200628:	77c50513          	addi	a0,a0,1916 # ffffffffc0201da0 <etext+0x29e>
ffffffffc020062c:	b21ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (n > nr_free || buddy_manager == NULL) {
ffffffffc0200630:	010a2583          	lw	a1,16(s4)
ffffffffc0200634:	02059793          	slli	a5,a1,0x20
ffffffffc0200638:	9381                	srli	a5,a5,0x20
ffffffffc020063a:	2287e463          	bltu	a5,s0,ffffffffc0200862 <buddy_alloc_pages+0x266>
ffffffffc020063e:	00006497          	auipc	s1,0x6
ffffffffc0200642:	a1248493          	addi	s1,s1,-1518 # ffffffffc0206050 <buddy_manager>
ffffffffc0200646:	6090                	ld	a2,0(s1)
ffffffffc0200648:	22060163          	beqz	a2,ffffffffc020086a <buddy_alloc_pages+0x26e>
    if (IS_POWER_OF_2(n)) {
ffffffffc020064c:	fff40793          	addi	a5,s0,-1
ffffffffc0200650:	8fe1                	and	a5,a5,s0
        alloc_size = n;
ffffffffc0200652:	0004091b          	sext.w	s2,s0
    if (IS_POWER_OF_2(n)) {
ffffffffc0200656:	e3a9                	bnez	a5,ffffffffc0200698 <buddy_alloc_pages+0x9c>
    cprintf("buddy_alloc_pages: adjusted to %u pages\n", alloc_size);
ffffffffc0200658:	85ca                	mv	a1,s2
ffffffffc020065a:	00001517          	auipc	a0,0x1
ffffffffc020065e:	7c650513          	addi	a0,a0,1990 # ffffffffc0201e20 <etext+0x31e>
ffffffffc0200662:	aebff0ef          	jal	ra,ffffffffc020014c <cprintf>
    int offset = buddy2_alloc(buddy_manager, alloc_size);
ffffffffc0200666:	0004bb83          	ld	s7,0(s1)
ffffffffc020066a:	0009041b          	sext.w	s0,s2
    if (self == NULL) {
ffffffffc020066e:	240b8263          	beqz	s7,ffffffffc02008b2 <buddy_alloc_pages+0x2b6>
    if (size <= 0) {
ffffffffc0200672:	02805c63          	blez	s0,ffffffffc02006aa <buddy_alloc_pages+0xae>
    } else if (!IS_POWER_OF_2(size)) {
ffffffffc0200676:	fff4079b          	addiw	a5,s0,-1
ffffffffc020067a:	8fe1                	and	a5,a5,s0
ffffffffc020067c:	2781                	sext.w	a5,a5
ffffffffc020067e:	1c078f63          	beqz	a5,ffffffffc020085c <buddy_alloc_pages+0x260>
    while (power < size) {
ffffffffc0200682:	4785                	li	a5,1
    unsigned power = 1;
ffffffffc0200684:	4985                	li	s3,1
    while (power < size) {
ffffffffc0200686:	02f90363          	beq	s2,a5,ffffffffc02006ac <buddy_alloc_pages+0xb0>
        power *= 2;
ffffffffc020068a:	0019999b          	slliw	s3,s3,0x1
    while (power < size) {
ffffffffc020068e:	ff29eee3          	bltu	s3,s2,ffffffffc020068a <buddy_alloc_pages+0x8e>
        size = fixsize(size);
ffffffffc0200692:	0009841b          	sext.w	s0,s3
ffffffffc0200696:	a821                	j	ffffffffc02006ae <buddy_alloc_pages+0xb2>
    while (power < size) {
ffffffffc0200698:	4785                	li	a5,1
ffffffffc020069a:	1af40463          	beq	s0,a5,ffffffffc0200842 <buddy_alloc_pages+0x246>
        power *= 2;
ffffffffc020069e:	0017979b          	slliw	a5,a5,0x1
    while (power < size) {
ffffffffc02006a2:	ff27eee3          	bltu	a5,s2,ffffffffc020069e <buddy_alloc_pages+0xa2>
ffffffffc02006a6:	893e                	mv	s2,a5
ffffffffc02006a8:	bf45                	j	ffffffffc0200658 <buddy_alloc_pages+0x5c>
ffffffffc02006aa:	4985                	li	s3,1
        size = 1;
ffffffffc02006ac:	4405                	li	s0,1
    cprintf("buddy2_alloc: requesting %d pages\n", size);
ffffffffc02006ae:	85a2                	mv	a1,s0
ffffffffc02006b0:	00001517          	auipc	a0,0x1
ffffffffc02006b4:	7c050513          	addi	a0,a0,1984 # ffffffffc0201e70 <etext+0x36e>
ffffffffc02006b8:	a95ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (self->longest[index] < size) {
ffffffffc02006bc:	004ba583          	lw	a1,4(s7)
ffffffffc02006c0:	1d35ea63          	bltu	a1,s3,ffffffffc0200894 <buddy_alloc_pages+0x298>
    for (node_size = self->size; node_size != size; node_size /= 2) {
ffffffffc02006c4:	000ba403          	lw	s0,0(s7)
ffffffffc02006c8:	1b340963          	beq	s0,s3,ffffffffc020087a <buddy_alloc_pages+0x27e>
    unsigned index = 0;
ffffffffc02006cc:	4481                	li	s1,0
            cprintf("buddy2_alloc: go right to index %u, size %u\n", index, node_size/2);
ffffffffc02006ce:	00002b17          	auipc	s6,0x2
ffffffffc02006d2:	83ab0b13          	addi	s6,s6,-1990 # ffffffffc0201f08 <etext+0x406>
            cprintf("buddy2_alloc: go left to index %u, size %u\n", index, node_size/2);
ffffffffc02006d6:	00002a97          	auipc	s5,0x2
ffffffffc02006da:	802a8a93          	addi	s5,s5,-2046 # ffffffffc0201ed8 <etext+0x3d6>
        if (self->longest[LEFT_LEAF(index)] >= size) {
ffffffffc02006de:	0014971b          	slliw	a4,s1,0x1
ffffffffc02006e2:	0017049b          	addiw	s1,a4,1
ffffffffc02006e6:	02049693          	slli	a3,s1,0x20
ffffffffc02006ea:	01e6d793          	srli	a5,a3,0x1e
ffffffffc02006ee:	97de                	add	a5,a5,s7
ffffffffc02006f0:	43dc                	lw	a5,4(a5)
            cprintf("buddy2_alloc: go left to index %u, size %u\n", index, node_size/2);
ffffffffc02006f2:	0014541b          	srliw	s0,s0,0x1
        if (self->longest[LEFT_LEAF(index)] >= size) {
ffffffffc02006f6:	1337ec63          	bltu	a5,s3,ffffffffc020082e <buddy_alloc_pages+0x232>
            cprintf("buddy2_alloc: go left to index %u, size %u\n", index, node_size/2);
ffffffffc02006fa:	8622                	mv	a2,s0
ffffffffc02006fc:	85a6                	mv	a1,s1
ffffffffc02006fe:	8556                	mv	a0,s5
ffffffffc0200700:	a4dff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (node_size = self->size; node_size != size; node_size /= 2) {
ffffffffc0200704:	fc899de3          	bne	s3,s0,ffffffffc02006de <buddy_alloc_pages+0xe2>
    offset = (index + 1) * node_size - self->size;
ffffffffc0200708:	0014841b          	addiw	s0,s1,1
ffffffffc020070c:	03340abb          	mulw	s5,s0,s3
ffffffffc0200710:	000ba703          	lw	a4,0(s7)
    self->longest[index] = 0;
ffffffffc0200714:	02049693          	slli	a3,s1,0x20
ffffffffc0200718:	01e6d793          	srli	a5,a3,0x1e
ffffffffc020071c:	97de                	add	a5,a5,s7
ffffffffc020071e:	0007a223          	sw	zero,4(a5)
    cprintf("buddy2_alloc: allocated at offset %u, index %u, node_size %u\n", 
ffffffffc0200722:	86ce                	mv	a3,s3
ffffffffc0200724:	8626                	mv	a2,s1
ffffffffc0200726:	00002517          	auipc	a0,0x2
ffffffffc020072a:	81250513          	addi	a0,a0,-2030 # ffffffffc0201f38 <etext+0x436>
    offset = (index + 1) * node_size - self->size;
ffffffffc020072e:	40ea8abb          	subw	s5,s5,a4
    cprintf("buddy2_alloc: allocated at offset %u, index %u, node_size %u\n", 
ffffffffc0200732:	85d6                	mv	a1,s5
ffffffffc0200734:	a19ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    return offset;
ffffffffc0200738:	8b56                	mv	s6,s5
    while (index) {
ffffffffc020073a:	ccb9                	beqz	s1,ffffffffc0200798 <buddy_alloc_pages+0x19c>
        cprintf("buddy2_alloc: update parent[%u] = %u\n", index, self->longest[index]);
ffffffffc020073c:	00002997          	auipc	s3,0x2
ffffffffc0200740:	83c98993          	addi	s3,s3,-1988 # ffffffffc0201f78 <etext+0x476>
ffffffffc0200744:	a019                	j	ffffffffc020074a <buddy_alloc_pages+0x14e>
ffffffffc0200746:	0014841b          	addiw	s0,s1,1
        index = PARENT(index);
ffffffffc020074a:	0014579b          	srliw	a5,s0,0x1
ffffffffc020074e:	37fd                	addiw	a5,a5,-1
            MAX(self->longest[LEFT_LEAF(index)], self->longest[RIGHT_LEAF(index)]);
ffffffffc0200750:	0017971b          	slliw	a4,a5,0x1
ffffffffc0200754:	9879                	andi	s0,s0,-2
ffffffffc0200756:	2705                	addiw	a4,a4,1
ffffffffc0200758:	1402                	slli	s0,s0,0x20
ffffffffc020075a:	02071693          	slli	a3,a4,0x20
ffffffffc020075e:	9001                	srli	s0,s0,0x20
ffffffffc0200760:	01e6d713          	srli	a4,a3,0x1e
ffffffffc0200764:	040a                	slli	s0,s0,0x2
ffffffffc0200766:	975e                	add	a4,a4,s7
ffffffffc0200768:	945e                	add	s0,s0,s7
ffffffffc020076a:	404c                	lw	a1,4(s0)
ffffffffc020076c:	4358                	lw	a4,4(a4)
        index = PARENT(index);
ffffffffc020076e:	0007849b          	sext.w	s1,a5
            MAX(self->longest[LEFT_LEAF(index)], self->longest[RIGHT_LEAF(index)]);
ffffffffc0200772:	0005869b          	sext.w	a3,a1
ffffffffc0200776:	0007061b          	sext.w	a2,a4
ffffffffc020077a:	00d67463          	bgeu	a2,a3,ffffffffc0200782 <buddy_alloc_pages+0x186>
ffffffffc020077e:	872e                	mv	a4,a1
ffffffffc0200780:	8636                	mv	a2,a3
        self->longest[index] = 
ffffffffc0200782:	02079693          	slli	a3,a5,0x20
ffffffffc0200786:	01e6d793          	srli	a5,a3,0x1e
ffffffffc020078a:	97de                	add	a5,a5,s7
ffffffffc020078c:	c3d8                	sw	a4,4(a5)
        cprintf("buddy2_alloc: update parent[%u] = %u\n", index, self->longest[index]);
ffffffffc020078e:	85a6                	mv	a1,s1
ffffffffc0200790:	854e                	mv	a0,s3
ffffffffc0200792:	9bbff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (index) {
ffffffffc0200796:	f8c5                	bnez	s1,ffffffffc0200746 <buddy_alloc_pages+0x14a>
    if (offset == -1) {
ffffffffc0200798:	57fd                	li	a5,-1
ffffffffc020079a:	10fa8463          	beq	s5,a5,ffffffffc02008a2 <buddy_alloc_pages+0x2a6>
    struct Page* page = buddy_base + offset;
ffffffffc020079e:	002b1613          	slli	a2,s6,0x2
ffffffffc02007a2:	965a                	add	a2,a2,s6
ffffffffc02007a4:	060e                	slli	a2,a2,0x3
ffffffffc02007a6:	00006417          	auipc	s0,0x6
ffffffffc02007aa:	8a243403          	ld	s0,-1886(s0) # ffffffffc0206048 <buddy_base>
ffffffffc02007ae:	9432                	add	s0,s0,a2
    cprintf("buddy_alloc_pages: allocated at offset %d, page = %p\n", offset, page);
ffffffffc02007b0:	8622                	mv	a2,s0
ffffffffc02007b2:	85da                	mv	a1,s6
ffffffffc02007b4:	00002517          	auipc	a0,0x2
ffffffffc02007b8:	81450513          	addi	a0,a0,-2028 # ffffffffc0201fc8 <etext+0x4c6>
ffffffffc02007bc:	991ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (unsigned i = 0; i < alloc_size; i++) {
ffffffffc02007c0:	00840713          	addi	a4,s0,8
ffffffffc02007c4:	4681                	li	a3,0
ffffffffc02007c6:	a829                	j	ffffffffc02007e0 <buddy_alloc_pages+0x1e4>
            ClearPageProperty(p);
ffffffffc02007c8:	9bf5                	andi	a5,a5,-3
ffffffffc02007ca:	e31c                	sd	a5,0(a4)
        SetPageReserved(p);  // 标记为已分配
ffffffffc02007cc:	0017e793          	ori	a5,a5,1
            p->property = 0;
ffffffffc02007d0:	00072423          	sw	zero,8(a4)
        SetPageReserved(p);  // 标记为已分配
ffffffffc02007d4:	e31c                	sd	a5,0(a4)
    for (unsigned i = 0; i < alloc_size; i++) {
ffffffffc02007d6:	2685                	addiw	a3,a3,1
ffffffffc02007d8:	02870713          	addi	a4,a4,40
ffffffffc02007dc:	03268163          	beq	a3,s2,ffffffffc02007fe <buddy_alloc_pages+0x202>
            SetPageProperty(p);
ffffffffc02007e0:	631c                	ld	a5,0(a4)
        if (i == 0) {
ffffffffc02007e2:	f2fd                	bnez	a3,ffffffffc02007c8 <buddy_alloc_pages+0x1cc>
            SetPageProperty(p);
ffffffffc02007e4:	0027e793          	ori	a5,a5,2
ffffffffc02007e8:	e31c                	sd	a5,0(a4)
        SetPageReserved(p);  // 标记为已分配
ffffffffc02007ea:	0017e793          	ori	a5,a5,1
            p->property = alloc_size;
ffffffffc02007ee:	01272423          	sw	s2,8(a4)
        SetPageReserved(p);  // 标记为已分配
ffffffffc02007f2:	e31c                	sd	a5,0(a4)
    for (unsigned i = 0; i < alloc_size; i++) {
ffffffffc02007f4:	2685                	addiw	a3,a3,1
ffffffffc02007f6:	02870713          	addi	a4,a4,40
ffffffffc02007fa:	ff2693e3          	bne	a3,s2,ffffffffc02007e0 <buddy_alloc_pages+0x1e4>
    nr_free -= alloc_size;
ffffffffc02007fe:	010a2783          	lw	a5,16(s4)
    cprintf("buddy_alloc_pages: success, new nr_free = %lu\n", nr_free);
ffffffffc0200802:	00001517          	auipc	a0,0x1
ffffffffc0200806:	7fe50513          	addi	a0,a0,2046 # ffffffffc0202000 <etext+0x4fe>
    nr_free -= alloc_size;
ffffffffc020080a:	40d785bb          	subw	a1,a5,a3
ffffffffc020080e:	00ba2823          	sw	a1,16(s4)
    cprintf("buddy_alloc_pages: success, new nr_free = %lu\n", nr_free);
ffffffffc0200812:	93bff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0200816:	60a6                	ld	ra,72(sp)
ffffffffc0200818:	8522                	mv	a0,s0
ffffffffc020081a:	6406                	ld	s0,64(sp)
ffffffffc020081c:	74e2                	ld	s1,56(sp)
ffffffffc020081e:	7942                	ld	s2,48(sp)
ffffffffc0200820:	79a2                	ld	s3,40(sp)
ffffffffc0200822:	7a02                	ld	s4,32(sp)
ffffffffc0200824:	6ae2                	ld	s5,24(sp)
ffffffffc0200826:	6b42                	ld	s6,16(sp)
ffffffffc0200828:	6ba2                	ld	s7,8(sp)
ffffffffc020082a:	6161                	addi	sp,sp,80
ffffffffc020082c:	8082                	ret
            index = RIGHT_LEAF(index);
ffffffffc020082e:	0027049b          	addiw	s1,a4,2
            cprintf("buddy2_alloc: go right to index %u, size %u\n", index, node_size/2);
ffffffffc0200832:	8622                	mv	a2,s0
ffffffffc0200834:	85a6                	mv	a1,s1
ffffffffc0200836:	855a                	mv	a0,s6
ffffffffc0200838:	915ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (node_size = self->size; node_size != size; node_size /= 2) {
ffffffffc020083c:	ea8991e3          	bne	s3,s0,ffffffffc02006de <buddy_alloc_pages+0xe2>
ffffffffc0200840:	b5e1                	j	ffffffffc0200708 <buddy_alloc_pages+0x10c>
    cprintf("buddy_alloc_pages: adjusted to %u pages\n", alloc_size);
ffffffffc0200842:	4585                	li	a1,1
ffffffffc0200844:	00001517          	auipc	a0,0x1
ffffffffc0200848:	5dc50513          	addi	a0,a0,1500 # ffffffffc0201e20 <etext+0x31e>
ffffffffc020084c:	901ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    int offset = buddy2_alloc(buddy_manager, alloc_size);
ffffffffc0200850:	0004bb83          	ld	s7,0(s1)
    if (self == NULL) {
ffffffffc0200854:	040b8f63          	beqz	s7,ffffffffc02008b2 <buddy_alloc_pages+0x2b6>
    int offset = buddy2_alloc(buddy_manager, alloc_size);
ffffffffc0200858:	4405                	li	s0,1
    unsigned power = 1;
ffffffffc020085a:	4905                	li	s2,1
    if (self->longest[index] < size) {
ffffffffc020085c:	0004099b          	sext.w	s3,s0
ffffffffc0200860:	b5b9                	j	ffffffffc02006ae <buddy_alloc_pages+0xb2>
    if (n > nr_free || buddy_manager == NULL) {
ffffffffc0200862:	00005617          	auipc	a2,0x5
ffffffffc0200866:	7ee63603          	ld	a2,2030(a2) # ffffffffc0206050 <buddy_manager>
        cprintf("buddy_alloc_pages: cannot allocate (nr_free=%lu, buddy_manager=%p)\n", 
ffffffffc020086a:	00001517          	auipc	a0,0x1
ffffffffc020086e:	56e50513          	addi	a0,a0,1390 # ffffffffc0201dd8 <etext+0x2d6>
ffffffffc0200872:	8dbff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200876:	4401                	li	s0,0
ffffffffc0200878:	bf79                	j	ffffffffc0200816 <buddy_alloc_pages+0x21a>
    self->longest[index] = 0;
ffffffffc020087a:	000ba223          	sw	zero,4(s7)
    cprintf("buddy2_alloc: allocated at offset %u, index %u, node_size %u\n", 
ffffffffc020087e:	86ce                	mv	a3,s3
ffffffffc0200880:	4601                	li	a2,0
ffffffffc0200882:	4581                	li	a1,0
ffffffffc0200884:	00001517          	auipc	a0,0x1
ffffffffc0200888:	6b450513          	addi	a0,a0,1716 # ffffffffc0201f38 <etext+0x436>
ffffffffc020088c:	8c1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200890:	4b01                	li	s6,0
ffffffffc0200892:	b731                	j	ffffffffc020079e <buddy_alloc_pages+0x1a2>
        cprintf("buddy2_alloc: not enough memory (available: %u, requested: %u)\n", 
ffffffffc0200894:	8622                	mv	a2,s0
ffffffffc0200896:	00001517          	auipc	a0,0x1
ffffffffc020089a:	60250513          	addi	a0,a0,1538 # ffffffffc0201e98 <etext+0x396>
ffffffffc020089e:	8afff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("buddy_alloc_pages: allocation failed\n");
ffffffffc02008a2:	00001517          	auipc	a0,0x1
ffffffffc02008a6:	6fe50513          	addi	a0,a0,1790 # ffffffffc0201fa0 <etext+0x49e>
ffffffffc02008aa:	8a3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc02008ae:	4401                	li	s0,0
ffffffffc02008b0:	b79d                	j	ffffffffc0200816 <buddy_alloc_pages+0x21a>
        cprintf("buddy2_alloc: self is NULL\n");
ffffffffc02008b2:	00001517          	auipc	a0,0x1
ffffffffc02008b6:	59e50513          	addi	a0,a0,1438 # ffffffffc0201e50 <etext+0x34e>
ffffffffc02008ba:	893ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (offset == -1) {
ffffffffc02008be:	b7d5                	j	ffffffffc02008a2 <buddy_alloc_pages+0x2a6>
    assert(n > 0);
ffffffffc02008c0:	00001697          	auipc	a3,0x1
ffffffffc02008c4:	4a868693          	addi	a3,a3,1192 # ffffffffc0201d68 <etext+0x266>
ffffffffc02008c8:	00001617          	auipc	a2,0x1
ffffffffc02008cc:	4a860613          	addi	a2,a2,1192 # ffffffffc0201d70 <etext+0x26e>
ffffffffc02008d0:	0ef00593          	li	a1,239
ffffffffc02008d4:	00001517          	auipc	a0,0x1
ffffffffc02008d8:	4b450513          	addi	a0,a0,1204 # ffffffffc0201d88 <etext+0x286>
ffffffffc02008dc:	8e7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02008e0 <buddy_check>:
    cprintf("测试4 通过: 边界情况处理正常\n");
}

// 主测试函数
static void
buddy_check(void) {
ffffffffc02008e0:	7139                	addi	sp,sp,-64
    cprintf("\n============ Buddy System 综合测试开始 ============\n");
ffffffffc02008e2:	00001517          	auipc	a0,0x1
ffffffffc02008e6:	74e50513          	addi	a0,a0,1870 # ffffffffc0202030 <etext+0x52e>
buddy_check(void) {
ffffffffc02008ea:	fc06                	sd	ra,56(sp)
ffffffffc02008ec:	e456                	sd	s5,8(sp)
ffffffffc02008ee:	f822                	sd	s0,48(sp)
ffffffffc02008f0:	f426                	sd	s1,40(sp)
ffffffffc02008f2:	f04a                	sd	s2,32(sp)
ffffffffc02008f4:	ec4e                	sd	s3,24(sp)
ffffffffc02008f6:	e852                	sd	s4,16(sp)
    cprintf("\n============ Buddy System 综合测试开始 ============\n");
ffffffffc02008f8:	855ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\n============ 测试1: 基本分配释放测试 ============\n");
ffffffffc02008fc:	00001517          	auipc	a0,0x1
ffffffffc0200900:	77450513          	addi	a0,a0,1908 # ffffffffc0202070 <etext+0x56e>
ffffffffc0200904:	849ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t initial_free = nr_free_pages();
ffffffffc0200908:	383000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
    cprintf("初始空闲页数: %lu\n", initial_free);
ffffffffc020090c:	85aa                	mv	a1,a0
    size_t initial_free = nr_free_pages();
ffffffffc020090e:	8aaa                	mv	s5,a0
    cprintf("初始空闲页数: %lu\n", initial_free);
ffffffffc0200910:	00001517          	auipc	a0,0x1
ffffffffc0200914:	7a050513          	addi	a0,a0,1952 # ffffffffc02020b0 <etext+0x5ae>
ffffffffc0200918:	835ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020091c:	4505                	li	a0,1
ffffffffc020091e:	355000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200922:	48050a63          	beqz	a0,ffffffffc0200db6 <buddy_check+0x4d6>
    cprintf("分配页面 p0 在偏移 %ld\n", p0 - buddy_base);
ffffffffc0200926:	00005917          	auipc	s2,0x5
ffffffffc020092a:	72290913          	addi	s2,s2,1826 # ffffffffc0206048 <buddy_base>
ffffffffc020092e:	00093583          	ld	a1,0(s2)
ffffffffc0200932:	842a                	mv	s0,a0
ffffffffc0200934:	00002497          	auipc	s1,0x2
ffffffffc0200938:	5d44b483          	ld	s1,1492(s1) # ffffffffc0202f08 <error_string+0x38>
ffffffffc020093c:	40b405b3          	sub	a1,s0,a1
ffffffffc0200940:	858d                	srai	a1,a1,0x3
ffffffffc0200942:	029585b3          	mul	a1,a1,s1
ffffffffc0200946:	00001517          	auipc	a0,0x1
ffffffffc020094a:	7aa50513          	addi	a0,a0,1962 # ffffffffc02020f0 <etext+0x5ee>
ffffffffc020094e:	ffeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(page_ref(p0) == 0);
ffffffffc0200952:	401c                	lw	a5,0(s0)
ffffffffc0200954:	44079163          	bnez	a5,ffffffffc0200d96 <buddy_check+0x4b6>
    assert(PageProperty(p0) && p0->property >= 1);
ffffffffc0200958:	641c                	ld	a5,8(s0)
ffffffffc020095a:	8b89                	andi	a5,a5,2
ffffffffc020095c:	3e078d63          	beqz	a5,ffffffffc0200d56 <buddy_check+0x476>
ffffffffc0200960:	481c                	lw	a5,16(s0)
ffffffffc0200962:	3e078a63          	beqz	a5,ffffffffc0200d56 <buddy_check+0x476>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200966:	4505                	li	a0,1
ffffffffc0200968:	30b000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc020096c:	89aa                	mv	s3,a0
ffffffffc020096e:	40050463          	beqz	a0,ffffffffc0200d76 <buddy_check+0x496>
    cprintf("分配页面 p1 在偏移 %ld\n", p1 - buddy_base);
ffffffffc0200972:	00093583          	ld	a1,0(s2)
ffffffffc0200976:	00001517          	auipc	a0,0x1
ffffffffc020097a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0202170 <etext+0x66e>
ffffffffc020097e:	40b985b3          	sub	a1,s3,a1
ffffffffc0200982:	858d                	srai	a1,a1,0x3
ffffffffc0200984:	029585b3          	mul	a1,a1,s1
ffffffffc0200988:	fc4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p1 != p0);
ffffffffc020098c:	59340563          	beq	s0,s3,ffffffffc0200f16 <buddy_check+0x636>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200990:	4505                	li	a0,1
ffffffffc0200992:	2e1000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200996:	8a2a                	mv	s4,a0
ffffffffc0200998:	54050f63          	beqz	a0,ffffffffc0200ef6 <buddy_check+0x616>
    cprintf("分配页面 p2 在偏移 %ld\n", p2 - buddy_base);
ffffffffc020099c:	00093583          	ld	a1,0(s2)
ffffffffc02009a0:	00002517          	auipc	a0,0x2
ffffffffc02009a4:	82050513          	addi	a0,a0,-2016 # ffffffffc02021c0 <etext+0x6be>
ffffffffc02009a8:	40ba05b3          	sub	a1,s4,a1
ffffffffc02009ac:	858d                	srai	a1,a1,0x3
ffffffffc02009ae:	029585b3          	mul	a1,a1,s1
ffffffffc02009b2:	f9aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p2 != p0 && p2 != p1);
ffffffffc02009b6:	39440063          	beq	s0,s4,ffffffffc0200d36 <buddy_check+0x456>
ffffffffc02009ba:	37498e63          	beq	s3,s4,ffffffffc0200d36 <buddy_check+0x456>
    free_page(p0);
ffffffffc02009be:	4585                	li	a1,1
ffffffffc02009c0:	8522                	mv	a0,s0
ffffffffc02009c2:	2bd000ef          	jal	ra,ffffffffc020147e <free_pages>
    free_page(p1);
ffffffffc02009c6:	4585                	li	a1,1
ffffffffc02009c8:	854e                	mv	a0,s3
ffffffffc02009ca:	2b5000ef          	jal	ra,ffffffffc020147e <free_pages>
    free_page(p2);
ffffffffc02009ce:	4585                	li	a1,1
ffffffffc02009d0:	8552                	mv	a0,s4
ffffffffc02009d2:	2ad000ef          	jal	ra,ffffffffc020147e <free_pages>
    assert(nr_free_pages() == initial_free);
ffffffffc02009d6:	2b5000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
ffffffffc02009da:	40aa9e63          	bne	s5,a0,ffffffffc0200df6 <buddy_check+0x516>
    cprintf("测试1 通过: 基本分配释放功能正常\n");
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	83a50513          	addi	a0,a0,-1990 # ffffffffc0202218 <etext+0x716>
ffffffffc02009e6:	f66ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\n============ 测试2: 不同大小分配测试 ============\n");
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	85e50513          	addi	a0,a0,-1954 # ffffffffc0202248 <etext+0x746>
ffffffffc02009f2:	f5aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t initial_free = nr_free_pages();
ffffffffc02009f6:	295000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
    cprintf("初始空闲页数: %lu\n", initial_free);
ffffffffc02009fa:	85aa                	mv	a1,a0
    size_t initial_free = nr_free_pages();
ffffffffc02009fc:	8aaa                	mv	s5,a0
    cprintf("初始空闲页数: %lu\n", initial_free);
ffffffffc02009fe:	00001517          	auipc	a0,0x1
ffffffffc0200a02:	6b250513          	addi	a0,a0,1714 # ffffffffc02020b0 <etext+0x5ae>
ffffffffc0200a06:	f46ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pages_1 = alloc_pages(1);
ffffffffc0200a0a:	4505                	li	a0,1
ffffffffc0200a0c:	267000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200a10:	89aa                	mv	s3,a0
    assert(pages_1 != NULL);
ffffffffc0200a12:	42050263          	beqz	a0,ffffffffc0200e36 <buddy_check+0x556>
    assert(pages_1->property >= 1);
ffffffffc0200a16:	491c                	lw	a5,16(a0)
ffffffffc0200a18:	3e078f63          	beqz	a5,ffffffffc0200e16 <buddy_check+0x536>
    cprintf("分配 1 页在偏移 %ld\n", pages_1 - buddy_base);
ffffffffc0200a1c:	00093583          	ld	a1,0(s2)
ffffffffc0200a20:	00002517          	auipc	a0,0x2
ffffffffc0200a24:	89050513          	addi	a0,a0,-1904 # ffffffffc02022b0 <etext+0x7ae>
ffffffffc0200a28:	40b985b3          	sub	a1,s3,a1
ffffffffc0200a2c:	858d                	srai	a1,a1,0x3
ffffffffc0200a2e:	029585b3          	mul	a1,a1,s1
ffffffffc0200a32:	f1aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pages_2 = alloc_pages(2);
ffffffffc0200a36:	4509                	li	a0,2
ffffffffc0200a38:	23b000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200a3c:	842a                	mv	s0,a0
    assert(pages_2 != NULL);
ffffffffc0200a3e:	46050c63          	beqz	a0,ffffffffc0200eb6 <buddy_check+0x5d6>
    assert(pages_2->property >= 2);
ffffffffc0200a42:	4918                	lw	a4,16(a0)
ffffffffc0200a44:	4785                	li	a5,1
ffffffffc0200a46:	44e7f863          	bgeu	a5,a4,ffffffffc0200e96 <buddy_check+0x5b6>
    cprintf("分配 2 页在偏移 %ld\n", pages_2 - buddy_base);
ffffffffc0200a4a:	00093583          	ld	a1,0(s2)
ffffffffc0200a4e:	00002517          	auipc	a0,0x2
ffffffffc0200a52:	8aa50513          	addi	a0,a0,-1878 # ffffffffc02022f8 <etext+0x7f6>
ffffffffc0200a56:	40b405b3          	sub	a1,s0,a1
ffffffffc0200a5a:	858d                	srai	a1,a1,0x3
ffffffffc0200a5c:	029585b3          	mul	a1,a1,s1
ffffffffc0200a60:	eecff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pages_4 = alloc_pages(4);
ffffffffc0200a64:	4511                	li	a0,4
ffffffffc0200a66:	20d000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200a6a:	8a2a                	mv	s4,a0
    assert(pages_4 != NULL);
ffffffffc0200a6c:	46050563          	beqz	a0,ffffffffc0200ed6 <buddy_check+0x5f6>
    assert(pages_4->property >= 4);
ffffffffc0200a70:	4918                	lw	a4,16(a0)
ffffffffc0200a72:	478d                	li	a5,3
ffffffffc0200a74:	36e7f163          	bgeu	a5,a4,ffffffffc0200dd6 <buddy_check+0x4f6>
    cprintf("分配 4 页在偏移 %ld\n", pages_4 - buddy_base);
ffffffffc0200a78:	00093583          	ld	a1,0(s2)
ffffffffc0200a7c:	00002517          	auipc	a0,0x2
ffffffffc0200a80:	8c450513          	addi	a0,a0,-1852 # ffffffffc0202340 <etext+0x83e>
ffffffffc0200a84:	40ba05b3          	sub	a1,s4,a1
ffffffffc0200a88:	858d                	srai	a1,a1,0x3
ffffffffc0200a8a:	029585b3          	mul	a1,a1,s1
ffffffffc0200a8e:	ebeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(pages_1 + pages_1->property <= pages_2 || 
ffffffffc0200a92:	0109e703          	lwu	a4,16(s3)
ffffffffc0200a96:	00271793          	slli	a5,a4,0x2
ffffffffc0200a9a:	97ba                	add	a5,a5,a4
ffffffffc0200a9c:	078e                	slli	a5,a5,0x3
ffffffffc0200a9e:	97ce                	add	a5,a5,s3
ffffffffc0200aa0:	01046703          	lwu	a4,16(s0)
ffffffffc0200aa4:	1ef47963          	bgeu	s0,a5,ffffffffc0200c96 <buddy_check+0x3b6>
ffffffffc0200aa8:	00271793          	slli	a5,a4,0x2
ffffffffc0200aac:	97ba                	add	a5,a5,a4
ffffffffc0200aae:	078e                	slli	a5,a5,0x3
ffffffffc0200ab0:	97a2                	add	a5,a5,s0
ffffffffc0200ab2:	26f9e263          	bltu	s3,a5,ffffffffc0200d16 <buddy_check+0x436>
    assert(pages_2 + pages_2->property <= pages_4 || 
ffffffffc0200ab6:	00fa7b63          	bgeu	s4,a5,ffffffffc0200acc <buddy_check+0x1ec>
ffffffffc0200aba:	010a6703          	lwu	a4,16(s4)
ffffffffc0200abe:	00271793          	slli	a5,a4,0x2
ffffffffc0200ac2:	97ba                	add	a5,a5,a4
ffffffffc0200ac4:	078e                	slli	a5,a5,0x3
ffffffffc0200ac6:	97d2                	add	a5,a5,s4
ffffffffc0200ac8:	50f46763          	bltu	s0,a5,ffffffffc0200fd6 <buddy_check+0x6f6>
    free_pages(pages_1, 1);
ffffffffc0200acc:	4585                	li	a1,1
ffffffffc0200ace:	854e                	mv	a0,s3
ffffffffc0200ad0:	1af000ef          	jal	ra,ffffffffc020147e <free_pages>
    free_pages(pages_2, 2);
ffffffffc0200ad4:	4589                	li	a1,2
ffffffffc0200ad6:	8522                	mv	a0,s0
ffffffffc0200ad8:	1a7000ef          	jal	ra,ffffffffc020147e <free_pages>
    free_pages(pages_4, 4);
ffffffffc0200adc:	4591                	li	a1,4
ffffffffc0200ade:	8552                	mv	a0,s4
ffffffffc0200ae0:	19f000ef          	jal	ra,ffffffffc020147e <free_pages>
    assert(nr_free_pages() == initial_free);
ffffffffc0200ae4:	1a7000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
ffffffffc0200ae8:	44aa9763          	bne	s5,a0,ffffffffc0200f36 <buddy_check+0x656>
    cprintf("测试2 通过: 不同大小分配功能正常\n");
ffffffffc0200aec:	00002517          	auipc	a0,0x2
ffffffffc0200af0:	92450513          	addi	a0,a0,-1756 # ffffffffc0202410 <etext+0x90e>
ffffffffc0200af4:	e58ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\n============ 测试3: 简化版伙伴合并功能测试 ============\n");
ffffffffc0200af8:	00002517          	auipc	a0,0x2
ffffffffc0200afc:	94850513          	addi	a0,a0,-1720 # ffffffffc0202440 <etext+0x93e>
ffffffffc0200b00:	e4cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t initial_free = nr_free_pages();
ffffffffc0200b04:	187000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
    cprintf("初始空闲页数: %lu\n", initial_free);
ffffffffc0200b08:	85aa                	mv	a1,a0
    size_t initial_free = nr_free_pages();
ffffffffc0200b0a:	8a2a                	mv	s4,a0
    cprintf("初始空闲页数: %lu\n", initial_free);
ffffffffc0200b0c:	00001517          	auipc	a0,0x1
ffffffffc0200b10:	5a450513          	addi	a0,a0,1444 # ffffffffc02020b0 <etext+0x5ae>
ffffffffc0200b14:	e38ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p1 = alloc_page();
ffffffffc0200b18:	4505                	li	a0,1
ffffffffc0200b1a:	159000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200b1e:	89aa                	mv	s3,a0
    struct Page *p2 = alloc_page();
ffffffffc0200b20:	4505                	li	a0,1
ffffffffc0200b22:	151000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
    cprintf("分配页面 p1 在偏移 %ld\n", p1 - buddy_base);
ffffffffc0200b26:	00093583          	ld	a1,0(s2)
    struct Page *p2 = alloc_page();
ffffffffc0200b2a:	842a                	mv	s0,a0
    cprintf("分配页面 p1 在偏移 %ld\n", p1 - buddy_base);
ffffffffc0200b2c:	00001517          	auipc	a0,0x1
ffffffffc0200b30:	64450513          	addi	a0,a0,1604 # ffffffffc0202170 <etext+0x66e>
ffffffffc0200b34:	40b985b3          	sub	a1,s3,a1
ffffffffc0200b38:	858d                	srai	a1,a1,0x3
ffffffffc0200b3a:	029585b3          	mul	a1,a1,s1
ffffffffc0200b3e:	e0eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("分配页面 p2 在偏移 %ld\n", p2 - buddy_base);
ffffffffc0200b42:	00093583          	ld	a1,0(s2)
ffffffffc0200b46:	00001517          	auipc	a0,0x1
ffffffffc0200b4a:	67a50513          	addi	a0,a0,1658 # ffffffffc02021c0 <etext+0x6be>
ffffffffc0200b4e:	40b405b3          	sub	a1,s0,a1
ffffffffc0200b52:	858d                	srai	a1,a1,0x3
ffffffffc0200b54:	029585b3          	mul	a1,a1,s1
ffffffffc0200b58:	df4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t block_index = page - buddy_base;
ffffffffc0200b5c:	00093683          	ld	a3,0(s2)
    cprintf("p1 的伙伴在偏移 %ld\n", buddy_of_p1 - buddy_base);
ffffffffc0200b60:	00002517          	auipc	a0,0x2
ffffffffc0200b64:	92850513          	addi	a0,a0,-1752 # ffffffffc0202488 <etext+0x986>
    size_t block_index = page - buddy_base;
ffffffffc0200b68:	40d987b3          	sub	a5,s3,a3
ffffffffc0200b6c:	878d                	srai	a5,a5,0x3
ffffffffc0200b6e:	029787b3          	mul	a5,a5,s1
    size_t buddy_index = block_index ^ block_size;
ffffffffc0200b72:	0017c793          	xori	a5,a5,1
    return buddy_base + buddy_index;
ffffffffc0200b76:	00279713          	slli	a4,a5,0x2
ffffffffc0200b7a:	97ba                	add	a5,a5,a4
ffffffffc0200b7c:	078e                	slli	a5,a5,0x3
    cprintf("p1 的伙伴在偏移 %ld\n", buddy_of_p1 - buddy_base);
ffffffffc0200b7e:	4037d593          	srai	a1,a5,0x3
ffffffffc0200b82:	029585b3          	mul	a1,a1,s1
    return buddy_base + buddy_index;
ffffffffc0200b86:	00f684b3          	add	s1,a3,a5
    cprintf("p1 的伙伴在偏移 %ld\n", buddy_of_p1 - buddy_base);
ffffffffc0200b8a:	dc2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (p2 == buddy_of_p1) {
ffffffffc0200b8e:	14940463          	beq	s0,s1,ffffffffc0200cd6 <buddy_check+0x3f6>
        cprintf("p1 和 p2 不是伙伴块，跳过合并测试\n");
ffffffffc0200b92:	00002517          	auipc	a0,0x2
ffffffffc0200b96:	97e50513          	addi	a0,a0,-1666 # ffffffffc0202510 <etext+0xa0e>
ffffffffc0200b9a:	db2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_page(p1);
ffffffffc0200b9e:	4585                	li	a1,1
ffffffffc0200ba0:	854e                	mv	a0,s3
ffffffffc0200ba2:	0dd000ef          	jal	ra,ffffffffc020147e <free_pages>
        free_page(p2);
ffffffffc0200ba6:	8522                	mv	a0,s0
ffffffffc0200ba8:	4585                	li	a1,1
ffffffffc0200baa:	0d5000ef          	jal	ra,ffffffffc020147e <free_pages>
        cprintf("测试3 跳过: 分配的页面不是伙伴块\n");
ffffffffc0200bae:	00002517          	auipc	a0,0x2
ffffffffc0200bb2:	99250513          	addi	a0,a0,-1646 # ffffffffc0202540 <etext+0xa3e>
ffffffffc0200bb6:	d96ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\n============ 测试4: 边界情况测试 ============\n");
ffffffffc0200bba:	00002517          	auipc	a0,0x2
ffffffffc0200bbe:	9b650513          	addi	a0,a0,-1610 # ffffffffc0202570 <etext+0xa6e>
ffffffffc0200bc2:	d8aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t initial_free = nr_free_pages();
ffffffffc0200bc6:	0c5000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
ffffffffc0200bca:	842a                	mv	s0,a0
    cprintf("初始空闲页数: %lu\n", initial_free);
ffffffffc0200bcc:	85aa                	mv	a1,a0
ffffffffc0200bce:	00001517          	auipc	a0,0x1
ffffffffc0200bd2:	4e250513          	addi	a0,a0,1250 # ffffffffc02020b0 <etext+0x5ae>
ffffffffc0200bd6:	d76ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t large_request = initial_free + 100;
ffffffffc0200bda:	06440493          	addi	s1,s0,100
    struct Page *large_block = alloc_pages(large_request);
ffffffffc0200bde:	8526                	mv	a0,s1
ffffffffc0200be0:	093000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
    assert(large_block == NULL);
ffffffffc0200be4:	36051963          	bnez	a0,ffffffffc0200f56 <buddy_check+0x676>
    cprintf("正确拒绝分配 %lu 页的请求 (只有 %lu 页可用)\n", large_request, initial_free);
ffffffffc0200be8:	8622                	mv	a2,s0
ffffffffc0200bea:	85a6                	mv	a1,s1
ffffffffc0200bec:	00002517          	auipc	a0,0x2
ffffffffc0200bf0:	9d450513          	addi	a0,a0,-1580 # ffffffffc02025c0 <etext+0xabe>
ffffffffc0200bf4:	d58ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *one_page = alloc_pages(1);
ffffffffc0200bf8:	4505                	li	a0,1
ffffffffc0200bfa:	079000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
    assert(one_page != NULL);
ffffffffc0200bfe:	36050c63          	beqz	a0,ffffffffc0200f76 <buddy_check+0x696>
    assert(one_page->property >= 1);
ffffffffc0200c02:	491c                	lw	a5,16(a0)
ffffffffc0200c04:	38078963          	beqz	a5,ffffffffc0200f96 <buddy_check+0x6b6>
    free_page(one_page);
ffffffffc0200c08:	4585                	li	a1,1
ffffffffc0200c0a:	075000ef          	jal	ra,ffffffffc020147e <free_pages>
    cprintf("分配1页测试正常\n");
ffffffffc0200c0e:	00002517          	auipc	a0,0x2
ffffffffc0200c12:	a2250513          	addi	a0,a0,-1502 # ffffffffc0202630 <etext+0xb2e>
ffffffffc0200c16:	d36ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *pages_3 = alloc_pages(3);
ffffffffc0200c1a:	450d                	li	a0,3
ffffffffc0200c1c:	057000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200c20:	84aa                	mv	s1,a0
    assert(pages_3 != NULL);
ffffffffc0200c22:	38050a63          	beqz	a0,ffffffffc0200fb6 <buddy_check+0x6d6>
    assert(pages_3->property >= 4);  // 应该调整为4页
ffffffffc0200c26:	4918                	lw	a4,16(a0)
ffffffffc0200c28:	478d                	li	a5,3
ffffffffc0200c2a:	22e7f663          	bgeu	a5,a4,ffffffffc0200e56 <buddy_check+0x576>
    cprintf("分配3页正确调整为4页\n");
ffffffffc0200c2e:	00002517          	auipc	a0,0x2
ffffffffc0200c32:	a4250513          	addi	a0,a0,-1470 # ffffffffc0202670 <etext+0xb6e>
ffffffffc0200c36:	d16ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    free_pages(pages_3, 3);
ffffffffc0200c3a:	458d                	li	a1,3
ffffffffc0200c3c:	8526                	mv	a0,s1
ffffffffc0200c3e:	041000ef          	jal	ra,ffffffffc020147e <free_pages>
    if (medium_request > 0) {
ffffffffc0200c42:	479d                	li	a5,7
ffffffffc0200c44:	0487ef63          	bltu	a5,s0,ffffffffc0200ca2 <buddy_check+0x3c2>
    assert(nr_free_pages() == initial_free);
ffffffffc0200c48:	043000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
ffffffffc0200c4c:	22a41563          	bne	s0,a0,ffffffffc0200e76 <buddy_check+0x596>
    cprintf("测试4 通过: 边界情况处理正常\n");
ffffffffc0200c50:	00002517          	auipc	a0,0x2
ffffffffc0200c54:	aa050513          	addi	a0,a0,-1376 # ffffffffc02026f0 <etext+0xbee>
ffffffffc0200c58:	cf4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_check_basic_allocation();
    buddy_check_different_sizes();
    buddy_check_simple_merging();
    buddy_check_edge_cases();
    
    cprintf("\n============ 所有测试完成! ============\n");
ffffffffc0200c5c:	00002517          	auipc	a0,0x2
ffffffffc0200c60:	ac450513          	addi	a0,a0,-1340 # ffffffffc0202720 <etext+0xc1e>
ffffffffc0200c64:	ce8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Buddy System 测试完成!\n");
ffffffffc0200c68:	00002517          	auipc	a0,0x2
ffffffffc0200c6c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0202750 <etext+0xc4e>
ffffffffc0200c70:	cdcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("最终空闲页数: %lu\n", nr_free_pages());
ffffffffc0200c74:	017000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
}
ffffffffc0200c78:	7442                	ld	s0,48(sp)
ffffffffc0200c7a:	70e2                	ld	ra,56(sp)
ffffffffc0200c7c:	74a2                	ld	s1,40(sp)
ffffffffc0200c7e:	7902                	ld	s2,32(sp)
ffffffffc0200c80:	69e2                	ld	s3,24(sp)
ffffffffc0200c82:	6a42                	ld	s4,16(sp)
ffffffffc0200c84:	6aa2                	ld	s5,8(sp)
    cprintf("最终空闲页数: %lu\n", nr_free_pages());
ffffffffc0200c86:	85aa                	mv	a1,a0
ffffffffc0200c88:	00002517          	auipc	a0,0x2
ffffffffc0200c8c:	ae850513          	addi	a0,a0,-1304 # ffffffffc0202770 <etext+0xc6e>
}
ffffffffc0200c90:	6121                	addi	sp,sp,64
    cprintf("最终空闲页数: %lu\n", nr_free_pages());
ffffffffc0200c92:	cbaff06f          	j	ffffffffc020014c <cprintf>
    assert(pages_1 + pages_1->property <= pages_2 || 
ffffffffc0200c96:	00271793          	slli	a5,a4,0x2
ffffffffc0200c9a:	97ba                	add	a5,a5,a4
ffffffffc0200c9c:	078e                	slli	a5,a5,0x3
ffffffffc0200c9e:	97a2                	add	a5,a5,s0
ffffffffc0200ca0:	bd19                	j	ffffffffc0200ab6 <buddy_check+0x1d6>
    size_t medium_request = initial_free / 8;  // 使用更小的块，避免问题
ffffffffc0200ca2:	00345913          	srli	s2,s0,0x3
        struct Page *medium_block = alloc_pages(medium_request);
ffffffffc0200ca6:	854a                	mv	a0,s2
ffffffffc0200ca8:	7ca000ef          	jal	ra,ffffffffc0201472 <alloc_pages>
ffffffffc0200cac:	84aa                	mv	s1,a0
            cprintf("成功分配 %lu 页的块\n", medium_request);
ffffffffc0200cae:	85ca                	mv	a1,s2
        if (medium_block != NULL) {
ffffffffc0200cb0:	cd21                	beqz	a0,ffffffffc0200d08 <buddy_check+0x428>
            cprintf("成功分配 %lu 页的块\n", medium_request);
ffffffffc0200cb2:	00002517          	auipc	a0,0x2
ffffffffc0200cb6:	9de50513          	addi	a0,a0,-1570 # ffffffffc0202690 <etext+0xb8e>
ffffffffc0200cba:	c92ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            free_pages(medium_block, medium_request);
ffffffffc0200cbe:	85ca                	mv	a1,s2
ffffffffc0200cc0:	8526                	mv	a0,s1
ffffffffc0200cc2:	7bc000ef          	jal	ra,ffffffffc020147e <free_pages>
            cprintf("成功释放 %lu 页的块\n", medium_request);
ffffffffc0200cc6:	85ca                	mv	a1,s2
ffffffffc0200cc8:	00002517          	auipc	a0,0x2
ffffffffc0200ccc:	9e850513          	addi	a0,a0,-1560 # ffffffffc02026b0 <etext+0xbae>
ffffffffc0200cd0:	c7cff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200cd4:	bf95                	j	ffffffffc0200c48 <buddy_check+0x368>
        cprintf("p1 和 p2 是伙伴块，可以进行合并测试\n");
ffffffffc0200cd6:	00001517          	auipc	a0,0x1
ffffffffc0200cda:	7d250513          	addi	a0,a0,2002 # ffffffffc02024a8 <etext+0x9a6>
ffffffffc0200cde:	c6eff0ef          	jal	ra,ffffffffc020014c <cprintf>
        free_page(p1);
ffffffffc0200ce2:	4585                	li	a1,1
ffffffffc0200ce4:	854e                	mv	a0,s3
ffffffffc0200ce6:	798000ef          	jal	ra,ffffffffc020147e <free_pages>
        free_page(p2);
ffffffffc0200cea:	4585                	li	a1,1
ffffffffc0200cec:	8522                	mv	a0,s0
ffffffffc0200cee:	790000ef          	jal	ra,ffffffffc020147e <free_pages>
        assert(nr_free_pages() == initial_free);
ffffffffc0200cf2:	798000ef          	jal	ra,ffffffffc020148a <nr_free_pages>
ffffffffc0200cf6:	30aa1063          	bne	s4,a0,ffffffffc0200ff6 <buddy_check+0x716>
        cprintf("测试3 通过: 伙伴合并功能正常\n");
ffffffffc0200cfa:	00001517          	auipc	a0,0x1
ffffffffc0200cfe:	7e650513          	addi	a0,a0,2022 # ffffffffc02024e0 <etext+0x9de>
ffffffffc0200d02:	c4aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200d06:	bd55                	j	ffffffffc0200bba <buddy_check+0x2da>
            cprintf("无法分配 %lu 页的块\n", medium_request);
ffffffffc0200d08:	00002517          	auipc	a0,0x2
ffffffffc0200d0c:	9c850513          	addi	a0,a0,-1592 # ffffffffc02026d0 <etext+0xbce>
ffffffffc0200d10:	c3cff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200d14:	bf15                	j	ffffffffc0200c48 <buddy_check+0x368>
    assert(pages_1 + pages_1->property <= pages_2 || 
ffffffffc0200d16:	00001697          	auipc	a3,0x1
ffffffffc0200d1a:	64a68693          	addi	a3,a3,1610 # ffffffffc0202360 <etext+0x85e>
ffffffffc0200d1e:	00001617          	auipc	a2,0x1
ffffffffc0200d22:	05260613          	addi	a2,a2,82 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200d26:	19b00593          	li	a1,411
ffffffffc0200d2a:	00001517          	auipc	a0,0x1
ffffffffc0200d2e:	05e50513          	addi	a0,a0,94 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200d32:	c90ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != p0 && p2 != p1);
ffffffffc0200d36:	00001697          	auipc	a3,0x1
ffffffffc0200d3a:	4aa68693          	addi	a3,a3,1194 # ffffffffc02021e0 <etext+0x6de>
ffffffffc0200d3e:	00001617          	auipc	a2,0x1
ffffffffc0200d42:	03260613          	addi	a2,a2,50 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200d46:	17500593          	li	a1,373
ffffffffc0200d4a:	00001517          	auipc	a0,0x1
ffffffffc0200d4e:	03e50513          	addi	a0,a0,62 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200d52:	c70ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0) && p0->property >= 1);
ffffffffc0200d56:	00001697          	auipc	a3,0x1
ffffffffc0200d5a:	3d268693          	addi	a3,a3,978 # ffffffffc0202128 <etext+0x626>
ffffffffc0200d5e:	00001617          	auipc	a2,0x1
ffffffffc0200d62:	01260613          	addi	a2,a2,18 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200d66:	16d00593          	li	a1,365
ffffffffc0200d6a:	00001517          	auipc	a0,0x1
ffffffffc0200d6e:	01e50513          	addi	a0,a0,30 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200d72:	c50ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d76:	00001697          	auipc	a3,0x1
ffffffffc0200d7a:	3da68693          	addi	a3,a3,986 # ffffffffc0202150 <etext+0x64e>
ffffffffc0200d7e:	00001617          	auipc	a2,0x1
ffffffffc0200d82:	ff260613          	addi	a2,a2,-14 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200d86:	16f00593          	li	a1,367
ffffffffc0200d8a:	00001517          	auipc	a0,0x1
ffffffffc0200d8e:	ffe50513          	addi	a0,a0,-2 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200d92:	c30ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0);
ffffffffc0200d96:	00001697          	auipc	a3,0x1
ffffffffc0200d9a:	37a68693          	addi	a3,a3,890 # ffffffffc0202110 <etext+0x60e>
ffffffffc0200d9e:	00001617          	auipc	a2,0x1
ffffffffc0200da2:	fd260613          	addi	a2,a2,-46 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200da6:	16c00593          	li	a1,364
ffffffffc0200daa:	00001517          	auipc	a0,0x1
ffffffffc0200dae:	fde50513          	addi	a0,a0,-34 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200db2:	c10ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200db6:	00001697          	auipc	a3,0x1
ffffffffc0200dba:	31a68693          	addi	a3,a3,794 # ffffffffc02020d0 <etext+0x5ce>
ffffffffc0200dbe:	00001617          	auipc	a2,0x1
ffffffffc0200dc2:	fb260613          	addi	a2,a2,-78 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200dc6:	16a00593          	li	a1,362
ffffffffc0200dca:	00001517          	auipc	a0,0x1
ffffffffc0200dce:	fbe50513          	addi	a0,a0,-66 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200dd2:	bf0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_4->property >= 4);
ffffffffc0200dd6:	00001697          	auipc	a3,0x1
ffffffffc0200dda:	55268693          	addi	a3,a3,1362 # ffffffffc0202328 <etext+0x826>
ffffffffc0200dde:	00001617          	auipc	a2,0x1
ffffffffc0200de2:	f9260613          	addi	a2,a2,-110 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200de6:	19700593          	li	a1,407
ffffffffc0200dea:	00001517          	auipc	a0,0x1
ffffffffc0200dee:	f9e50513          	addi	a0,a0,-98 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200df2:	bd0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_free);
ffffffffc0200df6:	00001697          	auipc	a3,0x1
ffffffffc0200dfa:	40268693          	addi	a3,a3,1026 # ffffffffc02021f8 <etext+0x6f6>
ffffffffc0200dfe:	00001617          	auipc	a2,0x1
ffffffffc0200e02:	f7260613          	addi	a2,a2,-142 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200e06:	17c00593          	li	a1,380
ffffffffc0200e0a:	00001517          	auipc	a0,0x1
ffffffffc0200e0e:	f7e50513          	addi	a0,a0,-130 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200e12:	bb0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_1->property >= 1);
ffffffffc0200e16:	00001697          	auipc	a3,0x1
ffffffffc0200e1a:	48268693          	addi	a3,a3,1154 # ffffffffc0202298 <etext+0x796>
ffffffffc0200e1e:	00001617          	auipc	a2,0x1
ffffffffc0200e22:	f5260613          	addi	a2,a2,-174 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200e26:	18d00593          	li	a1,397
ffffffffc0200e2a:	00001517          	auipc	a0,0x1
ffffffffc0200e2e:	f5e50513          	addi	a0,a0,-162 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200e32:	b90ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_1 != NULL);
ffffffffc0200e36:	00001697          	auipc	a3,0x1
ffffffffc0200e3a:	45268693          	addi	a3,a3,1106 # ffffffffc0202288 <etext+0x786>
ffffffffc0200e3e:	00001617          	auipc	a2,0x1
ffffffffc0200e42:	f3260613          	addi	a2,a2,-206 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200e46:	18c00593          	li	a1,396
ffffffffc0200e4a:	00001517          	auipc	a0,0x1
ffffffffc0200e4e:	f3e50513          	addi	a0,a0,-194 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200e52:	b70ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_3->property >= 4);  // 应该调整为4页
ffffffffc0200e56:	00002697          	auipc	a3,0x2
ffffffffc0200e5a:	80268693          	addi	a3,a3,-2046 # ffffffffc0202658 <etext+0xb56>
ffffffffc0200e5e:	00001617          	auipc	a2,0x1
ffffffffc0200e62:	f1260613          	addi	a2,a2,-238 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200e66:	1ea00593          	li	a1,490
ffffffffc0200e6a:	00001517          	auipc	a0,0x1
ffffffffc0200e6e:	f1e50513          	addi	a0,a0,-226 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200e72:	b50ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_free);
ffffffffc0200e76:	00001697          	auipc	a3,0x1
ffffffffc0200e7a:	38268693          	addi	a3,a3,898 # ffffffffc02021f8 <etext+0x6f6>
ffffffffc0200e7e:	00001617          	auipc	a2,0x1
ffffffffc0200e82:	ef260613          	addi	a2,a2,-270 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200e86:	1fb00593          	li	a1,507
ffffffffc0200e8a:	00001517          	auipc	a0,0x1
ffffffffc0200e8e:	efe50513          	addi	a0,a0,-258 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200e92:	b30ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_2->property >= 2);
ffffffffc0200e96:	00001697          	auipc	a3,0x1
ffffffffc0200e9a:	44a68693          	addi	a3,a3,1098 # ffffffffc02022e0 <etext+0x7de>
ffffffffc0200e9e:	00001617          	auipc	a2,0x1
ffffffffc0200ea2:	ed260613          	addi	a2,a2,-302 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200ea6:	19200593          	li	a1,402
ffffffffc0200eaa:	00001517          	auipc	a0,0x1
ffffffffc0200eae:	ede50513          	addi	a0,a0,-290 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200eb2:	b10ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_2 != NULL);
ffffffffc0200eb6:	00001697          	auipc	a3,0x1
ffffffffc0200eba:	41a68693          	addi	a3,a3,1050 # ffffffffc02022d0 <etext+0x7ce>
ffffffffc0200ebe:	00001617          	auipc	a2,0x1
ffffffffc0200ec2:	eb260613          	addi	a2,a2,-334 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200ec6:	19100593          	li	a1,401
ffffffffc0200eca:	00001517          	auipc	a0,0x1
ffffffffc0200ece:	ebe50513          	addi	a0,a0,-322 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200ed2:	af0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_4 != NULL);
ffffffffc0200ed6:	00001697          	auipc	a3,0x1
ffffffffc0200eda:	44268693          	addi	a3,a3,1090 # ffffffffc0202318 <etext+0x816>
ffffffffc0200ede:	00001617          	auipc	a2,0x1
ffffffffc0200ee2:	e9260613          	addi	a2,a2,-366 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200ee6:	19600593          	li	a1,406
ffffffffc0200eea:	00001517          	auipc	a0,0x1
ffffffffc0200eee:	e9e50513          	addi	a0,a0,-354 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200ef2:	ad0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ef6:	00001697          	auipc	a3,0x1
ffffffffc0200efa:	2aa68693          	addi	a3,a3,682 # ffffffffc02021a0 <etext+0x69e>
ffffffffc0200efe:	00001617          	auipc	a2,0x1
ffffffffc0200f02:	e7260613          	addi	a2,a2,-398 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200f06:	17300593          	li	a1,371
ffffffffc0200f0a:	00001517          	auipc	a0,0x1
ffffffffc0200f0e:	e7e50513          	addi	a0,a0,-386 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200f12:	ab0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != p0);
ffffffffc0200f16:	00001697          	auipc	a3,0x1
ffffffffc0200f1a:	27a68693          	addi	a3,a3,634 # ffffffffc0202190 <etext+0x68e>
ffffffffc0200f1e:	00001617          	auipc	a2,0x1
ffffffffc0200f22:	e5260613          	addi	a2,a2,-430 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200f26:	17100593          	li	a1,369
ffffffffc0200f2a:	00001517          	auipc	a0,0x1
ffffffffc0200f2e:	e5e50513          	addi	a0,a0,-418 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200f32:	a90ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == initial_free);
ffffffffc0200f36:	00001697          	auipc	a3,0x1
ffffffffc0200f3a:	2c268693          	addi	a3,a3,706 # ffffffffc02021f8 <etext+0x6f6>
ffffffffc0200f3e:	00001617          	auipc	a2,0x1
ffffffffc0200f42:	e3260613          	addi	a2,a2,-462 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200f46:	1a500593          	li	a1,421
ffffffffc0200f4a:	00001517          	auipc	a0,0x1
ffffffffc0200f4e:	e3e50513          	addi	a0,a0,-450 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200f52:	a70ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(large_block == NULL);
ffffffffc0200f56:	00001697          	auipc	a3,0x1
ffffffffc0200f5a:	65268693          	addi	a3,a3,1618 # ffffffffc02025a8 <etext+0xaa6>
ffffffffc0200f5e:	00001617          	auipc	a2,0x1
ffffffffc0200f62:	e1260613          	addi	a2,a2,-494 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200f66:	1dd00593          	li	a1,477
ffffffffc0200f6a:	00001517          	auipc	a0,0x1
ffffffffc0200f6e:	e1e50513          	addi	a0,a0,-482 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200f72:	a50ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(one_page != NULL);
ffffffffc0200f76:	00001697          	auipc	a3,0x1
ffffffffc0200f7a:	68a68693          	addi	a3,a3,1674 # ffffffffc0202600 <etext+0xafe>
ffffffffc0200f7e:	00001617          	auipc	a2,0x1
ffffffffc0200f82:	df260613          	addi	a2,a2,-526 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200f86:	1e200593          	li	a1,482
ffffffffc0200f8a:	00001517          	auipc	a0,0x1
ffffffffc0200f8e:	dfe50513          	addi	a0,a0,-514 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200f92:	a30ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(one_page->property >= 1);
ffffffffc0200f96:	00001697          	auipc	a3,0x1
ffffffffc0200f9a:	68268693          	addi	a3,a3,1666 # ffffffffc0202618 <etext+0xb16>
ffffffffc0200f9e:	00001617          	auipc	a2,0x1
ffffffffc0200fa2:	dd260613          	addi	a2,a2,-558 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200fa6:	1e300593          	li	a1,483
ffffffffc0200faa:	00001517          	auipc	a0,0x1
ffffffffc0200fae:	dde50513          	addi	a0,a0,-546 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200fb2:	a10ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_3 != NULL);
ffffffffc0200fb6:	00001697          	auipc	a3,0x1
ffffffffc0200fba:	69268693          	addi	a3,a3,1682 # ffffffffc0202648 <etext+0xb46>
ffffffffc0200fbe:	00001617          	auipc	a2,0x1
ffffffffc0200fc2:	db260613          	addi	a2,a2,-590 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200fc6:	1e900593          	li	a1,489
ffffffffc0200fca:	00001517          	auipc	a0,0x1
ffffffffc0200fce:	dbe50513          	addi	a0,a0,-578 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200fd2:	9f0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(pages_2 + pages_2->property <= pages_4 || 
ffffffffc0200fd6:	00001697          	auipc	a3,0x1
ffffffffc0200fda:	3e268693          	addi	a3,a3,994 # ffffffffc02023b8 <etext+0x8b6>
ffffffffc0200fde:	00001617          	auipc	a2,0x1
ffffffffc0200fe2:	d9260613          	addi	a2,a2,-622 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0200fe6:	19d00593          	li	a1,413
ffffffffc0200fea:	00001517          	auipc	a0,0x1
ffffffffc0200fee:	d9e50513          	addi	a0,a0,-610 # ffffffffc0201d88 <etext+0x286>
ffffffffc0200ff2:	9d0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == initial_free);
ffffffffc0200ff6:	00001697          	auipc	a3,0x1
ffffffffc0200ffa:	20268693          	addi	a3,a3,514 # ffffffffc02021f8 <etext+0x6f6>
ffffffffc0200ffe:	00001617          	auipc	a2,0x1
ffffffffc0201002:	d7260613          	addi	a2,a2,-654 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0201006:	1c500593          	li	a1,453
ffffffffc020100a:	00001517          	auipc	a0,0x1
ffffffffc020100e:	d7e50513          	addi	a0,a0,-642 # ffffffffc0201d88 <etext+0x286>
ffffffffc0201012:	9b0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201016 <buddy_free_pages>:
    if (n == 0) {
ffffffffc0201016:	cde9                	beqz	a1,ffffffffc02010f0 <buddy_free_pages+0xda>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0201018:	7139                	addi	sp,sp,-64
ffffffffc020101a:	f822                	sd	s0,48(sp)
    cprintf("buddy_free_pages: free %lu pages at %p\n", n, base);
ffffffffc020101c:	862a                	mv	a2,a0
ffffffffc020101e:	842a                	mv	s0,a0
ffffffffc0201020:	00001517          	auipc	a0,0x1
ffffffffc0201024:	7a850513          	addi	a0,a0,1960 # ffffffffc02027c8 <etext+0xcc6>
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0201028:	e852                	sd	s4,16(sp)
ffffffffc020102a:	fc06                	sd	ra,56(sp)
ffffffffc020102c:	f426                	sd	s1,40(sp)
ffffffffc020102e:	f04a                	sd	s2,32(sp)
ffffffffc0201030:	ec4e                	sd	s3,24(sp)
ffffffffc0201032:	e456                	sd	s5,8(sp)
    if (buddy_manager == NULL) {
ffffffffc0201034:	00005a17          	auipc	s4,0x5
ffffffffc0201038:	01ca0a13          	addi	s4,s4,28 # ffffffffc0206050 <buddy_manager>
    cprintf("buddy_free_pages: free %lu pages at %p\n", n, base);
ffffffffc020103c:	910ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (buddy_manager == NULL) {
ffffffffc0201040:	000a3783          	ld	a5,0(s4)
ffffffffc0201044:	1a078763          	beqz	a5,ffffffffc02011f2 <buddy_free_pages+0x1dc>
    int offset = base - buddy_base;
ffffffffc0201048:	00005917          	auipc	s2,0x5
ffffffffc020104c:	00093903          	ld	s2,0(s2) # ffffffffc0206048 <buddy_base>
ffffffffc0201050:	41240933          	sub	s2,s0,s2
ffffffffc0201054:	00002597          	auipc	a1,0x2
ffffffffc0201058:	eb45b583          	ld	a1,-332(a1) # ffffffffc0202f08 <error_string+0x38>
ffffffffc020105c:	40395913          	srai	s2,s2,0x3
ffffffffc0201060:	02b9093b          	mulw	s2,s2,a1
    size_t actual_size = base->property;
ffffffffc0201064:	4804                	lw	s1,16(s0)
    cprintf("buddy_free_pages: offset = %d, actual_size = %lu\n", offset, actual_size);
ffffffffc0201066:	00001517          	auipc	a0,0x1
ffffffffc020106a:	7ba50513          	addi	a0,a0,1978 # ffffffffc0202820 <etext+0xd1e>
    size_t actual_size = base->property;
ffffffffc020106e:	02049993          	slli	s3,s1,0x20
ffffffffc0201072:	0209d993          	srli	s3,s3,0x20
    cprintf("buddy_free_pages: offset = %d, actual_size = %lu\n", offset, actual_size);
ffffffffc0201076:	864e                	mv	a2,s3
ffffffffc0201078:	85ca                	mv	a1,s2
ffffffffc020107a:	8d2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (unsigned i = 0; i < actual_size; i++, p++) {
ffffffffc020107e:	c09d                	beqz	s1,ffffffffc02010a4 <buddy_free_pages+0x8e>
ffffffffc0201080:	00299793          	slli	a5,s3,0x2
ffffffffc0201084:	01378733          	add	a4,a5,s3
ffffffffc0201088:	070e                	slli	a4,a4,0x3
ffffffffc020108a:	9722                	add	a4,a4,s0
        assert(PageReserved(p));  // 应该已经被标记为已分配
ffffffffc020108c:	641c                	ld	a5,8(s0)
ffffffffc020108e:	8b85                	andi	a5,a5,1
ffffffffc0201090:	18078863          	beqz	a5,ffffffffc0201220 <buddy_free_pages+0x20a>
        p->flags = 0;
ffffffffc0201094:	00043423          	sd	zero,8(s0)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201098:	00042023          	sw	zero,0(s0)
    for (unsigned i = 0; i < actual_size; i++, p++) {
ffffffffc020109c:	02840413          	addi	s0,s0,40
ffffffffc02010a0:	fee416e3          	bne	s0,a4,ffffffffc020108c <buddy_free_pages+0x76>
    buddy2_free(buddy_manager, offset);
ffffffffc02010a4:	000a3a83          	ld	s5,0(s4)
    if (self == NULL || offset < 0 || offset >= self->size) {
ffffffffc02010a8:	000a8863          	beqz	s5,ffffffffc02010b8 <buddy_free_pages+0xa2>
ffffffffc02010ac:	00094663          	bltz	s2,ffffffffc02010b8 <buddy_free_pages+0xa2>
ffffffffc02010b0:	000aa783          	lw	a5,0(s5)
ffffffffc02010b4:	04f96463          	bltu	s2,a5,ffffffffc02010fc <buddy_free_pages+0xe6>
        cprintf("buddy2_free: invalid parameters\n");
ffffffffc02010b8:	00001517          	auipc	a0,0x1
ffffffffc02010bc:	7b050513          	addi	a0,a0,1968 # ffffffffc0202868 <etext+0xd66>
ffffffffc02010c0:	88cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    nr_free += actual_size;
ffffffffc02010c4:	00005717          	auipc	a4,0x5
ffffffffc02010c8:	f5470713          	addi	a4,a4,-172 # ffffffffc0206018 <free_area>
ffffffffc02010cc:	4b1c                	lw	a5,16(a4)
}
ffffffffc02010ce:	7442                	ld	s0,48(sp)
ffffffffc02010d0:	70e2                	ld	ra,56(sp)
ffffffffc02010d2:	7902                	ld	s2,32(sp)
ffffffffc02010d4:	69e2                	ld	s3,24(sp)
ffffffffc02010d6:	6a42                	ld	s4,16(sp)
ffffffffc02010d8:	6aa2                	ld	s5,8(sp)
    nr_free += actual_size;
ffffffffc02010da:	009785bb          	addw	a1,a5,s1
}
ffffffffc02010de:	74a2                	ld	s1,40(sp)
    nr_free += actual_size;
ffffffffc02010e0:	cb0c                	sw	a1,16(a4)
    cprintf("buddy_free_pages: success, new nr_free = %lu\n", nr_free);
ffffffffc02010e2:	00002517          	auipc	a0,0x2
ffffffffc02010e6:	88650513          	addi	a0,a0,-1914 # ffffffffc0202968 <etext+0xe66>
}
ffffffffc02010ea:	6121                	addi	sp,sp,64
    cprintf("buddy_free_pages: success, new nr_free = %lu\n", nr_free);
ffffffffc02010ec:	860ff06f          	j	ffffffffc020014c <cprintf>
        cprintf("buddy_free_pages: warning: trying to free 0 pages\n");
ffffffffc02010f0:	00001517          	auipc	a0,0x1
ffffffffc02010f4:	6a050513          	addi	a0,a0,1696 # ffffffffc0202790 <etext+0xc8e>
ffffffffc02010f8:	854ff06f          	j	ffffffffc020014c <cprintf>
    index = offset + self->size - 1;
ffffffffc02010fc:	37fd                	addiw	a5,a5,-1
ffffffffc02010fe:	012789bb          	addw	s3,a5,s2
ffffffffc0201102:	0009841b          	sext.w	s0,s3
    cprintf("buddy2_free: freeing offset %u, starting at index %u\n", offset, index);
ffffffffc0201106:	8622                	mv	a2,s0
ffffffffc0201108:	85ca                	mv	a1,s2
ffffffffc020110a:	00001517          	auipc	a0,0x1
ffffffffc020110e:	78650513          	addi	a0,a0,1926 # ffffffffc0202890 <etext+0xd8e>
ffffffffc0201112:	83aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (; self->longest[index]; index = PARENT(index)) {
ffffffffc0201116:	02099793          	slli	a5,s3,0x20
ffffffffc020111a:	01e7d993          	srli	s3,a5,0x1e
ffffffffc020111e:	99d6                	add	s3,s3,s5
ffffffffc0201120:	0049a783          	lw	a5,4(s3)
ffffffffc0201124:	0e078c63          	beqz	a5,ffffffffc020121c <buddy_free_pages+0x206>
        if (index == 0) {
ffffffffc0201128:	c07d                	beqz	s0,ffffffffc020120e <buddy_free_pages+0x1f8>
        node_size *= 2;
ffffffffc020112a:	4909                	li	s2,2
ffffffffc020112c:	a021                	j	ffffffffc0201134 <buddy_free_pages+0x11e>
ffffffffc020112e:	0019191b          	slliw	s2,s2,0x1
        if (index == 0) {
ffffffffc0201132:	cc71                	beqz	s0,ffffffffc020120e <buddy_free_pages+0x1f8>
    for (; self->longest[index]; index = PARENT(index)) {
ffffffffc0201134:	2405                	addiw	s0,s0,1
ffffffffc0201136:	0014541b          	srliw	s0,s0,0x1
ffffffffc020113a:	347d                	addiw	s0,s0,-1
ffffffffc020113c:	02041713          	slli	a4,s0,0x20
ffffffffc0201140:	01e75793          	srli	a5,a4,0x1e
ffffffffc0201144:	97d6                	add	a5,a5,s5
ffffffffc0201146:	43dc                	lw	a5,4(a5)
ffffffffc0201148:	f3fd                	bnez	a5,ffffffffc020112e <buddy_free_pages+0x118>
    self->longest[index] = node_size;
ffffffffc020114a:	02041713          	slli	a4,s0,0x20
ffffffffc020114e:	01e75793          	srli	a5,a4,0x1e
ffffffffc0201152:	97d6                	add	a5,a5,s5
ffffffffc0201154:	0127a223          	sw	s2,4(a5)
    cprintf("buddy2_free: set longest[%u] = %u\n", index, node_size);
ffffffffc0201158:	864a                	mv	a2,s2
ffffffffc020115a:	85a2                	mv	a1,s0
ffffffffc020115c:	00001517          	auipc	a0,0x1
ffffffffc0201160:	78c50513          	addi	a0,a0,1932 # ffffffffc02028e8 <etext+0xde6>
ffffffffc0201164:	fe9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (index) {
ffffffffc0201168:	dc31                	beqz	s0,ffffffffc02010c4 <buddy_free_pages+0xae>
            cprintf("buddy2_free: updated index %u to %u\n", index, self->longest[index]);
ffffffffc020116a:	00001997          	auipc	s3,0x1
ffffffffc020116e:	7d698993          	addi	s3,s3,2006 # ffffffffc0202940 <etext+0xe3e>
            cprintf("buddy2_free: merged at index %u, size %u\n", index, node_size);
ffffffffc0201172:	00001a17          	auipc	s4,0x1
ffffffffc0201176:	79ea0a13          	addi	s4,s4,1950 # ffffffffc0202910 <etext+0xe0e>
        index = PARENT(index);
ffffffffc020117a:	2405                	addiw	s0,s0,1
ffffffffc020117c:	0014571b          	srliw	a4,s0,0x1
ffffffffc0201180:	377d                	addiw	a4,a4,-1
        right_longest = self->longest[RIGHT_LEAF(index)];
ffffffffc0201182:	ffe47793          	andi	a5,s0,-2
        left_longest = self->longest[LEFT_LEAF(index)];
ffffffffc0201186:	0017169b          	slliw	a3,a4,0x1
ffffffffc020118a:	2685                	addiw	a3,a3,1
        right_longest = self->longest[RIGHT_LEAF(index)];
ffffffffc020118c:	1782                	slli	a5,a5,0x20
        left_longest = self->longest[LEFT_LEAF(index)];
ffffffffc020118e:	02069613          	slli	a2,a3,0x20
        right_longest = self->longest[RIGHT_LEAF(index)];
ffffffffc0201192:	9381                	srli	a5,a5,0x20
        left_longest = self->longest[LEFT_LEAF(index)];
ffffffffc0201194:	01e65693          	srli	a3,a2,0x1e
        right_longest = self->longest[RIGHT_LEAF(index)];
ffffffffc0201198:	078a                	slli	a5,a5,0x2
        left_longest = self->longest[LEFT_LEAF(index)];
ffffffffc020119a:	96d6                	add	a3,a3,s5
        right_longest = self->longest[RIGHT_LEAF(index)];
ffffffffc020119c:	97d6                	add	a5,a5,s5
        left_longest = self->longest[LEFT_LEAF(index)];
ffffffffc020119e:	42d4                	lw	a3,4(a3)
        right_longest = self->longest[RIGHT_LEAF(index)];
ffffffffc02011a0:	43dc                	lw	a5,4(a5)
        node_size *= 2;
ffffffffc02011a2:	0019191b          	slliw	s2,s2,0x1
ffffffffc02011a6:	864a                	mv	a2,s2
        if (left_longest + right_longest == node_size) {
ffffffffc02011a8:	00f685bb          	addw	a1,a3,a5
        index = PARENT(index);
ffffffffc02011ac:	0007041b          	sext.w	s0,a4
        if (left_longest + right_longest == node_size) {
ffffffffc02011b0:	03258463          	beq	a1,s2,ffffffffc02011d8 <buddy_free_pages+0x1c2>
            self->longest[index] = MAX(left_longest, right_longest);
ffffffffc02011b4:	0006861b          	sext.w	a2,a3
ffffffffc02011b8:	00f6f463          	bgeu	a3,a5,ffffffffc02011c0 <buddy_free_pages+0x1aa>
ffffffffc02011bc:	0007861b          	sext.w	a2,a5
ffffffffc02011c0:	02071793          	slli	a5,a4,0x20
ffffffffc02011c4:	01e7d713          	srli	a4,a5,0x1e
ffffffffc02011c8:	9756                	add	a4,a4,s5
ffffffffc02011ca:	c350                	sw	a2,4(a4)
            cprintf("buddy2_free: updated index %u to %u\n", index, self->longest[index]);
ffffffffc02011cc:	85a2                	mv	a1,s0
ffffffffc02011ce:	854e                	mv	a0,s3
ffffffffc02011d0:	f7dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (index) {
ffffffffc02011d4:	f05d                	bnez	s0,ffffffffc020117a <buddy_free_pages+0x164>
ffffffffc02011d6:	b5fd                	j	ffffffffc02010c4 <buddy_free_pages+0xae>
            self->longest[index] = node_size;
ffffffffc02011d8:	02071793          	slli	a5,a4,0x20
ffffffffc02011dc:	01e7d713          	srli	a4,a5,0x1e
ffffffffc02011e0:	9756                	add	a4,a4,s5
ffffffffc02011e2:	01272223          	sw	s2,4(a4)
            cprintf("buddy2_free: merged at index %u, size %u\n", index, node_size);
ffffffffc02011e6:	85a2                	mv	a1,s0
ffffffffc02011e8:	8552                	mv	a0,s4
ffffffffc02011ea:	f63fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (index) {
ffffffffc02011ee:	f451                	bnez	s0,ffffffffc020117a <buddy_free_pages+0x164>
ffffffffc02011f0:	bdd1                	j	ffffffffc02010c4 <buddy_free_pages+0xae>
}
ffffffffc02011f2:	7442                	ld	s0,48(sp)
ffffffffc02011f4:	70e2                	ld	ra,56(sp)
ffffffffc02011f6:	74a2                	ld	s1,40(sp)
ffffffffc02011f8:	7902                	ld	s2,32(sp)
ffffffffc02011fa:	69e2                	ld	s3,24(sp)
ffffffffc02011fc:	6a42                	ld	s4,16(sp)
ffffffffc02011fe:	6aa2                	ld	s5,8(sp)
        cprintf("buddy_free_pages: buddy_manager is NULL\n");
ffffffffc0201200:	00001517          	auipc	a0,0x1
ffffffffc0201204:	5f050513          	addi	a0,a0,1520 # ffffffffc02027f0 <etext+0xcee>
}
ffffffffc0201208:	6121                	addi	sp,sp,64
        cprintf("buddy_free_pages: buddy_manager is NULL\n");
ffffffffc020120a:	f43fe06f          	j	ffffffffc020014c <cprintf>
            cprintf("buddy2_free: reached root\n");
ffffffffc020120e:	00001517          	auipc	a0,0x1
ffffffffc0201212:	6ba50513          	addi	a0,a0,1722 # ffffffffc02028c8 <etext+0xdc6>
ffffffffc0201216:	f37fe0ef          	jal	ra,ffffffffc020014c <cprintf>
            return;
ffffffffc020121a:	b56d                	j	ffffffffc02010c4 <buddy_free_pages+0xae>
    node_size = 1;
ffffffffc020121c:	4905                	li	s2,1
ffffffffc020121e:	b735                	j	ffffffffc020114a <buddy_free_pages+0x134>
        assert(PageReserved(p));  // 应该已经被标记为已分配
ffffffffc0201220:	00001697          	auipc	a3,0x1
ffffffffc0201224:	63868693          	addi	a3,a3,1592 # ffffffffc0202858 <etext+0xd56>
ffffffffc0201228:	00001617          	auipc	a2,0x1
ffffffffc020122c:	b4860613          	addi	a2,a2,-1208 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0201230:	13d00593          	li	a1,317
ffffffffc0201234:	00001517          	auipc	a0,0x1
ffffffffc0201238:	b5450513          	addi	a0,a0,-1196 # ffffffffc0201d88 <etext+0x286>
ffffffffc020123c:	f87fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201240 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0201240:	715d                	addi	sp,sp,-80
ffffffffc0201242:	e486                	sd	ra,72(sp)
ffffffffc0201244:	e0a2                	sd	s0,64(sp)
ffffffffc0201246:	fc26                	sd	s1,56(sp)
ffffffffc0201248:	f84a                	sd	s2,48(sp)
ffffffffc020124a:	f44e                	sd	s3,40(sp)
ffffffffc020124c:	f052                	sd	s4,32(sp)
ffffffffc020124e:	ec56                	sd	s5,24(sp)
ffffffffc0201250:	e85a                	sd	s6,16(sp)
ffffffffc0201252:	e45e                	sd	s7,8(sp)
    assert(n > 0);
ffffffffc0201254:	1e058f63          	beqz	a1,ffffffffc0201452 <buddy_init_memmap+0x212>
ffffffffc0201258:	842a                	mv	s0,a0
    cprintf("buddy_init_memmap: start with %lu pages\n", n);
ffffffffc020125a:	00001517          	auipc	a0,0x1
ffffffffc020125e:	73e50513          	addi	a0,a0,1854 # ffffffffc0202998 <etext+0xe96>
ffffffffc0201262:	84ae                	mv	s1,a1
ffffffffc0201264:	ee9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (; p != base + n; p++) {
ffffffffc0201268:	00249693          	slli	a3,s1,0x2
ffffffffc020126c:	96a6                	add	a3,a3,s1
ffffffffc020126e:	068e                	slli	a3,a3,0x3
ffffffffc0201270:	96a2                	add	a3,a3,s0
ffffffffc0201272:	87a2                	mv	a5,s0
ffffffffc0201274:	00d40e63          	beq	s0,a3,ffffffffc0201290 <buddy_init_memmap+0x50>
        assert(PageReserved(p));
ffffffffc0201278:	6798                	ld	a4,8(a5)
ffffffffc020127a:	8b05                	andi	a4,a4,1
ffffffffc020127c:	1a070b63          	beqz	a4,ffffffffc0201432 <buddy_init_memmap+0x1f2>
        p->flags = 0;
ffffffffc0201280:	0007b423          	sd	zero,8(a5)
ffffffffc0201284:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0201288:	02878793          	addi	a5,a5,40
ffffffffc020128c:	fed796e3          	bne	a5,a3,ffffffffc0201278 <buddy_init_memmap+0x38>
    if (IS_POWER_OF_2(n)) {
ffffffffc0201290:	fff48793          	addi	a5,s1,-1
ffffffffc0201294:	8fe5                	and	a5,a5,s1
        actual_size = n;
ffffffffc0201296:	0004899b          	sext.w	s3,s1
    if (IS_POWER_OF_2(n)) {
ffffffffc020129a:	10079863          	bnez	a5,ffffffffc02013aa <buddy_init_memmap+0x16a>
    buddy_manager = buddy2_new(actual_size);
ffffffffc020129e:	8b4e                	mv	s6,s3
    cprintf("buddy_init_memmap: adjusted to %u pages\n", actual_size);
ffffffffc02012a0:	85ce                	mv	a1,s3
ffffffffc02012a2:	00001517          	auipc	a0,0x1
ffffffffc02012a6:	72650513          	addi	a0,a0,1830 # ffffffffc02029c8 <etext+0xec6>
ffffffffc02012aa:	ea3fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (size < 1 || !IS_POWER_OF_2(size)) {
ffffffffc02012ae:	13605863          	blez	s6,ffffffffc02013de <buddy_init_memmap+0x19e>
ffffffffc02012b2:	fffb079b          	addiw	a5,s6,-1
ffffffffc02012b6:	00fb77b3          	and	a5,s6,a5
ffffffffc02012ba:	2781                	sext.w	a5,a5
ffffffffc02012bc:	12079163          	bnez	a5,ffffffffc02013de <buddy_init_memmap+0x19e>
    return sizeof(buddy2_t) + (2 * size - 1) * sizeof(unsigned);
ffffffffc02012c0:	0019959b          	slliw	a1,s3,0x1
ffffffffc02012c4:	1582                	slli	a1,a1,0x20
ffffffffc02012c6:	9181                	srli	a1,a1,0x20
    cprintf("buddy2_new: required_size = %lu bytes for %d pages\n", required_size, size);
ffffffffc02012c8:	865a                	mv	a2,s6
ffffffffc02012ca:	058a                	slli	a1,a1,0x2
ffffffffc02012cc:	00001517          	auipc	a0,0x1
ffffffffc02012d0:	76450513          	addi	a0,a0,1892 # ffffffffc0202a30 <etext+0xf2e>
ffffffffc02012d4:	e79fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("buddy2_new: self = %p\n", self);
ffffffffc02012d8:	c06005b7          	lui	a1,0xc0600
ffffffffc02012dc:	00001517          	auipc	a0,0x1
ffffffffc02012e0:	78c50513          	addi	a0,a0,1932 # ffffffffc0202a68 <etext+0xf66>
ffffffffc02012e4:	e69fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (i = 0; i < 2 * size - 1; ++i) {
ffffffffc02012e8:	001b1a9b          	slliw	s5,s6,0x1
    self->size = size;
ffffffffc02012ec:	c06007b7          	lui	a5,0xc0600
ffffffffc02012f0:	0137a023          	sw	s3,0(a5) # ffffffffc0600000 <end+0x3f9f78>
    for (i = 0; i < 2 * size - 1; ++i) {
ffffffffc02012f4:	3afd                	addiw	s5,s5,-1
ffffffffc02012f6:	894e                	mv	s2,s3
ffffffffc02012f8:	4481                	li	s1,0
        self->longest[i] = node_size;
ffffffffc02012fa:	c0600a37          	lui	s4,0xc0600
        cprintf("buddy2_new: longest[%d] = %u\n", i, node_size);
ffffffffc02012fe:	00001b97          	auipc	s7,0x1
ffffffffc0201302:	782b8b93          	addi	s7,s7,1922 # ffffffffc0202a80 <etext+0xf7e>
        if (IS_POWER_OF_2(i+1)) {
ffffffffc0201306:	85a6                	mv	a1,s1
ffffffffc0201308:	2485                	addiw	s1,s1,1
ffffffffc020130a:	00b4f7b3          	and	a5,s1,a1
ffffffffc020130e:	e399                	bnez	a5,ffffffffc0201314 <buddy_init_memmap+0xd4>
            node_size = node_size / 2;
ffffffffc0201310:	0019591b          	srliw	s2,s2,0x1
        self->longest[i] = node_size;
ffffffffc0201314:	00259793          	slli	a5,a1,0x2
ffffffffc0201318:	97d2                	add	a5,a5,s4
ffffffffc020131a:	0127a223          	sw	s2,4(a5)
        cprintf("buddy2_new: longest[%d] = %u\n", i, node_size);
ffffffffc020131e:	864a                	mv	a2,s2
ffffffffc0201320:	855e                	mv	a0,s7
ffffffffc0201322:	e2bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (i = 0; i < 2 * size - 1; ++i) {
ffffffffc0201326:	ff5490e3          	bne	s1,s5,ffffffffc0201306 <buddy_init_memmap+0xc6>
    cprintf("buddy2_new: successfully initialized for %d pages\n", size);
ffffffffc020132a:	85da                	mv	a1,s6
ffffffffc020132c:	00001517          	auipc	a0,0x1
ffffffffc0201330:	77450513          	addi	a0,a0,1908 # ffffffffc0202aa0 <etext+0xf9e>
ffffffffc0201334:	e19fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (p = base; p != base + actual_size; p++) {
ffffffffc0201338:	02099793          	slli	a5,s3,0x20
ffffffffc020133c:	9381                	srli	a5,a5,0x20
ffffffffc020133e:	00279713          	slli	a4,a5,0x2
ffffffffc0201342:	973e                	add	a4,a4,a5
ffffffffc0201344:	070e                	slli	a4,a4,0x3
    buddy_manager = buddy2_new(actual_size);
ffffffffc0201346:	00005797          	auipc	a5,0x5
ffffffffc020134a:	d147b523          	sd	s4,-758(a5) # ffffffffc0206050 <buddy_manager>
    buddy_base = base;
ffffffffc020134e:	00005797          	auipc	a5,0x5
ffffffffc0201352:	ce87bd23          	sd	s0,-774(a5) # ffffffffc0206048 <buddy_base>
    for (p = base; p != base + actual_size; p++) {
ffffffffc0201356:	9722                	add	a4,a4,s0
        ClearPageReserved(p);
ffffffffc0201358:	641c                	ld	a5,8(s0)
    for (p = base; p != base + actual_size; p++) {
ffffffffc020135a:	02840413          	addi	s0,s0,40
        ClearPageReserved(p);
ffffffffc020135e:	9bf9                	andi	a5,a5,-2
ffffffffc0201360:	fef43023          	sd	a5,-32(s0)
    for (p = base; p != base + actual_size; p++) {
ffffffffc0201364:	fee41ae3          	bne	s0,a4,ffffffffc0201358 <buddy_init_memmap+0x118>
    nr_free += actual_size;
ffffffffc0201368:	00005417          	auipc	s0,0x5
ffffffffc020136c:	cb040413          	addi	s0,s0,-848 # ffffffffc0206018 <free_area>
ffffffffc0201370:	481c                	lw	a5,16(s0)
    cprintf("buddy system initialized: managing %u pages\n", actual_size);
ffffffffc0201372:	85ce                	mv	a1,s3
ffffffffc0201374:	00001517          	auipc	a0,0x1
ffffffffc0201378:	76450513          	addi	a0,a0,1892 # ffffffffc0202ad8 <etext+0xfd6>
    nr_free += actual_size;
ffffffffc020137c:	013789bb          	addw	s3,a5,s3
ffffffffc0201380:	01342823          	sw	s3,16(s0)
    cprintf("buddy system initialized: managing %u pages\n", actual_size);
ffffffffc0201384:	dc9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("nr_free after init: %lu\n", nr_free);
ffffffffc0201388:	480c                	lw	a1,16(s0)
}
ffffffffc020138a:	6406                	ld	s0,64(sp)
ffffffffc020138c:	60a6                	ld	ra,72(sp)
ffffffffc020138e:	74e2                	ld	s1,56(sp)
ffffffffc0201390:	7942                	ld	s2,48(sp)
ffffffffc0201392:	79a2                	ld	s3,40(sp)
ffffffffc0201394:	7a02                	ld	s4,32(sp)
ffffffffc0201396:	6ae2                	ld	s5,24(sp)
ffffffffc0201398:	6b42                	ld	s6,16(sp)
ffffffffc020139a:	6ba2                	ld	s7,8(sp)
    cprintf("nr_free after init: %lu\n", nr_free);
ffffffffc020139c:	00001517          	auipc	a0,0x1
ffffffffc02013a0:	76c50513          	addi	a0,a0,1900 # ffffffffc0202b08 <etext+0x1006>
}
ffffffffc02013a4:	6161                	addi	sp,sp,80
    cprintf("nr_free after init: %lu\n", nr_free);
ffffffffc02013a6:	da7fe06f          	j	ffffffffc020014c <cprintf>
    if (size == 0) return 1;
ffffffffc02013aa:	06098163          	beqz	s3,ffffffffc020140c <buddy_init_memmap+0x1cc>
    while (power < size) {
ffffffffc02013ae:	4705                	li	a4,1
    unsigned power = 1;
ffffffffc02013b0:	4785                	li	a5,1
    while (power < size) {
ffffffffc02013b2:	06e98763          	beq	s3,a4,ffffffffc0201420 <buddy_init_memmap+0x1e0>
        power *= 2;
ffffffffc02013b6:	0017979b          	slliw	a5,a5,0x1
    while (power < size) {
ffffffffc02013ba:	ff37eee3          	bltu	a5,s3,ffffffffc02013b6 <buddy_init_memmap+0x176>
        while (actual_size > n) {
ffffffffc02013be:	02079713          	slli	a4,a5,0x20
ffffffffc02013c2:	9301                	srli	a4,a4,0x20
ffffffffc02013c4:	00e4f963          	bgeu	s1,a4,ffffffffc02013d6 <buddy_init_memmap+0x196>
            actual_size >>= 1;
ffffffffc02013c8:	0017d79b          	srliw	a5,a5,0x1
        while (actual_size > n) {
ffffffffc02013cc:	02079713          	slli	a4,a5,0x20
ffffffffc02013d0:	9301                	srli	a4,a4,0x20
ffffffffc02013d2:	fee4ebe3          	bltu	s1,a4,ffffffffc02013c8 <buddy_init_memmap+0x188>
    buddy_manager = buddy2_new(actual_size);
ffffffffc02013d6:	00078b1b          	sext.w	s6,a5
            actual_size >>= 1;
ffffffffc02013da:	89be                	mv	s3,a5
ffffffffc02013dc:	b5d1                	j	ffffffffc02012a0 <buddy_init_memmap+0x60>
        cprintf("buddy2_new: invalid size %d\n", size);
ffffffffc02013de:	85da                	mv	a1,s6
ffffffffc02013e0:	00001517          	auipc	a0,0x1
ffffffffc02013e4:	61850513          	addi	a0,a0,1560 # ffffffffc02029f8 <etext+0xef6>
ffffffffc02013e8:	d65fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        panic("buddy2_new failed");
ffffffffc02013ec:	00001617          	auipc	a2,0x1
ffffffffc02013f0:	62c60613          	addi	a2,a2,1580 # ffffffffc0202a18 <etext+0xf16>
ffffffffc02013f4:	0dd00593          	li	a1,221
ffffffffc02013f8:	00001517          	auipc	a0,0x1
ffffffffc02013fc:	99050513          	addi	a0,a0,-1648 # ffffffffc0201d88 <etext+0x286>
    buddy_manager = buddy2_new(actual_size);
ffffffffc0201400:	00005797          	auipc	a5,0x5
ffffffffc0201404:	c407b823          	sd	zero,-944(a5) # ffffffffc0206050 <buddy_manager>
        panic("buddy2_new failed");
ffffffffc0201408:	dbbfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    cprintf("buddy_init_memmap: adjusted to %u pages\n", actual_size);
ffffffffc020140c:	4585                	li	a1,1
ffffffffc020140e:	00001517          	auipc	a0,0x1
ffffffffc0201412:	5ba50513          	addi	a0,a0,1466 # ffffffffc02029c8 <etext+0xec6>
ffffffffc0201416:	d37fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_manager = buddy2_new(actual_size);
ffffffffc020141a:	4b05                	li	s6,1
    if (size == 0) return 1;
ffffffffc020141c:	4985                	li	s3,1
ffffffffc020141e:	b54d                	j	ffffffffc02012c0 <buddy_init_memmap+0x80>
    cprintf("buddy_init_memmap: adjusted to %u pages\n", actual_size);
ffffffffc0201420:	4585                	li	a1,1
ffffffffc0201422:	00001517          	auipc	a0,0x1
ffffffffc0201426:	5a650513          	addi	a0,a0,1446 # ffffffffc02029c8 <etext+0xec6>
ffffffffc020142a:	d23fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020142e:	4b05                	li	s6,1
ffffffffc0201430:	bd41                	j	ffffffffc02012c0 <buddy_init_memmap+0x80>
        assert(PageReserved(p));
ffffffffc0201432:	00001697          	auipc	a3,0x1
ffffffffc0201436:	42668693          	addi	a3,a3,1062 # ffffffffc0202858 <etext+0xd56>
ffffffffc020143a:	00001617          	auipc	a2,0x1
ffffffffc020143e:	93660613          	addi	a2,a2,-1738 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0201442:	0c700593          	li	a1,199
ffffffffc0201446:	00001517          	auipc	a0,0x1
ffffffffc020144a:	94250513          	addi	a0,a0,-1726 # ffffffffc0201d88 <etext+0x286>
ffffffffc020144e:	d75fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0201452:	00001697          	auipc	a3,0x1
ffffffffc0201456:	91668693          	addi	a3,a3,-1770 # ffffffffc0201d68 <etext+0x266>
ffffffffc020145a:	00001617          	auipc	a2,0x1
ffffffffc020145e:	91660613          	addi	a2,a2,-1770 # ffffffffc0201d70 <etext+0x26e>
ffffffffc0201462:	0c000593          	li	a1,192
ffffffffc0201466:	00001517          	auipc	a0,0x1
ffffffffc020146a:	92250513          	addi	a0,a0,-1758 # ffffffffc0201d88 <etext+0x286>
ffffffffc020146e:	d55fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201472 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0201472:	00005797          	auipc	a5,0x5
ffffffffc0201476:	bf67b783          	ld	a5,-1034(a5) # ffffffffc0206068 <pmm_manager>
ffffffffc020147a:	6f9c                	ld	a5,24(a5)
ffffffffc020147c:	8782                	jr	a5

ffffffffc020147e <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc020147e:	00005797          	auipc	a5,0x5
ffffffffc0201482:	bea7b783          	ld	a5,-1046(a5) # ffffffffc0206068 <pmm_manager>
ffffffffc0201486:	739c                	ld	a5,32(a5)
ffffffffc0201488:	8782                	jr	a5

ffffffffc020148a <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc020148a:	00005797          	auipc	a5,0x5
ffffffffc020148e:	bde7b783          	ld	a5,-1058(a5) # ffffffffc0206068 <pmm_manager>
ffffffffc0201492:	779c                	ld	a5,40(a5)
ffffffffc0201494:	8782                	jr	a5

ffffffffc0201496 <pmm_init>:
    pmm_manager = &buddy_pmm_manager; //可以选择使用buddy系统或best_fit系统,pmm_manager = &best_fit_pmm_manager/&buddy_pmm_manager;
ffffffffc0201496:	00001797          	auipc	a5,0x1
ffffffffc020149a:	6aa78793          	addi	a5,a5,1706 # ffffffffc0202b40 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020149e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02014a0:	7179                	addi	sp,sp,-48
ffffffffc02014a2:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02014a4:	00001517          	auipc	a0,0x1
ffffffffc02014a8:	6d450513          	addi	a0,a0,1748 # ffffffffc0202b78 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager; //可以选择使用buddy系统或best_fit系统,pmm_manager = &best_fit_pmm_manager/&buddy_pmm_manager;
ffffffffc02014ac:	00005417          	auipc	s0,0x5
ffffffffc02014b0:	bbc40413          	addi	s0,s0,-1092 # ffffffffc0206068 <pmm_manager>
void pmm_init(void) {
ffffffffc02014b4:	f406                	sd	ra,40(sp)
ffffffffc02014b6:	ec26                	sd	s1,24(sp)
ffffffffc02014b8:	e44e                	sd	s3,8(sp)
ffffffffc02014ba:	e84a                	sd	s2,16(sp)
ffffffffc02014bc:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager; //可以选择使用buddy系统或best_fit系统,pmm_manager = &best_fit_pmm_manager/&buddy_pmm_manager;
ffffffffc02014be:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02014c0:	c8dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc02014c4:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02014c6:	00005497          	auipc	s1,0x5
ffffffffc02014ca:	bba48493          	addi	s1,s1,-1094 # ffffffffc0206080 <va_pa_offset>
    pmm_manager->init();
ffffffffc02014ce:	679c                	ld	a5,8(a5)
ffffffffc02014d0:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02014d2:	57f5                	li	a5,-3
ffffffffc02014d4:	07fa                	slli	a5,a5,0x1e
ffffffffc02014d6:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02014d8:	8e4ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc02014dc:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02014de:	8e8ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02014e2:	14050d63          	beqz	a0,ffffffffc020163c <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02014e6:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02014e8:	00001517          	auipc	a0,0x1
ffffffffc02014ec:	6d850513          	addi	a0,a0,1752 # ffffffffc0202bc0 <buddy_pmm_manager+0x80>
ffffffffc02014f0:	c5dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02014f4:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02014f8:	864e                	mv	a2,s3
ffffffffc02014fa:	fffa0693          	addi	a3,s4,-1 # ffffffffc05fffff <end+0x3f9f77>
ffffffffc02014fe:	85ca                	mv	a1,s2
ffffffffc0201500:	00001517          	auipc	a0,0x1
ffffffffc0201504:	6d850513          	addi	a0,a0,1752 # ffffffffc0202bd8 <buddy_pmm_manager+0x98>
ffffffffc0201508:	c45fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020150c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201510:	8652                	mv	a2,s4
ffffffffc0201512:	0d47e463          	bltu	a5,s4,ffffffffc02015da <pmm_init+0x144>
ffffffffc0201516:	00006797          	auipc	a5,0x6
ffffffffc020151a:	b7178793          	addi	a5,a5,-1167 # ffffffffc0207087 <end+0xfff>
ffffffffc020151e:	757d                	lui	a0,0xfffff
ffffffffc0201520:	8d7d                	and	a0,a0,a5
ffffffffc0201522:	8231                	srli	a2,a2,0xc
ffffffffc0201524:	00005797          	auipc	a5,0x5
ffffffffc0201528:	b2c7ba23          	sd	a2,-1228(a5) # ffffffffc0206058 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020152c:	00005797          	auipc	a5,0x5
ffffffffc0201530:	b2a7ba23          	sd	a0,-1228(a5) # ffffffffc0206060 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201534:	000807b7          	lui	a5,0x80
ffffffffc0201538:	002005b7          	lui	a1,0x200
ffffffffc020153c:	02f60563          	beq	a2,a5,ffffffffc0201566 <pmm_init+0xd0>
ffffffffc0201540:	00261593          	slli	a1,a2,0x2
ffffffffc0201544:	00c586b3          	add	a3,a1,a2
ffffffffc0201548:	fec007b7          	lui	a5,0xfec00
ffffffffc020154c:	97aa                	add	a5,a5,a0
ffffffffc020154e:	068e                	slli	a3,a3,0x3
ffffffffc0201550:	96be                	add	a3,a3,a5
ffffffffc0201552:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0201554:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201556:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9fa0>
        SetPageReserved(pages + i);
ffffffffc020155a:	00176713          	ori	a4,a4,1
ffffffffc020155e:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201562:	fef699e3          	bne	a3,a5,ffffffffc0201554 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201566:	95b2                	add	a1,a1,a2
ffffffffc0201568:	fec006b7          	lui	a3,0xfec00
ffffffffc020156c:	96aa                	add	a3,a3,a0
ffffffffc020156e:	058e                	slli	a1,a1,0x3
ffffffffc0201570:	96ae                	add	a3,a3,a1
ffffffffc0201572:	c02007b7          	lui	a5,0xc0200
ffffffffc0201576:	0af6e763          	bltu	a3,a5,ffffffffc0201624 <pmm_init+0x18e>
ffffffffc020157a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020157c:	77fd                	lui	a5,0xfffff
ffffffffc020157e:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201582:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201584:	04b6ee63          	bltu	a3,a1,ffffffffc02015e0 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201588:	601c                	ld	a5,0(s0)
ffffffffc020158a:	7b9c                	ld	a5,48(a5)
ffffffffc020158c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020158e:	00001517          	auipc	a0,0x1
ffffffffc0201592:	6d250513          	addi	a0,a0,1746 # ffffffffc0202c60 <buddy_pmm_manager+0x120>
ffffffffc0201596:	bb7fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020159a:	00004597          	auipc	a1,0x4
ffffffffc020159e:	a6658593          	addi	a1,a1,-1434 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02015a2:	00005797          	auipc	a5,0x5
ffffffffc02015a6:	acb7bb23          	sd	a1,-1322(a5) # ffffffffc0206078 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02015aa:	c02007b7          	lui	a5,0xc0200
ffffffffc02015ae:	0af5e363          	bltu	a1,a5,ffffffffc0201654 <pmm_init+0x1be>
ffffffffc02015b2:	6090                	ld	a2,0(s1)
}
ffffffffc02015b4:	7402                	ld	s0,32(sp)
ffffffffc02015b6:	70a2                	ld	ra,40(sp)
ffffffffc02015b8:	64e2                	ld	s1,24(sp)
ffffffffc02015ba:	6942                	ld	s2,16(sp)
ffffffffc02015bc:	69a2                	ld	s3,8(sp)
ffffffffc02015be:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02015c0:	40c58633          	sub	a2,a1,a2
ffffffffc02015c4:	00005797          	auipc	a5,0x5
ffffffffc02015c8:	aac7b623          	sd	a2,-1364(a5) # ffffffffc0206070 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02015cc:	00001517          	auipc	a0,0x1
ffffffffc02015d0:	6b450513          	addi	a0,a0,1716 # ffffffffc0202c80 <buddy_pmm_manager+0x140>
}
ffffffffc02015d4:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02015d6:	b77fe06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02015da:	c8000637          	lui	a2,0xc8000
ffffffffc02015de:	bf25                	j	ffffffffc0201516 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02015e0:	6705                	lui	a4,0x1
ffffffffc02015e2:	177d                	addi	a4,a4,-1
ffffffffc02015e4:	96ba                	add	a3,a3,a4
ffffffffc02015e6:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02015e8:	00c6d793          	srli	a5,a3,0xc
ffffffffc02015ec:	02c7f063          	bgeu	a5,a2,ffffffffc020160c <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc02015f0:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02015f2:	fff80737          	lui	a4,0xfff80
ffffffffc02015f6:	973e                	add	a4,a4,a5
ffffffffc02015f8:	00271793          	slli	a5,a4,0x2
ffffffffc02015fc:	97ba                	add	a5,a5,a4
ffffffffc02015fe:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201600:	8d95                	sub	a1,a1,a3
ffffffffc0201602:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201604:	81b1                	srli	a1,a1,0xc
ffffffffc0201606:	953e                	add	a0,a0,a5
ffffffffc0201608:	9702                	jalr	a4
}
ffffffffc020160a:	bfbd                	j	ffffffffc0201588 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc020160c:	00001617          	auipc	a2,0x1
ffffffffc0201610:	62460613          	addi	a2,a2,1572 # ffffffffc0202c30 <buddy_pmm_manager+0xf0>
ffffffffc0201614:	06a00593          	li	a1,106
ffffffffc0201618:	00001517          	auipc	a0,0x1
ffffffffc020161c:	63850513          	addi	a0,a0,1592 # ffffffffc0202c50 <buddy_pmm_manager+0x110>
ffffffffc0201620:	ba3fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201624:	00001617          	auipc	a2,0x1
ffffffffc0201628:	5e460613          	addi	a2,a2,1508 # ffffffffc0202c08 <buddy_pmm_manager+0xc8>
ffffffffc020162c:	05f00593          	li	a1,95
ffffffffc0201630:	00001517          	auipc	a0,0x1
ffffffffc0201634:	58050513          	addi	a0,a0,1408 # ffffffffc0202bb0 <buddy_pmm_manager+0x70>
ffffffffc0201638:	b8bfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc020163c:	00001617          	auipc	a2,0x1
ffffffffc0201640:	55460613          	addi	a2,a2,1364 # ffffffffc0202b90 <buddy_pmm_manager+0x50>
ffffffffc0201644:	04700593          	li	a1,71
ffffffffc0201648:	00001517          	auipc	a0,0x1
ffffffffc020164c:	56850513          	addi	a0,a0,1384 # ffffffffc0202bb0 <buddy_pmm_manager+0x70>
ffffffffc0201650:	b73fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201654:	86ae                	mv	a3,a1
ffffffffc0201656:	00001617          	auipc	a2,0x1
ffffffffc020165a:	5b260613          	addi	a2,a2,1458 # ffffffffc0202c08 <buddy_pmm_manager+0xc8>
ffffffffc020165e:	07a00593          	li	a1,122
ffffffffc0201662:	00001517          	auipc	a0,0x1
ffffffffc0201666:	54e50513          	addi	a0,a0,1358 # ffffffffc0202bb0 <buddy_pmm_manager+0x70>
ffffffffc020166a:	b59fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020166e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020166e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201672:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201674:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201678:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020167a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020167e:	f022                	sd	s0,32(sp)
ffffffffc0201680:	ec26                	sd	s1,24(sp)
ffffffffc0201682:	e84a                	sd	s2,16(sp)
ffffffffc0201684:	f406                	sd	ra,40(sp)
ffffffffc0201686:	e44e                	sd	s3,8(sp)
ffffffffc0201688:	84aa                	mv	s1,a0
ffffffffc020168a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020168c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201690:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201692:	03067e63          	bgeu	a2,a6,ffffffffc02016ce <printnum+0x60>
ffffffffc0201696:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201698:	00805763          	blez	s0,ffffffffc02016a6 <printnum+0x38>
ffffffffc020169c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020169e:	85ca                	mv	a1,s2
ffffffffc02016a0:	854e                	mv	a0,s3
ffffffffc02016a2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02016a4:	fc65                	bnez	s0,ffffffffc020169c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02016a6:	1a02                	slli	s4,s4,0x20
ffffffffc02016a8:	00001797          	auipc	a5,0x1
ffffffffc02016ac:	61878793          	addi	a5,a5,1560 # ffffffffc0202cc0 <buddy_pmm_manager+0x180>
ffffffffc02016b0:	020a5a13          	srli	s4,s4,0x20
ffffffffc02016b4:	9a3e                	add	s4,s4,a5
}
ffffffffc02016b6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02016b8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02016bc:	70a2                	ld	ra,40(sp)
ffffffffc02016be:	69a2                	ld	s3,8(sp)
ffffffffc02016c0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02016c2:	85ca                	mv	a1,s2
ffffffffc02016c4:	87a6                	mv	a5,s1
}
ffffffffc02016c6:	6942                	ld	s2,16(sp)
ffffffffc02016c8:	64e2                	ld	s1,24(sp)
ffffffffc02016ca:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02016cc:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02016ce:	03065633          	divu	a2,a2,a6
ffffffffc02016d2:	8722                	mv	a4,s0
ffffffffc02016d4:	f9bff0ef          	jal	ra,ffffffffc020166e <printnum>
ffffffffc02016d8:	b7f9                	j	ffffffffc02016a6 <printnum+0x38>

ffffffffc02016da <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02016da:	7119                	addi	sp,sp,-128
ffffffffc02016dc:	f4a6                	sd	s1,104(sp)
ffffffffc02016de:	f0ca                	sd	s2,96(sp)
ffffffffc02016e0:	ecce                	sd	s3,88(sp)
ffffffffc02016e2:	e8d2                	sd	s4,80(sp)
ffffffffc02016e4:	e4d6                	sd	s5,72(sp)
ffffffffc02016e6:	e0da                	sd	s6,64(sp)
ffffffffc02016e8:	fc5e                	sd	s7,56(sp)
ffffffffc02016ea:	f06a                	sd	s10,32(sp)
ffffffffc02016ec:	fc86                	sd	ra,120(sp)
ffffffffc02016ee:	f8a2                	sd	s0,112(sp)
ffffffffc02016f0:	f862                	sd	s8,48(sp)
ffffffffc02016f2:	f466                	sd	s9,40(sp)
ffffffffc02016f4:	ec6e                	sd	s11,24(sp)
ffffffffc02016f6:	892a                	mv	s2,a0
ffffffffc02016f8:	84ae                	mv	s1,a1
ffffffffc02016fa:	8d32                	mv	s10,a2
ffffffffc02016fc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02016fe:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201702:	5b7d                	li	s6,-1
ffffffffc0201704:	00001a97          	auipc	s5,0x1
ffffffffc0201708:	5f0a8a93          	addi	s5,s5,1520 # ffffffffc0202cf4 <buddy_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020170c:	00001b97          	auipc	s7,0x1
ffffffffc0201710:	7c4b8b93          	addi	s7,s7,1988 # ffffffffc0202ed0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201714:	000d4503          	lbu	a0,0(s10)
ffffffffc0201718:	001d0413          	addi	s0,s10,1
ffffffffc020171c:	01350a63          	beq	a0,s3,ffffffffc0201730 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201720:	c121                	beqz	a0,ffffffffc0201760 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201722:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201724:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201726:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201728:	fff44503          	lbu	a0,-1(s0)
ffffffffc020172c:	ff351ae3          	bne	a0,s3,ffffffffc0201720 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201730:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201734:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201738:	4c81                	li	s9,0
ffffffffc020173a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020173c:	5c7d                	li	s8,-1
ffffffffc020173e:	5dfd                	li	s11,-1
ffffffffc0201740:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201744:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201746:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020174a:	0ff5f593          	zext.b	a1,a1
ffffffffc020174e:	00140d13          	addi	s10,s0,1
ffffffffc0201752:	04b56263          	bltu	a0,a1,ffffffffc0201796 <vprintfmt+0xbc>
ffffffffc0201756:	058a                	slli	a1,a1,0x2
ffffffffc0201758:	95d6                	add	a1,a1,s5
ffffffffc020175a:	4194                	lw	a3,0(a1)
ffffffffc020175c:	96d6                	add	a3,a3,s5
ffffffffc020175e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201760:	70e6                	ld	ra,120(sp)
ffffffffc0201762:	7446                	ld	s0,112(sp)
ffffffffc0201764:	74a6                	ld	s1,104(sp)
ffffffffc0201766:	7906                	ld	s2,96(sp)
ffffffffc0201768:	69e6                	ld	s3,88(sp)
ffffffffc020176a:	6a46                	ld	s4,80(sp)
ffffffffc020176c:	6aa6                	ld	s5,72(sp)
ffffffffc020176e:	6b06                	ld	s6,64(sp)
ffffffffc0201770:	7be2                	ld	s7,56(sp)
ffffffffc0201772:	7c42                	ld	s8,48(sp)
ffffffffc0201774:	7ca2                	ld	s9,40(sp)
ffffffffc0201776:	7d02                	ld	s10,32(sp)
ffffffffc0201778:	6de2                	ld	s11,24(sp)
ffffffffc020177a:	6109                	addi	sp,sp,128
ffffffffc020177c:	8082                	ret
            padc = '0';
ffffffffc020177e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201780:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201784:	846a                	mv	s0,s10
ffffffffc0201786:	00140d13          	addi	s10,s0,1
ffffffffc020178a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020178e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201792:	fcb572e3          	bgeu	a0,a1,ffffffffc0201756 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201796:	85a6                	mv	a1,s1
ffffffffc0201798:	02500513          	li	a0,37
ffffffffc020179c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020179e:	fff44783          	lbu	a5,-1(s0)
ffffffffc02017a2:	8d22                	mv	s10,s0
ffffffffc02017a4:	f73788e3          	beq	a5,s3,ffffffffc0201714 <vprintfmt+0x3a>
ffffffffc02017a8:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02017ac:	1d7d                	addi	s10,s10,-1
ffffffffc02017ae:	ff379de3          	bne	a5,s3,ffffffffc02017a8 <vprintfmt+0xce>
ffffffffc02017b2:	b78d                	j	ffffffffc0201714 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02017b4:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02017b8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017bc:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02017be:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02017c2:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02017c6:	02d86463          	bltu	a6,a3,ffffffffc02017ee <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02017ca:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02017ce:	002c169b          	slliw	a3,s8,0x2
ffffffffc02017d2:	0186873b          	addw	a4,a3,s8
ffffffffc02017d6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02017da:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02017dc:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02017e0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02017e2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02017e6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02017ea:	fed870e3          	bgeu	a6,a3,ffffffffc02017ca <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02017ee:	f40ddce3          	bgez	s11,ffffffffc0201746 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02017f2:	8de2                	mv	s11,s8
ffffffffc02017f4:	5c7d                	li	s8,-1
ffffffffc02017f6:	bf81                	j	ffffffffc0201746 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02017f8:	fffdc693          	not	a3,s11
ffffffffc02017fc:	96fd                	srai	a3,a3,0x3f
ffffffffc02017fe:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201802:	00144603          	lbu	a2,1(s0)
ffffffffc0201806:	2d81                	sext.w	s11,s11
ffffffffc0201808:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020180a:	bf35                	j	ffffffffc0201746 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020180c:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201810:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201814:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201816:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201818:	bfd9                	j	ffffffffc02017ee <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020181a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020181c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201820:	01174463          	blt	a4,a7,ffffffffc0201828 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201824:	1a088e63          	beqz	a7,ffffffffc02019e0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201828:	000a3603          	ld	a2,0(s4)
ffffffffc020182c:	46c1                	li	a3,16
ffffffffc020182e:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201830:	2781                	sext.w	a5,a5
ffffffffc0201832:	876e                	mv	a4,s11
ffffffffc0201834:	85a6                	mv	a1,s1
ffffffffc0201836:	854a                	mv	a0,s2
ffffffffc0201838:	e37ff0ef          	jal	ra,ffffffffc020166e <printnum>
            break;
ffffffffc020183c:	bde1                	j	ffffffffc0201714 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020183e:	000a2503          	lw	a0,0(s4)
ffffffffc0201842:	85a6                	mv	a1,s1
ffffffffc0201844:	0a21                	addi	s4,s4,8
ffffffffc0201846:	9902                	jalr	s2
            break;
ffffffffc0201848:	b5f1                	j	ffffffffc0201714 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020184a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020184c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201850:	01174463          	blt	a4,a7,ffffffffc0201858 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201854:	18088163          	beqz	a7,ffffffffc02019d6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201858:	000a3603          	ld	a2,0(s4)
ffffffffc020185c:	46a9                	li	a3,10
ffffffffc020185e:	8a2e                	mv	s4,a1
ffffffffc0201860:	bfc1                	j	ffffffffc0201830 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201862:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201866:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201868:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020186a:	bdf1                	j	ffffffffc0201746 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020186c:	85a6                	mv	a1,s1
ffffffffc020186e:	02500513          	li	a0,37
ffffffffc0201872:	9902                	jalr	s2
            break;
ffffffffc0201874:	b545                	j	ffffffffc0201714 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201876:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020187a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020187c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020187e:	b5e1                	j	ffffffffc0201746 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201880:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201882:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201886:	01174463          	blt	a4,a7,ffffffffc020188e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020188a:	14088163          	beqz	a7,ffffffffc02019cc <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020188e:	000a3603          	ld	a2,0(s4)
ffffffffc0201892:	46a1                	li	a3,8
ffffffffc0201894:	8a2e                	mv	s4,a1
ffffffffc0201896:	bf69                	j	ffffffffc0201830 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201898:	03000513          	li	a0,48
ffffffffc020189c:	85a6                	mv	a1,s1
ffffffffc020189e:	e03e                	sd	a5,0(sp)
ffffffffc02018a0:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02018a2:	85a6                	mv	a1,s1
ffffffffc02018a4:	07800513          	li	a0,120
ffffffffc02018a8:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02018aa:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02018ac:	6782                	ld	a5,0(sp)
ffffffffc02018ae:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02018b0:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02018b4:	bfb5                	j	ffffffffc0201830 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02018b6:	000a3403          	ld	s0,0(s4)
ffffffffc02018ba:	008a0713          	addi	a4,s4,8
ffffffffc02018be:	e03a                	sd	a4,0(sp)
ffffffffc02018c0:	14040263          	beqz	s0,ffffffffc0201a04 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02018c4:	0fb05763          	blez	s11,ffffffffc02019b2 <vprintfmt+0x2d8>
ffffffffc02018c8:	02d00693          	li	a3,45
ffffffffc02018cc:	0cd79163          	bne	a5,a3,ffffffffc020198e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018d0:	00044783          	lbu	a5,0(s0)
ffffffffc02018d4:	0007851b          	sext.w	a0,a5
ffffffffc02018d8:	cf85                	beqz	a5,ffffffffc0201910 <vprintfmt+0x236>
ffffffffc02018da:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02018de:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018e2:	000c4563          	bltz	s8,ffffffffc02018ec <vprintfmt+0x212>
ffffffffc02018e6:	3c7d                	addiw	s8,s8,-1
ffffffffc02018e8:	036c0263          	beq	s8,s6,ffffffffc020190c <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02018ec:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02018ee:	0e0c8e63          	beqz	s9,ffffffffc02019ea <vprintfmt+0x310>
ffffffffc02018f2:	3781                	addiw	a5,a5,-32
ffffffffc02018f4:	0ef47b63          	bgeu	s0,a5,ffffffffc02019ea <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02018f8:	03f00513          	li	a0,63
ffffffffc02018fc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018fe:	000a4783          	lbu	a5,0(s4)
ffffffffc0201902:	3dfd                	addiw	s11,s11,-1
ffffffffc0201904:	0a05                	addi	s4,s4,1
ffffffffc0201906:	0007851b          	sext.w	a0,a5
ffffffffc020190a:	ffe1                	bnez	a5,ffffffffc02018e2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020190c:	01b05963          	blez	s11,ffffffffc020191e <vprintfmt+0x244>
ffffffffc0201910:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201912:	85a6                	mv	a1,s1
ffffffffc0201914:	02000513          	li	a0,32
ffffffffc0201918:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020191a:	fe0d9be3          	bnez	s11,ffffffffc0201910 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020191e:	6a02                	ld	s4,0(sp)
ffffffffc0201920:	bbd5                	j	ffffffffc0201714 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201922:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201924:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201928:	01174463          	blt	a4,a7,ffffffffc0201930 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020192c:	08088d63          	beqz	a7,ffffffffc02019c6 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201930:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201934:	0a044d63          	bltz	s0,ffffffffc02019ee <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201938:	8622                	mv	a2,s0
ffffffffc020193a:	8a66                	mv	s4,s9
ffffffffc020193c:	46a9                	li	a3,10
ffffffffc020193e:	bdcd                	j	ffffffffc0201830 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201940:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201944:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201946:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201948:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020194c:	8fb5                	xor	a5,a5,a3
ffffffffc020194e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201952:	02d74163          	blt	a4,a3,ffffffffc0201974 <vprintfmt+0x29a>
ffffffffc0201956:	00369793          	slli	a5,a3,0x3
ffffffffc020195a:	97de                	add	a5,a5,s7
ffffffffc020195c:	639c                	ld	a5,0(a5)
ffffffffc020195e:	cb99                	beqz	a5,ffffffffc0201974 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201960:	86be                	mv	a3,a5
ffffffffc0201962:	00001617          	auipc	a2,0x1
ffffffffc0201966:	38e60613          	addi	a2,a2,910 # ffffffffc0202cf0 <buddy_pmm_manager+0x1b0>
ffffffffc020196a:	85a6                	mv	a1,s1
ffffffffc020196c:	854a                	mv	a0,s2
ffffffffc020196e:	0ce000ef          	jal	ra,ffffffffc0201a3c <printfmt>
ffffffffc0201972:	b34d                	j	ffffffffc0201714 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201974:	00001617          	auipc	a2,0x1
ffffffffc0201978:	36c60613          	addi	a2,a2,876 # ffffffffc0202ce0 <buddy_pmm_manager+0x1a0>
ffffffffc020197c:	85a6                	mv	a1,s1
ffffffffc020197e:	854a                	mv	a0,s2
ffffffffc0201980:	0bc000ef          	jal	ra,ffffffffc0201a3c <printfmt>
ffffffffc0201984:	bb41                	j	ffffffffc0201714 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201986:	00001417          	auipc	s0,0x1
ffffffffc020198a:	35240413          	addi	s0,s0,850 # ffffffffc0202cd8 <buddy_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020198e:	85e2                	mv	a1,s8
ffffffffc0201990:	8522                	mv	a0,s0
ffffffffc0201992:	e43e                	sd	a5,8(sp)
ffffffffc0201994:	0fc000ef          	jal	ra,ffffffffc0201a90 <strnlen>
ffffffffc0201998:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020199c:	01b05b63          	blez	s11,ffffffffc02019b2 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02019a0:	67a2                	ld	a5,8(sp)
ffffffffc02019a2:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02019a6:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02019a8:	85a6                	mv	a1,s1
ffffffffc02019aa:	8552                	mv	a0,s4
ffffffffc02019ac:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02019ae:	fe0d9ce3          	bnez	s11,ffffffffc02019a6 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02019b2:	00044783          	lbu	a5,0(s0)
ffffffffc02019b6:	00140a13          	addi	s4,s0,1
ffffffffc02019ba:	0007851b          	sext.w	a0,a5
ffffffffc02019be:	d3a5                	beqz	a5,ffffffffc020191e <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02019c0:	05e00413          	li	s0,94
ffffffffc02019c4:	bf39                	j	ffffffffc02018e2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02019c6:	000a2403          	lw	s0,0(s4)
ffffffffc02019ca:	b7ad                	j	ffffffffc0201934 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02019cc:	000a6603          	lwu	a2,0(s4)
ffffffffc02019d0:	46a1                	li	a3,8
ffffffffc02019d2:	8a2e                	mv	s4,a1
ffffffffc02019d4:	bdb1                	j	ffffffffc0201830 <vprintfmt+0x156>
ffffffffc02019d6:	000a6603          	lwu	a2,0(s4)
ffffffffc02019da:	46a9                	li	a3,10
ffffffffc02019dc:	8a2e                	mv	s4,a1
ffffffffc02019de:	bd89                	j	ffffffffc0201830 <vprintfmt+0x156>
ffffffffc02019e0:	000a6603          	lwu	a2,0(s4)
ffffffffc02019e4:	46c1                	li	a3,16
ffffffffc02019e6:	8a2e                	mv	s4,a1
ffffffffc02019e8:	b5a1                	j	ffffffffc0201830 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02019ea:	9902                	jalr	s2
ffffffffc02019ec:	bf09                	j	ffffffffc02018fe <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02019ee:	85a6                	mv	a1,s1
ffffffffc02019f0:	02d00513          	li	a0,45
ffffffffc02019f4:	e03e                	sd	a5,0(sp)
ffffffffc02019f6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02019f8:	6782                	ld	a5,0(sp)
ffffffffc02019fa:	8a66                	mv	s4,s9
ffffffffc02019fc:	40800633          	neg	a2,s0
ffffffffc0201a00:	46a9                	li	a3,10
ffffffffc0201a02:	b53d                	j	ffffffffc0201830 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201a04:	03b05163          	blez	s11,ffffffffc0201a26 <vprintfmt+0x34c>
ffffffffc0201a08:	02d00693          	li	a3,45
ffffffffc0201a0c:	f6d79de3          	bne	a5,a3,ffffffffc0201986 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201a10:	00001417          	auipc	s0,0x1
ffffffffc0201a14:	2c840413          	addi	s0,s0,712 # ffffffffc0202cd8 <buddy_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201a18:	02800793          	li	a5,40
ffffffffc0201a1c:	02800513          	li	a0,40
ffffffffc0201a20:	00140a13          	addi	s4,s0,1
ffffffffc0201a24:	bd6d                	j	ffffffffc02018de <vprintfmt+0x204>
ffffffffc0201a26:	00001a17          	auipc	s4,0x1
ffffffffc0201a2a:	2b3a0a13          	addi	s4,s4,691 # ffffffffc0202cd9 <buddy_pmm_manager+0x199>
ffffffffc0201a2e:	02800513          	li	a0,40
ffffffffc0201a32:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201a36:	05e00413          	li	s0,94
ffffffffc0201a3a:	b565                	j	ffffffffc02018e2 <vprintfmt+0x208>

ffffffffc0201a3c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a3c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201a3e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a42:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a44:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201a46:	ec06                	sd	ra,24(sp)
ffffffffc0201a48:	f83a                	sd	a4,48(sp)
ffffffffc0201a4a:	fc3e                	sd	a5,56(sp)
ffffffffc0201a4c:	e0c2                	sd	a6,64(sp)
ffffffffc0201a4e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201a50:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201a52:	c89ff0ef          	jal	ra,ffffffffc02016da <vprintfmt>
}
ffffffffc0201a56:	60e2                	ld	ra,24(sp)
ffffffffc0201a58:	6161                	addi	sp,sp,80
ffffffffc0201a5a:	8082                	ret

ffffffffc0201a5c <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201a5c:	4781                	li	a5,0
ffffffffc0201a5e:	00004717          	auipc	a4,0x4
ffffffffc0201a62:	5b273703          	ld	a4,1458(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201a66:	88ba                	mv	a7,a4
ffffffffc0201a68:	852a                	mv	a0,a0
ffffffffc0201a6a:	85be                	mv	a1,a5
ffffffffc0201a6c:	863e                	mv	a2,a5
ffffffffc0201a6e:	00000073          	ecall
ffffffffc0201a72:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201a74:	8082                	ret

ffffffffc0201a76 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201a76:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201a7a:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201a7c:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201a7e:	cb81                	beqz	a5,ffffffffc0201a8e <strlen+0x18>
        cnt ++;
ffffffffc0201a80:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201a82:	00a707b3          	add	a5,a4,a0
ffffffffc0201a86:	0007c783          	lbu	a5,0(a5)
ffffffffc0201a8a:	fbfd                	bnez	a5,ffffffffc0201a80 <strlen+0xa>
ffffffffc0201a8c:	8082                	ret
    }
    return cnt;
}
ffffffffc0201a8e:	8082                	ret

ffffffffc0201a90 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a90:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a92:	e589                	bnez	a1,ffffffffc0201a9c <strnlen+0xc>
ffffffffc0201a94:	a811                	j	ffffffffc0201aa8 <strnlen+0x18>
        cnt ++;
ffffffffc0201a96:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a98:	00f58863          	beq	a1,a5,ffffffffc0201aa8 <strnlen+0x18>
ffffffffc0201a9c:	00f50733          	add	a4,a0,a5
ffffffffc0201aa0:	00074703          	lbu	a4,0(a4)
ffffffffc0201aa4:	fb6d                	bnez	a4,ffffffffc0201a96 <strnlen+0x6>
ffffffffc0201aa6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201aa8:	852e                	mv	a0,a1
ffffffffc0201aaa:	8082                	ret

ffffffffc0201aac <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201aac:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ab0:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201ab4:	cb89                	beqz	a5,ffffffffc0201ac6 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201ab6:	0505                	addi	a0,a0,1
ffffffffc0201ab8:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201aba:	fee789e3          	beq	a5,a4,ffffffffc0201aac <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201abe:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ac2:	9d19                	subw	a0,a0,a4
ffffffffc0201ac4:	8082                	ret
ffffffffc0201ac6:	4501                	li	a0,0
ffffffffc0201ac8:	bfed                	j	ffffffffc0201ac2 <strcmp+0x16>

ffffffffc0201aca <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201aca:	c20d                	beqz	a2,ffffffffc0201aec <strncmp+0x22>
ffffffffc0201acc:	962e                	add	a2,a2,a1
ffffffffc0201ace:	a031                	j	ffffffffc0201ada <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201ad0:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ad2:	00e79a63          	bne	a5,a4,ffffffffc0201ae6 <strncmp+0x1c>
ffffffffc0201ad6:	00b60b63          	beq	a2,a1,ffffffffc0201aec <strncmp+0x22>
ffffffffc0201ada:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ade:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ae0:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201ae4:	f7f5                	bnez	a5,ffffffffc0201ad0 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ae6:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201aea:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201aec:	4501                	li	a0,0
ffffffffc0201aee:	8082                	ret

ffffffffc0201af0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201af0:	ca01                	beqz	a2,ffffffffc0201b00 <memset+0x10>
ffffffffc0201af2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201af4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201af6:	0785                	addi	a5,a5,1
ffffffffc0201af8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201afc:	fec79de3          	bne	a5,a2,ffffffffc0201af6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201b00:	8082                	ret
