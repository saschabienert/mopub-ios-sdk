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

@interface HeyzapMediation()

@property (nonatomic) BOOL mediatorsAreSetup;

@property (nonatomic, strong) NSMutableSet *setupMediators; // Make this an NSSet when we get data from the server

NSValue * HZNSValueFromMediator(HZMediator mediator);
HZMediator HZMediatorFromNSValue(NSValue *value);
id <HZMediationAdapter> HZAdapterFromHZMediator(HZMediator mediator);
BOOL hzWaitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout);
NSString * NSStringFromHZMediator(HZMediator mediator);

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

#pragma mark - Enum Support

NSValue * HZNSValueFromMediator(HZMediator mediator) {
    return [NSValue valueWithBytes:&mediator objCType:@encode(HZMediator)];
}

HZMediator HZMediatorFromNSValue(NSValue *value) {
    NSCParameterAssert(value);
    HZMediator mediator;
    [value getValue:&mediator];
    return mediator;
}

id <HZMediationAdapter> HZAdapterFromHZMediator(HZMediator mediator) {
    switch (mediator) {
        case HZMediatorHeyzap: {
            return [HZHeyzapAdapter sharedInstance];
            break;
        }
        case HZMediatorChartboost: {
            return [HZChartboostAdapter sharedInstance];
            break;
        }
        case HZMediatorAdColony: {
            return [HZAdColonyAdapter sharedInstance];
            break;
        }
        case HZMediatorVungle: {
            return [HZVungleAdapter sharedInstance];
            break;
        }
        case HZMediatorAdMob: {
            return [HZAdMobAdapter sharedInstance];
            break;
        }
        default: {
            [[NSException exceptionWithName:kHZUnknownMediatiorException reason:@"Uknown HZMediator passed." userInfo:nil] raise];
        }
    }
}

NSString * NSStringFromHZMediator(HZMediator mediator) {
    switch (mediator) {
        case HZMediatorAdColony: {
            return @"Ad Colony";
            break;
        }
        case HZMediatorAdMob: {
            return @"Ad Mob";
            break;
        }
        case HZMediatorChartboost: {
            return @"Chartboost";
            break;
        }
        case HZMediatorHeyzap: {
            return @"Heyzap";
            break;
        }
        case HZMediatorVungle: {
            return @"Vungle";
            break;
        }
    }
}

+ (id<HZMediationAdapter>)mediatorFromString:(NSString *)mediator
{
    if ([mediator isEqualToString:@""]) {
        
    } else {
        
    }
    return nil;
}


#pragma mark - Mediator Setup

- (void)didSetupMediator:(HZMediator)mediator
{
    [self.setupMediators addObject:HZNSValueFromMediator(mediator)];
}

- (void)setupHeyzap
{
    [self.setupMediators addObject:HZNSValueFromMediator(HZMediatorHeyzap)];
}

- (void)setupAdMob
{
    [self.setupMediators addObject:HZNSValueFromMediator(HZMediatorAdMob)];
}

- (void)setupAdColonyWithAppID:(NSString *)appID zoneID:(NSString *)zoneID
{
    [[HZAdColonyAdapter sharedInstance] setupAdColonyWithAppID:appID zoneID:zoneID];
    [self didSetupMediator:HZMediatorAdColony];
}

- (void)setupChartboostWithAppID:(NSString *)appID appSignature:(NSString *)appSignature
{
    if (![HZChartboostAdapter isSDKAvailable]) {
        NSLog(@"Tried to load chartboost, but we couldn't load their SDK. Has Chartboost been added to your project?");
        return;
    }
    BOOL chartboostExists = NSClassFromString(@"Chartboost") != NULL;
    NSLog(@"Chartboost exists = %i",chartboostExists);
    
    [[HZChartboostAdapter sharedInstance] setupChartboostWithAppID:appID appSignature:appSignature];
    
    [self didSetupMediator:HZMediatorChartboost];
}

- (void)setupVungleWithAppID:(NSString *)appID
{
    [HZVGVunglePub startWithPubAppID:appID];
}

- (void)finishedSettingUpMediators
{
    self.mediatorsAreSetup = YES;
    
    [self fetch:[self preferredMediatorList]
            tag:nil
showImmediately:NO
   fetchTimeout:8]; // Give a longer timeout for the initial fetch
}

#pragma mark - Ads

- (NSArray *)preferredMediatorList
{
    return @[
             HZNSValueFromMediator(HZMediatorVungle),
             HZNSValueFromMediator(HZMediatorAdColony),
             HZNSValueFromMediator(HZMediatorChartboost),
             HZNSValueFromMediator(HZMediatorAdMob),
             ];
}

- (void)showAd
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
    [self fetch:[self preferredMediatorList] tag:nil showImmediately:YES fetchTimeout:2];
//    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
//    for (NSValue *value in self.preferredMediatorList) {
//        const HZMediator mediator = HZMediatorFromNSValue(value);
//        const idHZMediationAdapter proxy = HZProxyFromHZMediator(mediator);
//        if ([proxy hasAd]) {
//            [proxy showAd];
//            break;
//        } else {
//            NSLog(@"Didn't have ad");
//        }
//    }
}

- (void)fetch:(NSArray *)preferredMediatorList tag:(NSString *)tag showImmediately:(BOOL)showImmediately fetchTimeout:(NSTimeInterval)timeout
{
    // Should take an ad unit, and filter out SDKs that don't support that ad unit.
    
    // Find the first SDK that has an ad, and use it
    // This means if e.g. the first 2 networks aren't working, we don't have to wait for a timeout to get to the third.
    const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(NSValue *mediatorValue, NSUInteger idx, BOOL *stop) {
        const HZMediator mediator = HZMediatorFromNSValue(mediatorValue);
        id <HZMediationAdapter> adapter = HZAdapterFromHZMediator(mediator);
        return [adapter hasAd];
    }];
    
    if (idx != NSNotFound) {
        NSLog(@"Using fast path by skipping to first network with an ad.");
        NSValue *mediatorValue = preferredMediatorList[idx];
        const HZMediator mediator = HZMediatorFromNSValue(mediatorValue);
        id <HZMediationAdapter> adapter = HZAdapterFromHZMediator(mediator);
        [adapter showAd];
        return;
    }
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSValue *value in preferredMediatorList) {
            const HZMediator mediator = HZMediatorFromNSValue(value);
            
            __block id<HZMediationAdapter> adapter;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                adapter = HZAdapterFromHZMediator(mediator);
            });
            
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
                NSLog(@"We fetched within the timeout! Network = %@",NSStringFromHZMediator(mediator));
                // Send a fetch successful message
                // For just a fetch we can break now.
                if (!showImmediately) {
                    break;
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [adapter showAd];
                });
                NSLog(@"Mediator %@ is showing an ad",NSStringFromHZMediator(mediator));
                break;
                
                // Send delega)te notification about showing an ad.
            } else {
                NSLog(@"The mediator with name = %@ didn't have an ad",NSStringFromHZMediator(mediator));
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
    // Get a list of available mediators
    // Send list to the server.
    // Get back list of enabled mediators
    // Set property of enabled mediators
    // Initialize all those mediators with credentials
        // -- need a way of validating our credentials are good. Have a class for each credential thing?
}

// Known mediators
NSString * const kHZAdapterVungle = @"Vungle";
NSString * const kHZAdapterChartboost = @"Chartboost";
NSString * const kHZAdapterAdColony = @"AdColony";
NSString * const kHZAdapterAdMob = @"AdMob";
NSString * const kHZAdapterHeyzap = @"Heyzap";

// Dictionary keys
NSString * const kHZAdapterKey = @"name";

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

+ (NSArray *)mediatorJSON
{
    return @[
             @{kHZAdapterKey: kHZAdapterVungle},
             @{kHZAdapterKey: kHZAdapterChartboost},
             ];
}


- (void)setupMediators:(NSArray *)mediatorJSON
{
    for (NSDictionary *mediator in mediatorJSON) {
//        find class for mediator
        Class<HZMediationAdapter> mediatorClass = mediator[kHZAdapterKey];
        if (mediatorClass && [mediatorClass isSDKAvailable]) {
            // setup with credentials, check error returned.
            
        }
//
//          + Enable with credentials
//          Adapter returns YES for success, by checking the credentials
//          If successful, add the adapter to the set.
//          Becomes an NSSet when assigned to the property
    }
}

@end
