//
//  HeyzapMediation.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HeyzapMediation.h"
#import "HZMediatorProxy.h"

// Proxies
#import "HZChartboostProxy.h"
#import "HZHeyzapProxy.h"
#import "HZAdColonyProxy.h"
#import "HZVungleProxy.h"
#import "HZAdMobProxy.h"
#import "HZVGVunglePub.h"


@interface HeyzapMediation()

@property (nonatomic) BOOL mediatorsAreSetup;

@property (nonatomic, strong) NSMutableSet *setupMediators;

NSValue * HZNSValueFromMediator(HZMediator mediator);
HZMediator HZMediatorFromNSValue(NSValue *value);
id <HZMediatorProxy> HZProxyFromHZMediator(HZMediator mediator);
BOOL hzWaitUntil(BOOL (^waitBlock)(void), const NSTimeInterval timeout);

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

id <HZMediatorProxy> HZProxyFromHZMediator(HZMediator mediator) {
    switch (mediator) {
        case HZMediatorHeyzap: {
            return [HZHeyzapProxy sharedInstance];
            break;
        }
        case HZMediatorChartboost: {
            return [HZChartboostProxy sharedInstance];
            break;
        }
        case HZMediatorAdColony: {
            return [HZAdColonyProxy sharedInstance];
            break;
        }
        case HZMediatorVungle: {
            return [HZVungleProxy sharedInstance];
            break;
        }
        case HZMediatorAdMob: {
            return [HZAdMobProxy sharedInstance];
            break;
        }
        default: {
            [[NSException exceptionWithName:kHZUnknownMediatiorException reason:@"Uknown HZMediator passed." userInfo:nil] raise];
        }
    }
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
    [[HZAdColonyProxy sharedInstance] setupAdColonyWithAppID:appID zoneID:zoneID];
    [self didSetupMediator:HZMediatorAdColony];
}

- (void)setupChartboostWithAppID:(NSString *)appID appSignature:(NSString *)appSignature
{
    if (![HZChartboostProxy isSDKLoaded]) {
        NSLog(@"Tried to load chartboost, but we couldn't load their SDK. Has Chartboost been added to your project?");
        return;
    }
    BOOL chartboostExists = NSClassFromString(@"Chartboost") != NULL;
    NSLog(@"Chartboost exists = %i",chartboostExists);
    
    [[HZChartboostProxy sharedInstance] setupChartboostWithAppID:appID appSignature:appSignature];
    
    [self didSetupMediator:HZMediatorChartboost];
}

- (void)setupVungleWithAppID:(NSString *)appID
{
    [HZVGVunglePub startWithPubAppID:appID];
}

- (void)finishedSettingUpMediators
{
    self.mediatorsAreSetup = YES;
    
    for (NSValue *value in self.setupMediators) {
        NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
        const HZMediator mediator = HZMediatorFromNSValue(value);
        const id<HZMediatorProxy> proxy = HZProxyFromHZMediator(mediator);
        [proxy prefetch];
    }
}

#pragma mark - Ads

- (NSArray *)preferredMediatorList
{
    return @[
             HZNSValueFromMediator(HZMediatorAdMob),
//             HZNSValueFromMediator(HZMediatorVungle),
//             HZNSValueFromMediator(HZMediatorAdColony),
//             HZNSValueFromMediator(HZMediatorHeyzap),
//             HZNSValueFromMediator(HZMediatorChartboost),
             ];
}

- (void)showAd
{
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
    for (NSValue *value in self.preferredMediatorList) {
        const HZMediator mediator = HZMediatorFromNSValue(value);
        const id<HZMediatorProxy> proxy = HZProxyFromHZMediator(mediator);
        if ([proxy hasAd]) {
            [proxy showAd];
            break;
        } else {
            NSLog(@"Didn't have ad");
        }
    }
}

- (void)showAd:(NSArray *)preferredMediatorList
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSValue *value in preferredMediatorList) {
            const HZMediator mediator = HZMediatorFromNSValue(value);

            __block id<HZMediatorProxy> proxy;
            __block BOOL isReady = NO;
            __block BOOL shouldBreak = NO;
            dispatch_sync(dispatch_get_main_queue(), ^{
                proxy = HZProxyFromHZMediator(mediator);
                isReady = [proxy hasAd];
            });
            
            if (isReady) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    shouldBreak = YES;
                    [proxy showAd];
                });
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [proxy prefetch];
                });
                const BOOL fetchedWithinTimeout = hzWaitUntil(^BOOL{
                    return [proxy hasAd];
                }, 2);
                if (fetchedWithinTimeout) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [proxy showAd];
                    });
                }
            }
        }
    });
}

- (void)showAd2:(NSArray *)preferredMediatorList tag:(NSString *)tag
{
    __block BOOL didShowAd = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSValue *value in preferredMediatorList) {
            const HZMediator mediator = HZMediatorFromNSValue(value);
            
            __block id<HZMediatorProxy> proxy;
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                proxy = HZProxyFromHZMediator(mediator);
            });
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [proxy prefetch];
            });
            
            const BOOL fetchedWithinTimeout = hzWaitUntil(^BOOL{
                return [proxy hasAd];
            }, 2);
            
            if (fetchedWithinTimeout) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [proxy showAd];
                    didShowAd = YES;
                });
                
                // Send delegate notification about showing an ad.
                // Send
            }
        }
    });
    
    if (didShowAd) {
        // did show ad with tag.
    } else {
        // did Fail to show ad with tag.
    }
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
        dispatch_async(dispatch_get_main_queue(), ^{
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
}

@end
