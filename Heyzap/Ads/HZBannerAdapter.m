//
//  HZBannerAdaper.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdapter.h"

#define ABSTRACT_METHOD_ERROR() @throw [NSException exceptionWithName:@"AbstractMethodException" reason:@"Subclasses should override this method" userInfo:nil];

@interface HZBannerAdapter()

@property (nonatomic, weak) NSTimer *impressionCheckerTimer;

@end

@implementation HZBannerAdapter

- (UIView *)mediatedBanner {
    ABSTRACT_METHOD_ERROR();
}

- (BOOL)isAvailable {
    ABSTRACT_METHOD_ERROR();
}

- (void)bannerWasAddedToView {
    // Override in subclass.
}

@end
