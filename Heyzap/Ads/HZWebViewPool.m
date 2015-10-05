//
//  HZWebViewPool.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/24/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZWebViewPool.h"


@interface HZWebViewPool()

@property (nonatomic) NSMutableArray<UIWebView *> *pool;

@end

@implementation HZWebViewPool

+ (instancetype)sharedPool {
    static HZWebViewPool *pool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [[HZWebViewPool alloc] init];
    });
    return pool;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.pool = [NSMutableArray array];
    }
    return self;
}

- (void)seedWithPools:(NSUInteger)pools {
    for (NSUInteger i = 0; i < pools; i++) {
        [self.pool addObject:[[UIWebView alloc] init]];
    }
}

- (UIWebView *)checkoutPool {
    UIWebView *fromPool = [self.pool firstObject];
    if (fromPool) {
        [self.pool removeObjectAtIndex:0];
    }
    return fromPool ?: [[UIWebView alloc] init];
}

- (void)returnWebView:(UIWebView *)webView {
    webView.delegate = nil;
    [webView removeFromSuperview];
    [webView loadHTMLString:@"" baseURL:nil];
    [webView stopLoading];
    [self.pool addObject:webView];
}

- (NSUInteger)cachedPools {
    return [self.pool count];
}

@end
