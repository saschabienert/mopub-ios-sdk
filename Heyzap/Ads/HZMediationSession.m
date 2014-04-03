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

@end

@implementation HZMediationSession
//
//- (instancetype)initWithJSON:(NSDictionary *)json setupMediators:(NSSet *)setupMediators error:(NSError **)error
//{
//    self = [super init];
//    if (self) {
//        _originalJSON = json;
//        
//        NSArray *networks = [HZDictionaryUtils objectForKey:@"networks" ofClass:[NSArray class] dict:json error:error];
//        // Check error macro for networks being nil/empty
//        
//        NSMutableOrderedSet *adapters = [NSMutableOrderedSet orderedSet];
//        for (NSDictionary *network in networks) {
//            NSString *networkName = network[@"network"];
//            Class<HZMediationAdapter> adapter = [[self class] adapterClassForName:networkName];
//            if (adapter && [adapter isSDKAvailable] && [self.setupMediators containsObject:[adapter sharedInstance]]) {
//                [adapters addObject:[adapter sharedInstance]];
//            }
//        }
//    }
//    return self;
//}

@end
