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

@property (nonatomic, strong) NSMutableSet *setupMediators;

NSValue * HZNSValueFromMediator(HZMediator mediator);
HZMediator HZMediatorFromNSValue(NSValue *value);
id <HZMediationAdapter> HZProxyFromHZMediator(HZMediator mediator);
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

id <HZMediationAdapter> HZProxyFromHZMediator(HZMediator mediator) {
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
    if (![HZChartboostAdapter isSDKLoaded]) {
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
   fetchTimeout:6]; // Give a longer timeout for the initial fetch
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
    // Find the first SDK that has an ad, and use it
    // This means if e.g. the first 2 networks aren't working, we don't have to wait for a timeout to get to the third.
    const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(NSValue *mediatorValue, NSUInteger idx, BOOL *stop) {
        const HZMediator mediator = HZMediatorFromNSValue(mediatorValue);
        id <HZMediationAdapter> proxy = HZProxyFromHZMediator(mediator);
        return [proxy hasAd];
    }];
    
    if (idx != NSNotFound) {
        NSLog(@"Using fast path by skipping to first network with an ad.");
        NSValue *mediatorValue = preferredMediatorList[idx];
        const HZMediator mediator = HZMediatorFromNSValue(mediatorValue);
        id <HZMediationAdapter> proxy = HZProxyFromHZMediator(mediator);
        [proxy showAd];
        return;
    }
    
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSValue *value in preferredMediatorList) {
            const HZMediator mediator = HZMediatorFromNSValue(value);
            
            __block id<HZMediationAdapter> proxy;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                proxy = HZProxyFromHZMediator(mediator);
            });
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [proxy prefetch];
            });
            
            __block BOOL fetchedWithinTimeout = NO;
            hzWaitUntil(^BOOL{
                fetchedWithinTimeout = [proxy hasAd];
                return [proxy hasAd] || proxy.lastError != nil; // If it errored, exit early.
            }, 2);
            
            if (fetchedWithinTimeout) {
                NSLog(@"We fetched within the timeout! Network = %@",NSStringFromHZMediator(mediator));
                // For just a fetch we can break now.
                if (!showImmediately) {
                    break;
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [proxy showAd];
                });
                NSLog(@"Mediator %@ is showing an ad",NSStringFromHZMediator(mediator));
                break;
                
                // Send delegate notification about showing an ad.
            } else {
                NSLog(@"The mediator with name = %@ didn't have an ad",NSStringFromHZMediator(mediator));
                // If the mediated SDK errored, reset it and try again.
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (proxy.lastError) {
                        proxy.lastError = nil;
                        [proxy prefetch];
                    }
                });
            }
        }
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

@end
