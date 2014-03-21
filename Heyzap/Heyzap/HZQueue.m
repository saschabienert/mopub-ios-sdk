//
//  NSMutableArray+HZQueueAdditions.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZQueue.h"

@interface HZQueue()
@property (nonatomic) NSMutableArray *queue;
@end

@implementation HZQueue

- (id) init {
    self = [super init];
    if (self) {
        _queue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

// Add to the tail of the queue
-(void) enqueue: (id) anObject {
    // Push the item in
    [self.queue addObject: anObject];
}

// Grab the next item in the queue, if there is one
-(id) dequeue {
    if ([self.queue firstObject]) {
        id first = self.queue.firstObject;
        [self.queue removeObjectAtIndex: 0];
        return first;
    } else {
        return nil;
    }
}

// Takes a look at an object at a given location
-(id) peek: (NSUInteger) index {
    if (index < [self.queue count]) {
        return [self.queue objectAtIndex: index];
    } else {
        return nil;
    }
}

// Let's take a look at the next item to be dequeued
-(id) peekHead {
    // Peek at the next item
    return [self.queue firstObject];
}

// Let's take a look at the last item to have been added to the queue
-(id) peekTail {
    // Pick out the last item
    return [self.queue lastObject];
}

// Checks if the queue is empty
-(BOOL) empty {
    return ([self.queue lastObject] == nil);
}

@end
