//
//  HZAdLibrary.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdLibrary.h"
#import "HZAdModel.h"
#import "HZQueue.h"
#import "HZMetrics.h"
#import "HZAdInfo.h"

@interface HZAdLibrary()
@property (nonatomic, strong) NSMutableDictionary *adDict;
@end

@implementation HZAdLibrary

#pragma mark - Initialization

+ (instancetype) sharedLibrary {
    static HZAdLibrary* sharedLibrary;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!sharedLibrary) {
            sharedLibrary = [[HZAdLibrary alloc] init];
        }
    });
    return sharedLibrary;
}

- (id) init {
    self = [super init];
    if (self) {
        _adDict = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark - Queueing Behavior

- (HZAdModel *)peekAtAdForAdUnit:(NSString *)adUnit tag:(NSString *)tag auctionType:(HZAuctionType)auctionType
{
    tag = [HZAdModel normalizeTag: tag];
    HZAdInfo *key = [[HZAdInfo alloc] initWithTag:tag adUnit:adUnit auctionType:auctionType];
    HZQueue *queue =  self.adDict[key];
    return [queue peekTail];
}

- (HZAdModel *) popAdForAdUnit:(NSString *)adUnit tag:(NSString *)tag auctionType:(HZAuctionType)auctionType {
    tag = [HZAdModel normalizeTag: tag];
    HZAdInfo *key = [[HZAdInfo alloc] initWithTag:tag adUnit:adUnit auctionType:auctionType];
    HZQueue *queue =  self.adDict[key];
    return [queue dequeue];
}

- (void) pushAd:(HZAdModel *)ad forAdUnit:(NSString *)adUnit tag:(NSString *)tag auctionType:(HZAuctionType)auctionType {
    tag = [HZAdModel normalizeTag: tag];
    HZAdInfo *key = [[HZAdInfo alloc] initWithTag:tag adUnit:adUnit auctionType:auctionType];
    
    HZQueue *const queue = ({
        HZQueue *maybeQueue = self.adDict[key];
        if (!maybeQueue) {
            self.adDict[key] = [[HZQueue alloc] init];
            maybeQueue = self.adDict[key];
        }
        maybeQueue;
    });
    
    [queue enqueue:ad];
}

- (NSArray *) peekAtAllAds {
    return [self.adDict allValues];
}

- (void) purgeAd: (HZAdModel *) ad {
    [ad cleanup];
}


@end
