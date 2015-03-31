//
//  HZShowOptions.m
//  Heyzap
//
//  Created by Mike Urbach on 3/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZShowOptions.h"
#import "HZAdModel.h"

@implementation HZShowOptions

- (HZShowOptions *)copyWithZone:(NSZone *)zone {
    HZShowOptions *options = [[[self class] allocWithZone:zone] init];
    [options setTag:[self tag]];
    [options setViewController:[self viewController]];
    return options;
}

@synthesize tag = _tag;

- (NSString *)tag {
    if (_tag == nil) {
        _tag = [HeyzapAds defaultTagName];
    }

    return _tag;
}

- (void)setTag:(NSString *)tag {
    _tag = [HZAdModel normalizeTag:tag];
}

- (UIViewController *)viewController {
    if (_viewController == nil) {
        _viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    }

    return _viewController;
}

@end