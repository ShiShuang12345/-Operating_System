#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// LAB2 EXERCISE 1: YOUR CODE
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */
static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void//初始化存放空闲块的链表
default_init(void) {
    list_init(&free_list);//，初始化一个空的双向链表free_list
    nr_free = 0;//空闲块的个数定义为0
}

static void//初始化一段连续的空闲物理内存页，并将其加入到空闲链表中
default_init_memmap(struct Page *base, size_t n) {//参数base指向一个页面结构体数组的起始地址，代表一段连续的内存页面，也就是我们需要存放的数组；后面的参数n就是我们需要进行初始化的页面数量。
    assert(n > 0);//首先，我们判定n是否大于0，目的是确定我们需要存放的页面是否不为0，如果为0就不需要存放了。
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);//将给定Page结构体指针所指向的页面的引用计数为指定的值
    }
    base->property = n;//将首个页面的property属性设置为n，也就是对应的块总数
    SetPageProperty(base);//设置页面的属性值
    nr_free += n;//更新nr_free的数量，进来几块空闲内存块，我们就加上对应的数量
    if (list_empty(&free_list)) {//判断该列表是否为空
        list_add(&free_list, &(base->page_link));//如果空闲页面链表为空，则将起始页面的链表节点添加到链表中。
    } else {
        list_entry_t* le = &free_list;//首先初始化一个指针指向我们的空闲链表头
        while ((le = list_next(le)) != &free_list) {//一直往后找，找到了合适的位置，也就是地址大小按照顺序排列
            struct Page* page = le2page(le, page_link);
            if (base < page) {//在链表中找到第一个地址大于base的页面，如果找到了就在该页面之前插入新的链表节点(使用list_add_before函数)
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {//；如果遍历完链表也没有找到这样的页面，则将新的链表节点添加到链表末尾(使用list_add函数)
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *//内存分配函数，用于从空闲链表中分配指定数量（n）的连续内存页。如果剩余空闲内存块大小多于所需的内存区块大小，则从链表中查找大小超过所需大小的页，并更新该页剩余的大小。
default_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {//检查系统是否有足够空闲页。若不足，返回 NULL。
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {//首次适应算法​​：遍历链表，找到第一个 property（空闲页数）≥ n的块。若找到，记录到 page并跳出循环。
        struct Page *p = le2page(le, page_link);//​​le2page​​：通过链表节点地址 le计算出所属 Page结构体的地址（利用 page_link字段在结构体中的偏移）
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));//将选中的页块从空闲链表移除
        if (page->property > n) {// 若块大小 > n，分割剩余部分
            struct Page *p = page + n;// 计算剩余块的起始地址
            p->property = page->property - n;// 设置剩余块大小
            SetPageProperty(p);// 标记剩余块为空闲
            list_add(prev, &(p->page_link));// 将剩余块插入原位置
        }
        nr_free -= n;// 更新全局空闲页计数
        ClearPageProperty(page);// 标记分配块为已占用
    }
    return page;
}

static void//释放从 base开始的连续 n个物理页，合并相邻空闲块
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));//检查页既非保留页(PageReserved)也非空闲块起始页(PageProperty)
        p->flags = 0;//重置页标志(flags = 0)
        set_page_ref(p, 0);//清除引用计数(set_page_ref(p, 0))
    }
    base->property = n;//设置起始页的 property为块大小 n
    SetPageProperty(base);//SetPageProperty(base)标记该页是空闲块起始页
    nr_free += n;//​​更新全局计数​​：nr_free += n增加空闲页总数
//插入空闲链表（按地址排序）​
    if (list_empty(&free_list)) {//链表为空​​：直接插入
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {// 按地址升序插入
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {// 插入末尾
                list_add(le, &(base->page_link));
            }
        }
    }
//向前合并（与低地址块合并）​
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {//检查是否相邻，前一个块的结束地址(p + p->property)是否等于当前块起始地址(base)
            p->property += base->property;// 合并大小
            ClearPageProperty(base);// 清除起始页标记
            list_del(&(base->page_link));// 移除当前块
            base = p;// 指向合并后的块
        }
    }
//向后合并（与高地址块合并）​
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {// 检查是否相邻
            base->property += p->property;// 合并大小
            ClearPageProperty(p);// 清除后继块标记
            list_del(&(p->page_link));// 移除后继块
        }
    }
}

static size_t//获取系统中当前空闲物理页的总数
default_nr_free_pages(void) {
    return nr_free;
}

static void////针对内存管理子系统的单元测试函数，用于验证物理页分配和释放的基本功能。
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void//针对内存管理子系统的高级单元测试函数，用于验证更复杂的物理页分配和释放场景，特别是空闲块合并功能
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
}
//物理内存管理器(pmm_manager)的接口实现结构体，定义了内存管理子系统的核心操作接口
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};

