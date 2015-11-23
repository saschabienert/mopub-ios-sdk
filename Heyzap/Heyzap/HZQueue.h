//
//  NSMutableArray+HZQueueAdditions.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HZQueue<ObjectType> : NSObject

-(ObjectType) dequeue;
-(void) enqueue:(ObjectType)obj;
-(nullable ObjectType) peek:(NSUInteger)index;
-(nullable ObjectType) peekHead;
-(nullable ObjectType) peekTail;
-(BOOL) empty;
- (NSUInteger)count;

@end

NS_ASSUME_NONNULL_END