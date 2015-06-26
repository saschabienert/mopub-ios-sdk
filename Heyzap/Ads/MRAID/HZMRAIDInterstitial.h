//
//  SKMRAIDInterstitial.h
//  MRAID
//
//  Created by Jay Tucker on 10/18/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "HZMRAIDView.h"

@class HZMRAIDInterstitial;
@protocol HZMRAIDServiceDelegate;

// A delegate for MRAIDInterstitial to handle callbacks for the interstitial lifecycle.
@protocol HZMRAIDInterstitialDelegate <NSObject>

@optional

- (void)mraidInterstitialAdReady:(HZMRAIDInterstitial *)mraidInterstitial;
- (void)mraidInterstitialAdFailed:(HZMRAIDInterstitial *)mraidInterstitial;
- (void)mraidInterstitialWillShow:(HZMRAIDInterstitial *)mraidInterstitial;
- (void)mraidInterstitialDidHide:(HZMRAIDInterstitial *)mraidInterstitial;
- (void)mraidInterstitialNavigate:(HZMRAIDInterstitial *)mraidInterstitial withURL:(NSURL *)url;

@end

// A class which handles interstitials and offers optional callbacks for its states and services (sms, tel, calendar, etc.)
@interface HZMRAIDInterstitial : NSObject

@property (nonatomic, unsafe_unretained) id<HZMRAIDInterstitialDelegate> delegate;
@property (nonatomic, unsafe_unretained) id<HZMRAIDServiceDelegate> serviceDelegate;
@property (nonatomic, unsafe_unretained, setter = setRootViewController:, getter=rootViewController) UIViewController *rootViewController;
@property (nonatomic, assign, getter = isViewable, setter = setIsViewable:) BOOL isViewable;
@property (nonatomic, copy, setter=setBackgroundColor:) UIColor *backgroundColor;

// IMPORTANT: This is the only valid initializer for an MRAIDInterstitial; -init will throw an exception
- (id)initWithSupportedFeatures:(NSArray *)features
                   withHtmlData:(NSString*)htmlData
                    withBaseURL:(NSURL*)bsURL
                       delegate:(id<HZMRAIDInterstitialDelegate>)delegate
               serviceDelegate:(id<HZMRAIDServiceDelegate>)serviceDelegate
             rootViewController:(UIViewController *)rootViewController;
- (BOOL)isAdReady;
- (void)show;

@end
