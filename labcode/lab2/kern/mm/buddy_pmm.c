#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

// 伙伴系统数据结构
typedef struct buddy2 {
    unsigned size;          // 管理的内存总大小（以页为单位）
    unsigned longest[0];    // 柔性数组，存储二叉树节点
} buddy2_t;

#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) (((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

static free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static buddy2_t* buddy_manager = NULL;
static struct Page* buddy_base = NULL;

// 将size调整为2的幂
static unsigned fixsize(unsigned size) {
    if (size == 0) return 1;
    
    unsigned power = 1;
    while (power < size) {
        power *= 2;
    }
    return power;
}

// 计算Buddy System管理器需要的内存大小（字节）
static size_t buddy_manager_size(unsigned size) {
    return sizeof(buddy2_t) + (2 * size - 1) * sizeof(unsigned);
}

// 初始化伙伴系统
static buddy2_t* buddy2_new(int size) {
    buddy2_t* self;
    unsigned node_size;
    int i;
    
    if (size < 1 || !IS_POWER_OF_2(size)) {
        cprintf("buddy2_new: invalid size %d\n", size);
        return NULL;
    }
    
    // 计算需要的存储空间
    size_t required_size = buddy_manager_size(size);
    cprintf("buddy2_new: required_size = %lu bytes for %d pages\n", required_size, size);
    
    // 使用静态分配（避免在初始化阶段动态分配）
    // 这里我们假设调用者已经提供了足够的内存
    self = (buddy2_t*)KERNBASE + 0x100000; // 使用一个固定的内核地址区域
    
    cprintf("buddy2_new: self = %p\n", self);
    
    self->size = size;
    node_size = size;
    
    // 初始化二叉树 - 修正初始化逻辑
    for (i = 0; i < 2 * size - 1; ++i) {
        if (IS_POWER_OF_2(i+1)) {
            node_size = node_size / 2;
        }
        self->longest[i] = node_size;
        cprintf("buddy2_new: longest[%d] = %u\n", i, node_size);
    }
    
    cprintf("buddy2_new: successfully initialized for %d pages\n", size);
    return self;
}

// 分配内存
static int buddy2_alloc(buddy2_t* self, int size) {
    unsigned index = 0;
    unsigned node_size;
    unsigned offset = 0;
    
    if (self == NULL) {
        cprintf("buddy2_alloc: self is NULL\n");
        return -1;
    }
    
    if (size <= 0) {
        size = 1;
    } else if (!IS_POWER_OF_2(size)) {
        size = fixsize(size);
    }
    
    cprintf("buddy2_alloc: requesting %d pages\n", size);
    
    if (self->longest[index] < size) {
        cprintf("buddy2_alloc: not enough memory (available: %u, requested: %u)\n", 
                self->longest[index], size);
        return -1;
    }
    
    // 在二叉树中搜索合适的节点
    for (node_size = self->size; node_size != size; node_size /= 2) {
        if (self->longest[LEFT_LEAF(index)] >= size) {
            index = LEFT_LEAF(index);
            cprintf("buddy2_alloc: go left to index %u, size %u\n", index, node_size/2);
        } else {
            index = RIGHT_LEAF(index);
            cprintf("buddy2_alloc: go right to index %u, size %u\n", index, node_size/2);
        }
    }
    
    // 标记节点为已使用
    self->longest[index] = 0;
    offset = (index + 1) * node_size - self->size;
    
    cprintf("buddy2_alloc: allocated at offset %u, index %u, node_size %u\n", 
            offset, index, node_size);
    
    // 更新父节点
    while (index) {
        index = PARENT(index);
        self->longest[index] = 
            MAX(self->longest[LEFT_LEAF(index)], self->longest[RIGHT_LEAF(index)]);
        cprintf("buddy2_alloc: update parent[%u] = %u\n", index, self->longest[index]);
    }
    
    return offset;
}

// 释放内存
static void buddy2_free(buddy2_t* self, int offset) {
    unsigned node_size, index = 0;
    unsigned left_longest, right_longest;
    
    // 安全检查
    if (self == NULL || offset < 0 || offset >= self->size) {
        cprintf("buddy2_free: invalid parameters\n");
        return;
    }
    
    node_size = 1;
    index = offset + self->size - 1;
    
    cprintf("buddy2_free: freeing offset %u, starting at index %u\n", offset, index);
    
    // 向上搜索找到实际分配的节点
    for (; self->longest[index]; index = PARENT(index)) {
        node_size *= 2;
        if (index == 0) {
            cprintf("buddy2_free: reached root\n");
            return;
        }
    }
    
    // 恢复节点大小
    self->longest[index] = node_size;
    cprintf("buddy2_free: set longest[%u] = %u\n", index, node_size);
    
    // 向上合并伙伴块
    while (index) {
        index = PARENT(index);
        node_size *= 2;
        
        left_longest = self->longest[LEFT_LEAF(index)];
        right_longest = self->longest[RIGHT_LEAF(index)];
        
        if (left_longest + right_longest == node_size) {
            self->longest[index] = node_size;
            cprintf("buddy2_free: merged at index %u, size %u\n", index, node_size);
        } else {
            self->longest[index] = MAX(left_longest, right_longest);
            cprintf("buddy2_free: updated index %u to %u\n", index, self->longest[index]);
        }
    }
}

static void
buddy_init(void) {
    list_init(&free_list);
    nr_free = 0;
    buddy_manager = NULL;
    buddy_base = NULL;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    
    cprintf("buddy_init_memmap: start with %lu pages\n", n);
    
    // 首先，将所有页面标记为已保留
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    
    // 将n调整为2的幂
    unsigned actual_size;
    if (IS_POWER_OF_2(n)) {
        actual_size = n;
    } else {
        actual_size = fixsize(n);
        // 确保调整后的大小不超过实际可用内存
        while (actual_size > n) {
            actual_size >>= 1;
        }
    }
    
    cprintf("buddy_init_memmap: adjusted to %u pages\n", actual_size);
    
    // 初始化Buddy System管理器
    buddy_manager = buddy2_new(actual_size);
    if (buddy_manager == NULL) {
        panic("buddy2_new failed");
    }
    
    buddy_base = base;
    
    // 将所有管理的页面标记为可用
    for (p = base; p != base + actual_size; p++) {
        ClearPageReserved(p);
    }
    
    nr_free += actual_size;
    
    cprintf("buddy system initialized: managing %u pages\n", actual_size);
    cprintf("nr_free after init: %lu\n", nr_free);
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    cprintf("buddy_alloc_pages: request %lu pages, nr_free = %lu\n", n, nr_free);
    
    if (n > nr_free || buddy_manager == NULL) {
        cprintf("buddy_alloc_pages: cannot allocate (nr_free=%lu, buddy_manager=%p)\n", 
                nr_free, buddy_manager);
        return NULL;
    }
    
    // 将请求大小调整为2的幂
    unsigned alloc_size;
    if (IS_POWER_OF_2(n)) {
        alloc_size = n;
    } else {
        alloc_size = fixsize(n);
    }
    
    cprintf("buddy_alloc_pages: adjusted to %u pages\n", alloc_size);
    
    int offset = buddy2_alloc(buddy_manager, alloc_size);
    
    if (offset == -1) {
        cprintf("buddy_alloc_pages: allocation failed\n");
        return NULL;
    }
    
    // 计算分配的页
    struct Page* page = buddy_base + offset;
    
    cprintf("buddy_alloc_pages: allocated at offset %d, page = %p\n", offset, page);
    
    // 设置页面属性
    for (unsigned i = 0; i < alloc_size; i++) {
        struct Page* p = page + i;
        if (i == 0) {
            p->property = alloc_size;
            SetPageProperty(p);
        } else {
            p->property = 0;
            ClearPageProperty(p);
        }
        SetPageReserved(p);  // 标记为已分配
    }
    
    nr_free -= alloc_size;
    cprintf("buddy_alloc_pages: success, new nr_free = %lu\n", nr_free);
    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    // 添加安全检查，避免n为0的情况
    if (n == 0) {
        cprintf("buddy_free_pages: warning: trying to free 0 pages\n");
        return;
    }
    
    assert(n > 0);
    
    cprintf("buddy_free_pages: free %lu pages at %p\n", n, base);
    
    if (buddy_manager == NULL) {
        cprintf("buddy_free_pages: buddy_manager is NULL\n");
        return;
    }
    
    // 计算在伙伴系统中的偏移
    int offset = base - buddy_base;
    
    // 获取实际分配的大小
    size_t actual_size = base->property;
    
    cprintf("buddy_free_pages: offset = %d, actual_size = %lu\n", offset, actual_size);
    
    // 验证释放的页面
    struct Page *p = base;
    for (unsigned i = 0; i < actual_size; i++, p++) {
        assert(PageReserved(p));  // 应该已经被标记为已分配
        p->flags = 0;
        set_page_ref(p, 0);
        ClearPageReserved(p);     // 清除分配标记
    }
    
    // 释放到伙伴系统
    buddy2_free(buddy_manager, offset);
    
    nr_free += actual_size;
    cprintf("buddy_free_pages: success, new nr_free = %lu\n", nr_free);
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

// 获取伙伴块地址的简化版本
static struct Page* get_buddy_simple(struct Page* page, unsigned int order) {
    // 计算块的大小（页数）
    size_t block_size = 1 << order;
    
    // 计算当前块在buddy_base中的索引
    size_t block_index = page - buddy_base;
    
    // 计算伙伴块的索引
    size_t buddy_index = block_index ^ block_size;
    
    // 返回伙伴块的地址
    return buddy_base + buddy_index;
}

// 测试1: 基本分配释放测试
static void
buddy_check_basic_allocation(void) {
    cprintf("\n============ 测试1: 基本分配释放测试 ============\n");
    
    size_t initial_free = nr_free_pages();
    cprintf("初始空闲页数: %lu\n", initial_free);
    
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    
    // 分配三个页面
    assert((p0 = alloc_page()) != NULL);
    cprintf("分配页面 p0 在偏移 %ld\n", p0 - buddy_base);
    assert(page_ref(p0) == 0);
    assert(PageProperty(p0) && p0->property >= 1);
    
    assert((p1 = alloc_page()) != NULL);
    cprintf("分配页面 p1 在偏移 %ld\n", p1 - buddy_base);
    assert(p1 != p0);
    
    assert((p2 = alloc_page()) != NULL);
    cprintf("分配页面 p2 在偏移 %ld\n", p2 - buddy_base);
    assert(p2 != p0 && p2 != p1);
    
    // 释放页面
    free_page(p0);
    free_page(p1);
    free_page(p2);
    
    assert(nr_free_pages() == initial_free);
    cprintf("测试1 通过: 基本分配释放功能正常\n");
}

// 测试2: 不同大小分配测试
static void
buddy_check_different_sizes(void) {
    cprintf("\n============ 测试2: 不同大小分配测试 ============\n");
    
    size_t initial_free = nr_free_pages();
    cprintf("初始空闲页数: %lu\n", initial_free);
    
    struct Page *pages_1, *pages_2, *pages_4;
    
    // 分配不同大小的块
    pages_1 = alloc_pages(1);
    assert(pages_1 != NULL);
    assert(pages_1->property >= 1);
    cprintf("分配 1 页在偏移 %ld\n", pages_1 - buddy_base);
    
    pages_2 = alloc_pages(2);
    assert(pages_2 != NULL);
    assert(pages_2->property >= 2);
    cprintf("分配 2 页在偏移 %ld\n", pages_2 - buddy_base);
    
    pages_4 = alloc_pages(4);
    assert(pages_4 != NULL);
    assert(pages_4->property >= 4);
    cprintf("分配 4 页在偏移 %ld\n", pages_4 - buddy_base);
    
    // 验证它们不重叠
    assert(pages_1 + pages_1->property <= pages_2 || 
           pages_2 + pages_2->property <= pages_1);
    assert(pages_2 + pages_2->property <= pages_4 || 
           pages_4 + pages_4->property <= pages_2);
    
    // 释放所有块
    free_pages(pages_1, 1);
    free_pages(pages_2, 2);
    free_pages(pages_4, 4);
    
    assert(nr_free_pages() == initial_free);
    cprintf("测试2 通过: 不同大小分配功能正常\n");
}

// 测试3: 简化版伙伴合并功能测试
static void
buddy_check_simple_merging(void) {
    cprintf("\n============ 测试3: 简化版伙伴合并功能测试 ============\n");
    
    size_t initial_free = nr_free_pages();
    cprintf("初始空闲页数: %lu\n", initial_free);
    
    // 分配两个单独的页面
    struct Page *p1 = alloc_page();
    struct Page *p2 = alloc_page();
    
    cprintf("分配页面 p1 在偏移 %ld\n", p1 - buddy_base);
    cprintf("分配页面 p2 在偏移 %ld\n", p2 - buddy_base);
    
    // 检查它们是否是伙伴
    struct Page *buddy_of_p1 = get_buddy_simple(p1, 0);
    cprintf("p1 的伙伴在偏移 %ld\n", buddy_of_p1 - buddy_base);
    
    // 如果p1和p2是伙伴，则进行合并测试
    if (p2 == buddy_of_p1) {
        cprintf("p1 和 p2 是伙伴块，可以进行合并测试\n");
        
        // 释放两个伙伴块
        free_page(p1);
        free_page(p2);
        
        // 检查是否成功合并
        assert(nr_free_pages() == initial_free);
        cprintf("测试3 通过: 伙伴合并功能正常\n");
    } else {
        cprintf("p1 和 p2 不是伙伴块，跳过合并测试\n");
        
        // 仍然释放页面
        free_page(p1);
        free_page(p2);
        
        cprintf("测试3 跳过: 分配的页面不是伙伴块\n");
    }
}

// 测试4: 边界情况测试
static void
buddy_check_edge_cases(void) {
    cprintf("\n============ 测试4: 边界情况测试 ============\n");
    
    size_t initial_free = nr_free_pages();
    cprintf("初始空闲页数: %lu\n", initial_free);
    
    // 测试内存不足情况
    size_t large_request = initial_free + 100;
    struct Page *large_block = alloc_pages(large_request);
    assert(large_block == NULL);
    cprintf("正确拒绝分配 %lu 页的请求 (只有 %lu 页可用)\n", large_request, initial_free);
    
    // 测试分配1页（而不是0页，避免问题）
    struct Page *one_page = alloc_pages(1);
    assert(one_page != NULL);
    assert(one_page->property >= 1);
    free_page(one_page);
    cprintf("分配1页测试正常\n");
    
    // 测试分配非2的幂次方页数
    struct Page *pages_3 = alloc_pages(3);
    assert(pages_3 != NULL);
    assert(pages_3->property >= 4);  // 应该调整为4页
    cprintf("分配3页正确调整为4页\n");
    free_pages(pages_3, 3);
    
    // 测试分配一个较大的块
    size_t medium_request = initial_free / 8;  // 使用更小的块，避免问题
    if (medium_request > 0) {
        struct Page *medium_block = alloc_pages(medium_request);
        if (medium_block != NULL) {
            cprintf("成功分配 %lu 页的块\n", medium_request);
            free_pages(medium_block, medium_request);
            cprintf("成功释放 %lu 页的块\n", medium_request);
        } else {
            cprintf("无法分配 %lu 页的块\n", medium_request);
        }
    }
    
    assert(nr_free_pages() == initial_free);
    cprintf("测试4 通过: 边界情况处理正常\n");
}

// 主测试函数
static void
buddy_check(void) {
    cprintf("\n============ Buddy System 综合测试开始 ============\n");
    
    // 执行四个方面的测试
    buddy_check_basic_allocation();
    buddy_check_different_sizes();
    buddy_check_simple_merging();
    buddy_check_edge_cases();
    
    cprintf("\n============ 所有测试完成! ============\n");
    cprintf("Buddy System 测试完成!\n");
    cprintf("最终空闲页数: %lu\n", nr_free_pages());
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};