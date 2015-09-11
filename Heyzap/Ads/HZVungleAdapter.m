//
//  HZVungleProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZVungleAdapter.h"
#import <UIKit/UIKit.h>
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZVungleSDK.h"
#import "HZUtils.h"
#import "HeyzapMediation.h"

@interface HZVungleAdapter() <HZVungleSDKDelegate>

/**
 *  Because Vungle makes no differentiation between having an incentivized ad and having a video ad, we just store any error in a property shared between the ad types.
 */
@property (nonatomic) NSString *appID;
@property (nonatomic, strong) NSError *lastError;
@property (nonatomic) BOOL isShowingIncentivized;

@end

@implementation HZVungleAdapter

#pragma mark - Initialization

+ (instancetype)sharedAdapter
{
    static HZVungleAdapter *proxy;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[HZVungleAdapter alloc] init];
    });
    return proxy;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.forwardingDelegate = [HZAdapterDelegate new];
        self.forwardingDelegate.adapter = self;
    }
    return self;
}

- (void)loadCredentials {
    self.appID = [HZDictionaryUtils objectForKey:@"app_id" ofClass:[NSString class] dict:self.credentials];
}

#pragma mark - Adapter Protocol

- (NSError *)initializeSDK {
    RETURN_ERROR_IF_NIL(self.appID, @"app_id");
    
    HZDLog(@"Initializing Vungle with App ID: %@",self.appID);
    [[HZVungleSDK sharedSDK] startWithAppId:self.appID];
    [[HZVungleSDK sharedSDK] setDelegate:self.forwardingDelegate];
    
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZVungleSDK hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return HZNetworkVungle;
}

+ (NSString *)humanizedName
{
    return kHZAdapterVungleHumanized;
}

+ (NSString *)sdkVersion {
    return hzLookupStringConstant(@"VungleSDKVersion");
}

- (HZCreativeType) supportedCreativeTypes
{
    return HZCreativeTypeIncentivized | HZCreativeTypeVideo;
}

- (void)prefetchForCreativeType:(HZCreativeType)creativeType
{
    // Vungle autoprefetches, and incentivized == regular video on their platform.
}

- (BOOL)hasAdForCreativeType:(HZCreativeType)creativeType
{
    if(![self supportsCreativeType:creativeType]) return NO;
    
    BOOL adPlayable = NO;
    
    // in v.3.1.0 `isAdPlayable` is added, `isCachedAdAvailable` is deprecated
    if ([[HZVungleSDK sharedSDK] respondsToSelector:@selector(isAdPlayable)]) {
        adPlayable = [[HZVungleSDK sharedSDK] isAdPlayable];
        
    } else {
        adPlayable = [[HZVungleSDK sharedSDK] isCachedAdAvailable];
    }
    
    return [self supportedCreativeTypes] & creativeType && adPlayable;
}

- (NSError *)lastErrorForCreativeType:(HZCreativeType)creativeType
{
    return self.lastError;
}

- (void)clearErrorForCreativeType:(HZCreativeType)creativeType
{
    self.lastError = nil;
}

- (void)showAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options
{
    SEND_SHOW_ERROR_IF_UNSUPPORTED_CREATIVETYPE(creativeType);
    
    // setup options
    NSMutableDictionary *vungleOptions = [[NSMutableDictionary alloc] init];
    
    if (creativeType == HZCreativeTypeIncentivized) {
        self.isShowingIncentivized = YES;
        
        NSString *const incentivizedKey = [[self class] vunglePlayAdOptionKeyIncentivized];
        vungleOptions[incentivizedKey] = @1;
    }
    
    NSError *error;
    [[HZVungleSDK sharedSDK] playAd:options.viewController withOptions:vungleOptions error:&error];
    
    if (error) {
        [self.delegate adapterDidFailToShowAd:self error:error];
    }
}

#pragma mark - Vungle Delegate

/* Note: There is a bug with the Vungle SDK. `willPresentProductSheet` method gets called first and then the `vungleSDKwillCloseAdWithViewInfo` method, even though their docs state the opposite order. This made us end up calling `adapterDidDismissAd` in `willPresentProductSheet` FIRST, which prevented any further callbacks for the session to be called (i.e. the `did*CompleteAdWithTag` for incentivized ads to be called).
 * Please git blame and revert changes to the two callbacks when the bug is resolved.
 */

- (void)vungleSDKwillShowAd {
    [self.delegate adapterDidShowAd:self];
    [self.delegate adapterWillPlayAudio:self]; // adapterWillPlayAudio has to be called AFTER adapterDidShowAd
}

- (void)vungleSDKwillCloseAdWithViewInfo:(NSDictionary*)viewInfo willPresentProductSheet:(BOOL)willPresentProductSheet
{
    if (self.isShowingIncentivized) {
        
        if ([viewInfo[@"completedView"] boolValue]) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
            
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
    
    if ([viewInfo[@"didDownload"] boolValue]) {
        [self.delegate adapterWasClicked:self];
    }
    
    [self.delegate adapterDidFinishPlayingAudio:self];
    [self.delegate adapterDidDismissAd:self];
    
    self.isShowingIncentivized = NO;
}

- (void)vungleSDKwillCloseProductSheet:(id)productSheet {
    
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"VungleSDKDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

+ (NSString *)vunglePlayAdOptionKeyIncentivized {
    return @"incentivized";
}

@end
