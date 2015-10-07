//
//  HZClassProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@implementation HZClassProxy

+ (BOOL)hzProxiedClassIsAvailable
{
    return NSClassFromString([self hzProxiedClassName]) != nil;
}

+ (NSString *)hzProxiedClassName
{
    @throw [NSException exceptionWithName:@"AbstractMethodException"
                             reason:@"Subclasses should override this method"
                                 userInfo:nil];
}

+ (id)forwardingTargetForSelector:(SEL)aSelector
{
    return NSClassFromString([self hzProxiedClassName]);
}

+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [NSClassFromString([self hzProxiedClassName]) methodSignatureForSelector:aSelector];
}

+ (id)alloc
{
    return [NSClassFromString([self hzProxiedClassName]) alloc];
}

+ (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [NSClassFromString([self hzProxiedClassName]) respondsToSelector:aSelector];
}

@end
