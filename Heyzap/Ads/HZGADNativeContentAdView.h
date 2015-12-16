//
//  HZGADNativeContentAdView.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@class HZGADNativeContentAd;

@interface HZGADNativeContentAdView : HZClassProxy

- (instancetype)init;

/// This property must point to the native content ad object rendered by this ad view.
@property(nonatomic, strong) HZGADNativeContentAd *nativeContentAd;

// Weak references to your ad view's asset views.
@property(nonatomic, weak) IBOutlet UIView *headlineView;
@property(nonatomic, weak) IBOutlet UIView *bodyView;
@property(nonatomic, weak) IBOutlet UIView *imageView;
@property(nonatomic, weak) IBOutlet UIView *logoView;
@property(nonatomic, weak) IBOutlet UIView *callToActionView;
@property(nonatomic, weak) IBOutlet UIView *advertiserView;

@end
