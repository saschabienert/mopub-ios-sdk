//
//  HZNativeAdCollection.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZNativeAdCollection.h"
#import "HZUtils.h"
#import "HZAdsAPIClient.h"
#import "HZLog.h"
#import "HZAdsManager.h"

@interface HZNativeAdCollection()

@property (nonatomic) BOOL sentImpressions;

@end

@implementation HZNativeAdCollection

- (instancetype)initWithAds:(NSArray *)ads {
    if ([ads count] == 0) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _ads = ads;
    }
    return self;
}

- (void)reportImpressionOnAllAds {
    HZVersionCheck()

    if (self.sentImpressions) {
        return;
    }
    NSString *impressionIDs = [[self.ads valueForKey:@"impressionID"] componentsJoinedByString:@","];
    
    [[HZAdsAPIClient sharedClient] post: kHZRegisterImpressionEndpoint withParams: @{@"impression_ids": impressionIDs} success:^(id JSON) {
        self.sentImpressions = YES;
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION ERROR) %@, Error: %@", self, error]];
    }];
}

@end
