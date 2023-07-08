// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"
#include "stddef.h"
#define NBUC 13

struct bucket
{
  struct spinlock lock;
  struct buf head;
};

struct {
  //struct spinlock lock;
  struct buf buf[NBUF];
  struct bucket bucket[NBUC];
  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  //struct buf head;
} bcache;

void
binit(void)
{
  //struct buf *b;

  //initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  //bcache.head.prev = &bcache.head;
  //bcache.head.next = &bcache.head;
  /*for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    //b->next = bcache.head.next;
    //b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");
    //bcache.head.next->prev = b;
    //bcache.head.next = b;
  }*/
  struct buf *b;
  for(int i=0;i<NBUC;i++)
  {
    bcache.bucket[i].head.next=NULL;
    initlock(&bcache.bucket[i].lock,"bcache.bucket");
  }
  int j;
  for(int i=0;i<NBUF;i++)
  {
    j=i%NBUC;
    b=bcache.buf+i;
    b->next=bcache.bucket[j].head.next;
    bcache.bucket[j].head.next=b;
    initsleeplock(&bcache.buf[i].lock,"buffer");
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  // Is the block already cached?
  //acquire(&bcache.lock);
  /*for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }*/
  //try to find the block in its own bucket
  struct buf *b;
  int no=blockno%NBUC;
  acquire(&bcache.bucket[no].lock);
  for(b=bcache.bucket[no].head.next;b;b=b->next)
  {
    if(b->dev==dev&&b->blockno==blockno)
    {
      b->refcnt++;
      b->timestamp=ticks;
      release(&bcache.bucket[no].lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  //release(&bcache.bucket[no].lock);
  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  /*for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0) {
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }*/

  //try to recycle a block from its own bucket
  struct buf *lru=NULL;
  for(b=bcache.bucket[no].head.next;b;b=b->next)
  {
    if(b->refcnt==0)
    {
      if(!lru)
      {
        lru=b;
      }
      else if(lru->timestamp>b->timestamp)
      {
        lru=b;
      }
    }
  }
  if(lru)
  {
    lru->dev=dev;
    lru->blockno=blockno;
    lru->valid=0;
    lru->refcnt=1;
    lru->timestamp=ticks;
    release(&bcache.bucket[no].lock);
    acquiresleep(&lru->lock);
    return lru;
  }
  //try to recycle a block from other buckets
  struct buf *temp=NULL;
  int new_no=-1;
  for(int i=0;i<NBUC;i++)
  {
    if(i==no)
    continue;
    acquire(&bcache.bucket[i].lock);
    temp=bcache.bucket[i].head.next;
    for(;temp;temp=temp->next)
    {
      if(temp->refcnt==0)
      {
        if(!lru)
        {
	  lru=temp;
	  new_no=i;
	}
	else if(lru->timestamp>temp->timestamp)
        {
	  lru=temp;
	  new_no=i;
	}
      }
    }
    release(&bcache.bucket[i].lock);
  }
  if(lru)
  {
    acquire(&bcache.bucket[new_no].lock);
    for(temp=&bcache.bucket[new_no].head;temp;temp=temp->next)
    {
      if(temp->next==lru)
      {
        temp->next=temp->next->next;
	break;
      }
    }
    lru->dev=dev;
    lru->blockno=blockno;
    lru->valid=0;
    lru->refcnt=1;
    lru->timestamp=ticks;
    lru->next=bcache.bucket[no].head.next;
    bcache.bucket[no].head.next=lru;
    release(&bcache.bucket[no].lock);
    release(&bcache.bucket[new_no].lock);
    acquiresleep(&lru->lock);
    return lru;
  }
  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);
  int no=b->blockno%NBUC;
  acquire(&bcache.bucket[no].lock);
  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    /*b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;*/
    b->timestamp=ticks;
  }
  release(&bcache.bucket[no].lock);
}

void
bpin(struct buf *b) {
  //acquire(&bcache.lock);
  int no=b->blockno%NBUC;
  acquire(&bcache.bucket[no].lock);
  b->refcnt++;
  release(&bcache.bucket[no].lock);
  //release(&bcache.lock);
}

void
bunpin(struct buf *b) {
  //acquire(&bcache.lock);
  int no=b->blockno%NBUC;
  acquire(&bcache.bucket[no].lock);
  b->refcnt--;
  release(&bcache.bucket[no].lock);
  //release(&bcache.lock);
}


