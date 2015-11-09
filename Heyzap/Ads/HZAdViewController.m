    //
//  HZAdController.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdViewController.h"
#import "HZDevice.h"
#import <StoreKit/StoreKit.h>
#import "HZUtils.h"
#import "HZAdsManager.h"
#import "HZAdsAPIClient.h"
#import "HZStorePresenter.h"
#import "HZLabeledActivityIndicator.h"
#import "HZEnums.h"

@interface HZAdViewController()<SKStoreProductViewControllerDelegate>

@property (nonatomic) HZLabeledActivityIndicator *activityIndicator;

@property (nonatomic) BOOL statusBarHidden;

@end

@implementation HZAdViewController

- (id) initWithAd:(HZAdModel *)ad {
    self = [super init];
    if (self) {
        self.ad = ad;
        
        _activityIndicator = [[HZLabeledActivityIndicator alloc] initWithFrame:CGRectZero withBackgroundBox:YES];
        _activityIndicator.labelText = @"Loading App Store";
        _activityIndicator.fadeBackground = YES;
    }
    
    return self;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) show {
    [self showWithOptions:nil];
}

- (void) showWithOptions:(HZShowOptions *)options {
    
    self.statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    if (!options) {
        options = [HZShowOptions new];
    }

    if (!options.viewController) {
        NSLog(@"Heyzap requires a root view controller to display an ad. Set the `rootViewController` property of [UIApplication sharedApplication].keyWindow to fix this error. If you have any trouble doing this, contact support@heyzap.com");
        
        NSError *const error = [NSError errorWithDomain:@"Heyzap" code:10 userInfo:@{NSLocalizedFailureReasonErrorKey:@"There was no root view controller to display the ad."}];
        [HZAdsManager postNotificationName:kHeyzapDidFailToShowAdNotification infoProvider:self.ad userInfo:@{NSUnderlyingErrorKey: error}];
        return;
    }

    [options.viewController presentViewController:self animated:NO completion:nil];

    [[UIApplication sharedApplication] setStatusBarHidden: YES];
}

- (void) hide {    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self.ad cleanup];
    
    // Revert back to old status bar state
    [[UIApplication sharedApplication] setStatusBarHidden: self.statusBarHidden];
    
    [HZAdsManager postNotificationName:kHeyzapDidHideAdNotification infoProvider:self.ad];
}

- (void) didClickHeyzapInstall {
    
}

- (void) didImpression {
    if ([self.ad onImpression]) {
        [HZAdsManager postNotificationName:kHeyzapDidShowAdNotitification infoProvider:self.ad];
    }
}

- (void)didClickWithURL:(NSURL *)url {
    
    [self.ad onClick];
    [HZAdsManager postNotificationName:kHeyzapDidClickAdNotification infoProvider:self.ad];
    
    NSDictionary *queryDictionary = [HZUtils hzQueryDictionaryFromURL: url];
    
    NSURL *clickURL;
    id urlString = [queryDictionary objectForKey:@"click_url"];
    if (urlString) {
        clickURL = [NSURL URLWithString:urlString];
    } else {
        clickURL = self.ad.clickURL;
    }
    
    // start activity indicator
    if (self.ad.useModalAppStore) {
        [self.view addSubview:_activityIndicator];
        [self.view bringSubviewToFront:self.activityIndicator];
        [self.activityIndicator startAnimating];
    }
    
    __weak HZAdViewController *weakSelf = self;
    
    [[HZStorePresenter sharedInstance] presentAppStoreForID:self.ad.promotedGamePackage
                                   presentingViewController:self
                                                   delegate:self
                                           useModalAppStore:self.ad.useModalAppStore
                                                   clickURL:clickURL
                                               impressionID:self.ad.impressionID
                                                 completion:^(BOOL result, NSError *error) {
                                                     if ([[weakSelf ad] useModalAppStore]) {
                                                         [[weakSelf activityIndicator] stopAnimating];
                                                         [[weakSelf activityIndicator] removeFromSuperview];
                                                     }
                                                 }];
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Utility

- (BOOL) applicationSupportsLandscape {
    if ([HZDevice hzSystemVersionIsLessThan: @"6.0"]) {
        return YES;
    } else {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow: keyWindow] & UIInterfaceOrientationMaskLandscape;
    }
}


@end
