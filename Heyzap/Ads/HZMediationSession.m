//
//  HZMediationSession.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZMediationSession.h"
#import "HZDictionaryUtils.h"
#import "HZBaseAdapter.h"

@interface HZMediationSession()

@property (nonatomic, strong) NSDictionary *originalJSON;

@property (nonatomic, strong) NSOrderedSet *chosenAdapters;

@property (nonatomic) HZAdType adType;
@property (nonatomic, strong) NSString *tag;

@end

@implementation HZMediationSession

- (instancetype)initWithJSON:(NSDictionary *)json setupMediators:(NSSet *)setupMediators adType:(HZAdType)adType tag:(NSString *)tag error:(NSError **)error
{
    self = [super init];
    if (self) {
        _originalJSON = json;
        _adType = adType;
        _tag = tag;
        
        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json error:error];
        // Check error macro for networks being nil/empty
        
        NSMutableOrderedSet *adapters = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *network in networks) {
            NSString *networkName = network[@"network"];
            Class adapter = [HZBaseAdapter adapterClassForName:networkName];
            if (adapter && [adapter isSDKAvailable] && [setupMediators containsObject:[adapter sharedInstance]]) {
                if ([[adapter sharedInstance] supportsAdType:adType]) {
                    [adapters addObject:[adapter sharedInstance]];
                }
                
            }
        }
        
        self.chosenAdapters = adapters;
    }
    return self;
}

- (HZBaseAdapter *)firstAdapterWithAd
{
    NSArray *preferredMediatorList = [self.chosenAdapters array];
    
    const NSUInteger idx = [preferredMediatorList indexOfObjectPassingTest:^BOOL(HZBaseAdapter *adapter, NSUInteger idx, BOOL *stop) {
        return [adapter hasAdForType:self.adType tag:self.tag];
    }];
    
    if (idx != NSNotFound) {
        return preferredMediatorList[idx];
    } else {
        return nil;
    }
}

@end
