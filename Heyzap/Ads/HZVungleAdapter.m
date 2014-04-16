//
//  HZVungleProxy.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZVungleAdapter.h"
#import "HZVGVunglePub.h"
#import <UIKit/UIKit.h>
#import "HZVGStatusData.h"
#import "HZMediationConstants.h"
#import "HZDictionaryUtils.h"
#import "HZVGPlayData.h"

@interface HZVungleAdapter() <HZVGVunglePubDelegate>

/**
 *  Because Vungle makes no differentiation between having an incentivized ad and having a video ad, we just store any error in a property shared between the ad types.
 */
@property (nonatomic, strong) NSError *lastError;

@end

@implementation HZVungleAdapter

#pragma mark - Initialization

+ (instancetype)sharedInstance
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
        [HZVGVunglePub setDelegate:self];
    }
    return self;
}

#pragma mark - Adapter Protocol

+ (NSError *)enableWithCredentials:(NSDictionary *)credentials
{
    NSParameterAssert(credentials);
    NSError *error;
    NSString *const appID = [HZDictionaryUtils objectForKey:@"app_id" ofClass:[NSString class] dict:credentials error:&error];
    CHECK_CREDENTIALS_ERROR(error);
    
    [[self sharedInstance] startWithPubAppID:appID];
    
    return nil;
}

+ (BOOL)isSDKAvailable
{
    return [HZVGVunglePub hzProxiedClassIsAvailable]
    && [HZVGStatusData hzProxiedClassIsAvailable]
    && [HZVGPlayData hzProxiedClassIsAvailable];
}

+ (NSString *)name
{
    return kHZAdapterVungle;
}

- (void)startWithPubAppID:(NSString *)appID
{
    NSLog(@"Starting vungle!");
    [HZVGVunglePub startWithPubAppID:appID];
}

- (HZAdType)supportedAdFormats
{
    return HZAdTypeIncentivized | HZAdTypeVideo;
}

- (void)prefetchForType:(HZAdType)type tag:(NSString *)tag
{
    // Vungle autoprefetches, and incentivized == regular video on their platform.
}

- (BOOL)hasAdForType:(HZAdType)type tag:(NSString *)tag
{
    return [self supportedAdFormats] & type && [HZVGVunglePub adIsAvailable];
}

- (NSError *)lastErrorForAdType:(HZAdType)adType
{
    return self.lastError;
}

- (void)clearErrorForAdType:(HZAdType)adType
{
    self.lastError = nil;
}

- (void)showAdForType:(HZAdType)type tag:(NSString *)tag
{
    NSLog(@"Showing ad for vungle");
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    if (type == HZAdTypeVideo) {
        NSLog(@"Showing video ad");
        [HZVGVunglePub playModalAd:vc animated:YES];
    } else if (type == HZAdTypeIncentivized) {
        NSLog(@"Showing incentivized");
        [HZVGVunglePub playIncentivizedAd:vc animated:YES showClose:YES userTag:nil];
    }
}

#pragma mark - Vungle Delegate

- (void)vungleStatusUpdate:(HZVGStatusData *)statusData
{
    if (statusData.status != HZVGStatusOkay) {
        self.lastError = [NSError errorWithDomain:kHZMediationDomain code:1 userInfo:@{kHZMediatorNameKey: @"Vungle"}];
    } else {
        self.lastError = nil;
    }
}

- (void)vungleMoviePlayed:(HZVGPlayData*)playData
{
    // Check if incentivized, if so send the incentivized callback.
    const BOOL incentivized = YES;
    if (incentivized) {
        if ([playData playedFull]) {
            [self.delegate adapterDidCompleteIncentivizedAd:self];
        } else {
            [self.delegate adapterDidFailToCompleteIncentivizedAd:self];
        }
    }
}

- (void)vungleViewDidDisappear:(UIViewController*)viewController willShowProductView:(BOOL)willShow
{
    // Use this callback to say that we're dismissing the ad.
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
    [self.delegate adapterDidDismissAd:self];
}
- (void)vungleViewWillAppear:(UIViewController*)viewController
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}
- (void)vungleAppStoreWillAppear
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}
- (void)vungleAppStoreViewDidDisappear
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"VGVunglePubDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

@end
