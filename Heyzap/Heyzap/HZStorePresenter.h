//
//  HZStorePresenter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
@import StoreKit;

@interface HZStorePresenter : NSObject

+ (instancetype) sharedInstance;

// Taking this many parameters is annoying. Unfortunately, both native and normal ads need this logic, but have slight twists which makes it hard to generalize this code.
- (void)presentAppStoreForID:(NSNumber *)appStoreID
    presentingViewController:(UIViewController *)viewController
                    delegate:(id<SKStoreProductViewControllerDelegate>)delegate
            useModalAppStore:(BOOL)useModalAppStore
                    clickURL:(NSURL *)clickURL
                impressionID:(NSString *)impressionID
                  completion:(void(^)(BOOL result, NSError *error))completion;

@end
