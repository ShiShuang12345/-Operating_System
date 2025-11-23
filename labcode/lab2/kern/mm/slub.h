#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>
#include <list.h>

// SLUB缓存结构
struct kmem_cache;
// SLAB页结构  
struct slab_page;

// SLUB公共接口
struct kmem_cache *kmem_cache_create(const char *name, size_t size);
void *kmem_cache_alloc(struct kmem_cache *cache);
void kmem_cache_free(struct kmem_cache *cache, void *obj);
void kmem_cache_destroy(struct kmem_cache *cache);

// 通用分配函数
void *kmalloc(size_t size);
void kfree(void *obj);

#endif /* !__KERN_MM_SLUB_H__ */