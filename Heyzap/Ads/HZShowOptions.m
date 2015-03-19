//
//  HZShowOptions.m
//  Heyzap
//
//  Created by Mike Urbach on 3/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZShowOptions.h"

@implementation HZShowOptions

- (NSString *)tag {
    if (_tag == nil) {
        _tag = [HeyzapAds defaultTagName];
    }

    return _tag;
}

- (UIViewController *)viewController {
    if (_viewController == nil) {
        _viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    }

    return _viewController;
}

@end
