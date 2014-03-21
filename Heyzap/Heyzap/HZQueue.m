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
    // Set aside a reference to the object to pass back
    id queueObject = nil;
    
    // Do we have any items?
    if ([self.queue lastObject]) {
        // Pick out the first one

        queueObject = [self.queue objectAtIndex: 0];

        // Remove it from the queue
        [self.queue removeObjectAtIndex: 0];
    }
    
    // Pass back the dequeued object, if any
    return queueObject;
}

// Takes a look at an object at a given location
-(id) peek: (NSUInteger) index {
    // Set aside a reference to the peeked at object
    id peekObject = nil;
    // Do we have any items at all?
    if ([self.queue lastObject]) {
        // Is this within range?
        if (index < [self.queue count]) {
            // Get the object at this index
            peekObject = [self.queue objectAtIndex: index];
        }
    }
    
    // Pass back the peeked at object, if any
    return peekObject;
}

// Let's take a look at the next item to be dequeued
-(id) peekHead {
    // Peek at the next item
    return [self peek: 0];
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
