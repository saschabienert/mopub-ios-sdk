//
//  HeyzapMediation.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HeyzapMediation.h"
#import "HZMediationAdapter.h"

// Proxies
#import "HZChartboostAdapter.h"
#import "HZHeyzapAdapter.h"
#import "HZAdColonyAdapter.h"
#import "HZVungleAdapter.h"
#import "HZAdMobAdapter.h"
#import "HZVGVunglePub.h"
#import "MediationAPIClient.h"
#import "HZDictionaryUtils.h"
#import "HZMediationConstants.h"
#import "HZAdFetchRequest.h"
#import "HeyzapAds.h"

#define HZVideoAdUnit @"video"
#define HZVideoAdCreativeTypes @[@"video", @"interstitial_video"]

#define HZInterstitialAdCreativeTypes @[@"interstitial", @"full_screen_interstitial", @"video", @"interstitial_video"]
#define HZInterstitialAdCreativeTypesNoVideo @[@"interstitial", @"full_screen_interstitial"]
#define HZInterstitialAdUnit @"interstitial"

@interface HeyzapMediation()

@property (nonatomic, strong) NSMutableSet *setupMediators; // Make this an NSSet when we get data from the server

BOOL hzWaitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout);
HZAdType hzAdTypeFromString(NSString *adUnit);

@end

@implementation HeyzapMediation

#pragma mark -

NSString * const kHZUnknownMediatiorException = @"UnknownMediator";

+ (instancetype)sharedInstance
{
    static HeyzapMediation *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[HeyzapMediation alloc] init];
        mediator.setupMediators = [[NSMutableSet alloc] init];
    });
    
    return mediator;
}

#pragma mark - Ads

- (void)showAd
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
    
    [self mediateForAdUnit:HZInterstitialAdUnit
                       tag:nil
           showImmediately:YES
              fetchTimeout:2];
}



- (void)mediateForAdUnit:(NSString *)adUnit tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout
{
    
    HZAdFetchRequest *request = [[HZAdFetchRequest alloc] initWithCreativeTypes:HZInterstitialAdCreativeTypes
                                                                         adUnit:HZInterstitialAdUnit
                                                                            tag:[HeyzapAds defaultTagName]
                                                            andAdditionalParams:nil];
    
    [[MediationAPIClient sharedClient] get:@"mediate"
                                withParams:request.createParams
                                   success:^(NSDictionary *json) {
        // Need better error checking here.
//        NSString *fetchID = json[@"id"];
        NSArray *networks = json[@"networks"];
        
        NSMutableArray *adapters = [NSMutableArray array];
        for (NSDictionary *network in networks) {
            NSString *networkName = network[@"network"];
            Class<HZMediationAdapter> adapter = [[self class] adapterClassForName:networkName];
            if (adapter && [adapter isSDKAvailable]) {
                [adapters addObject:[adapter sharedInstance]];
            }
        }
        
                                       
        NSLog(@"Asked to mediate; showImmediately = %i, adUnit = %@, chosen adapters = %@",showImmediately, adUnit, adapters);
        NSIndexSet *indexes = [adapters indexesOfObjectsPassingTest:^BOOL(id<HZMediationAdapter> adapter, NSUInteger idx, BOOL *stop) {
            return [[self class] adapter:adapter supportsAdUnit:adUnit];
        }];
        NSArray *validSDKs = [adapters objectsAtIndexes:indexes];
                                       NSLog(@"After filtering, valid SDKs = %@",validSDKs);
                                       
        
        [self fetch:validSDKs tag:tag showImmediately:showImmediately fetchTimeout:timeout];
    } failure:^(NSError *error) {
        
        NSLog(@"Error! Failed to get the list of list of networks to mediate from Heyzap. Mediation won't be possible. Error = %@,",error);
    }];
}

- (void)fetch:(NSArray *)preferredMediatorList tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout
{
    // Should take an ad unit, and filter out SDKs that don't support that ad unit.
    
    // Find the first SDK that has an ad, and use it
    // This means if e.g. the first 2 networks aren't working, we don't have to wait for a timeout to get to the third.
    if (showImmediately) {
        const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(id<HZMediationAdapter> adapter, NSUInteger idx, BOOL *stop) {
            return [adapter hasAd];
        }];
        
        if (idx != NSNotFound) {
            NSLog(@"Using fast path by skipping to first network with an ad.");
            id <HZMediationAdapter> adapter = preferredMediatorList[idx];
            [adapter showAd];
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (id<HZMediationAdapter> adapter in preferredMediatorList) {
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [adapter prefetch];
            });
            
            __block BOOL fetchedWithinTimeout = NO;
            hzWaitUntil(^BOOL{
                fetchedWithinTimeout = [adapter hasAd];
                if (adapter.lastError) {
                    NSLog(@"There was an error w/ the fetch = %@",adapter.lastError);
                }
                return [adapter hasAd] || adapter.lastError != nil; // If it errored, exit early.
            }, 2);
            
            if (fetchedWithinTimeout) {
                NSLog(@"We fetched within the timeout! Network = %@",[[adapter class] name]);
                // Send a fetch successful message
                // For just a fetch we can break now.
                if (!showImmediately) {
                    break;
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [adapter showAd];
                });
                NSLog(@"Mediator %@ is showing an ad",[[adapter class] name]);
                break;
                
                // Send delegate notification about showing an ad.
            } else {
                NSLog(@"The mediator with name = %@ didn't have an ad",[[adapter class] name]);
                // If the mediated SDK errored, reset it and try again.
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (adapter.lastError) {
                        adapter.lastError = nil;
                        [adapter prefetch];
                    }
                });
            }
        }
        // Send a fetch failed notification, if appropriate
        // Send a show failed notification, if appropriate.
    });
    
//    if (didShowAd) {
//        // did show ad with tag.
//    } else {
//        // did Fail to show ad with tag.
//    }
}

// Did receive ad with tag -> Tag always nil (no consistent way to say what tag a fetch is for).
// Did fail to receieve ad with tag -> Tag always nil (no consistent way to say what tag a fetch is for).

// Did hide ad -> Receive callback from individual SDKs about whether

// Must not be called from the main thread—this will sleep.
BOOL hzWaitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout)
{
    NSCParameterAssert(waitBlock);
    NSCParameterAssert(timeout > 0);
    
    NSTimeInterval timeWaited = 0;
    while (true) {
        
        __block BOOL waitCondition = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            waitCondition = waitBlock();
        });
        
        if (waitCondition) {
            return YES;
        } else if (timeWaited >= timeout) {
            return NO;
        } else {
            static const NSTimeInterval sleepInterval = 0.2;
            [NSThread sleepForTimeInterval:sleepInterval];
            timeWaited += sleepInterval;
        }
    }
}

- (void)start
{
    [[MediationAPIClient sharedClient] get:@"start" withParams:nil success:^(NSDictionary *json) {
        
        NSArray *networks = [HZDictionaryUtils hzObjectForKey:@"networks" ofClass:[NSArray class] withDict:json];
        if (networks) {
            [self setupMediators:networks];
        } else {
            NSLog(@"Error! Failed to get networks from Heyzap; mediation won't be possible. `networks` was invalid");
        }
    } failure:^(NSError *error) {
        
        NSLog(@"Error! Failed to get networks from Heyzap. Mediation won't be possible. Error = %@,",error);
    }];
    // Get a list of available mediators
    // Send list to the server.
    // Get back list of enabled mediators
    // Set property of enabled mediators
    // Initialize all those mediators with credentials
        // -- need a way of validating our credentials are good. Have a class for each credential thing?
}

// Dictionary keys
NSString * const kHZAdapterKey = @"name";
NSString * const kHZDataKey = @"data";


+ (Class<HZMediationAdapter>)adapterClassForName:(NSString *)adapterName
{
    if ([adapterName isEqualToString:kHZAdapterVungle]) {
        return [HZVungleAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterChartboost]) {
        return [HZChartboostAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterAdColony]) {
        return [HZAdColonyAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterAdMob]) {
        return [HZAdMobAdapter class];
    } else if ([adapterName isEqualToString:kHZAdapterHeyzap]) {
        return [HZHeyzapAdapter class];
    } else {
        return nil;
    }
}


- (void)setupMediators:(NSArray *)mediatorJSON
{
    NSMutableSet *setupMediators = [NSMutableSet set];
    for (NSDictionary *mediator in mediatorJSON) {
        NSString *mediatorName = mediator[kHZAdapterKey];
        Class<HZMediationAdapter> mediatorClass = [[self class] adapterClassForName:mediatorName];
        NSDictionary *mediatorInfo = mediator[kHZDataKey];
        if (mediatorClass && mediatorInfo && [mediatorClass isSDKAvailable]) {
            NSError *credentialError = [mediatorClass enableWithCredentials:mediatorInfo];
            if (!credentialError) {
                [setupMediators addObject:[mediatorClass sharedInstance]];
            }
        }
    }
    self.setupMediators = setupMediators;
    NSLog(@"Setup mediators = %@",setupMediators);
    
    [self mediateForAdUnit:HZInterstitialAdUnit
                       tag:nil
           showImmediately:NO
              fetchTimeout:10];
}

+ (BOOL)adapter:(id<HZMediationAdapter>)adapter supportsAdUnit:(NSString *)adUnit
{
    return [adapter supportedAdFormats] & hzAdTypeFromString(adUnit);
}

HZAdType hzAdTypeFromString(NSString *adUnit) {
    if ([adUnit isEqualToString:@"interstitial"]) {
        return HZAdTypeInterstitial;
    } else if ([adUnit isEqualToString:@"incentivized"]) {
        return HZAdTypeIncentivized;
    } else if ([adUnit isEqualToString:@"video"]) {
        return HZAdTypeVideo;
    }
    // hmm
    abort();
}

@end
