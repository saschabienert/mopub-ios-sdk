//
//  HeyzapSDKTestAppViewController.h
//  HeyzapSDKTestApp
//
//  Created by Daniel Rhodes on 8/15/11.
//  Copyright 2011 Heyzap. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseTestAppViewController.h"
#import "HeyzapAds.h"
#import <Chartboost/Chartboost.h>

@interface SDKTestAppViewController : BaseTestAppViewController <UITextFieldDelegate>

extern NSString * const kCreativeIDTextFieldAccessibilityLabel;
extern NSString * const kShowAdButtonAccessibilityLabel;
extern NSString * const kFetchAdButtonAccessibilityLabel;
extern NSString * const kViewAccessibilityLabel;

@property (nonatomic) UITextField * adsTextField ;

- (void) logCallback:(NSString *)callbackName;
- (void) logCallback:(NSString *)callbackName withString:(NSString *)string;

- (void) otherAudioIsPlaying:(BOOL)isPlaying;

@end
