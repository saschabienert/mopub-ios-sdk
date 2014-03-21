//
//  HeyzapMediation.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HeyzapMediation.h"
#import "Chartboost.h"
#import <AdColony/AdColony.h>
#import <vunglepub/vunglepub.h>
#import "HZMediatorProxy.h"

// Proxies
#import "HZChartboostProxy.h"
#import "HZHeyzapProxy.h"
#import "HZAdColonyProxy.h"
#import "HZVungleProxy.h"
#import "HZAdMobProxy.h"


@interface HeyzapMediation()

@property (nonatomic) BOOL mediatorsAreSetup;

@property (nonatomic, strong) NSMutableSet *setupMediators;

NSValue * HZNSValueFromMediator(HZMediator mediator);
HZMediator HZMediatorFromNSValue(NSValue *value);
id <HZMediatorProxy> HZProxyFromHZMediator(HZMediator mediator);

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
    if ([Chartboost class]) {
        NSLog(@"Chartboost exists based on class");
    } else {
        return;
    }
    BOOL chartboostExists = NSClassFromString(@"Chartboost") != NULL;
    NSLog(@"Chartboost exists = %i",chartboostExists);
    
    [Chartboost sharedChartboost].appId = appID;
    [Chartboost sharedChartboost].appSignature = appSignature;
    [[Chartboost sharedChartboost] startSession];
    
    [self didSetupMediator:HZMediatorChartboost];
}

- (void)setupVungleWithAppID:(NSString *)appID
{
    [VGVunglePub startWithPubAppID:appID];
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
             HZNSValueFromMediator(HZMediatorVungle),
             HZNSValueFromMediator(HZMediatorAdColony),
             HZNSValueFromMediator(HZMediatorHeyzap),
             HZNSValueFromMediator(HZMediatorChartboost),
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

@end
