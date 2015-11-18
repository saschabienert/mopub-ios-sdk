//
//  HZStorePresenter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface HZStorePresenter : NSObject

+ (instancetype) sharedInstance;

/*  Attempts to show the app store for an app with the given parameters, first with the SKStoreProductViewController, then with UIApplication's `openURL:` method.
 *
 *  Returns the `SKStoreProductViewController` if we created one.
 *  
 *  The completion block’s `result` parameter will be `YES` if the `SKStoreProductViewController` was presented, `NO` otherwise. If it’s `NO`, the `error` may contain more information on why it was not presented (and in this case, the return value may or may not be `nil`.) In all cases, we will attempt to use the `openURL:` method of `UIApplication` to open the click URL of the ad instead if the `SKStoreProductViewController` can not be shown. (This complexity is because HZNativeAd's public API accepts a completion block and promises it to reflect the completion block of the `SKStoreProductViewController`. This should be reworked when possible to return more specific information about what was shown and why.).
 *
 *  Taking this many parameters is annoying. Unfortunately, both native and normal ads need this logic, but have slight twists which makes it hard to generalize this code.
 */
- (SKStoreProductViewController *)presentAppStoreForID:(NSNumber *)appStoreID
    presentingViewController:(UIViewController *)viewController
                    delegate:(id<SKStoreProductViewControllerDelegate>)delegate
            useModalAppStore:(BOOL)useModalAppStore
                    clickURL:(NSURL *)clickURL
                impressionID:(NSString *)impressionID
                  completion:(void(^)(BOOL result, NSError *error))completion;

@end
