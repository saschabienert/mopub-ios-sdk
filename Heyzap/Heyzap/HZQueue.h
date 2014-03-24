//
//  NSMutableArray+HZQueueAdditions.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZQueue : NSObject

-(id) dequeue;
-(void) enqueue:(id)obj;
-(id) peek:(NSUInteger)index;
-(id) peekHead;
-(id) peekTail;
-(BOOL) empty;

@end
