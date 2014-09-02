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

@interface HZAdLibrary()
@property (nonatomic) NSMutableDictionary *adUnitDict;
@property (nonatomic) NSMutableDictionary *adImpressionDict;
@end

@implementation HZAdLibrary

- (id) init {
    self = [super init];
    if (self) {
        self.adUnitDict = [[NSMutableDictionary alloc] init];
        self.adImpressionDict = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSString *) peekAtImpressionIDForAdUnit:(NSString *)adUnit withTag:(NSString *)tag {
    tag = [HZAdModel normalizeTag: tag];
    
    if ([self.adUnitDict objectForKey: adUnit] != nil) {
        NSMutableDictionary *adUnitDict = [self.adUnitDict objectForKey: adUnit];
        if ([adUnitDict objectForKey: tag]
            && [[adUnitDict objectForKey: tag] isKindOfClass: [HZQueue class]]) {
            HZQueue *tagAdUnitQueue = [adUnitDict objectForKey: tag];
            NSString *impressionID = [tagAdUnitQueue peekTail];
            return impressionID;
        }
    }
    
    return nil;
}

- (HZAdModel *) peekAtAdForAdUnit:(NSString *)adUnit withTag:(NSString *)tag {
    tag = [HZAdModel normalizeTag: tag];

    NSString *impressionID = [self peekAtImpressionIDForAdUnit: adUnit withTag: tag];
    if (impressionID != nil) {
        return [self peekAtAdWithImpressionID: impressionID];
    }
    
    return nil;
}

- (HZAdModel *) peekAtAdWithImpressionID:(NSString *)impressionID {
    HZAdModel *ad = [self.adImpressionDict objectForKey: impressionID];
    return ad;
}

- (HZAdModel *) popAdForAdUnit:(NSString *)adUnit andTag:(NSString *)tag {
    tag = [HZAdModel normalizeTag: tag];

    if ([self.adUnitDict objectForKey: adUnit] != nil) {
        NSMutableDictionary *adUnitDict = [self.adUnitDict objectForKey: adUnit];
        if ([adUnitDict objectForKey: tag]
            && [[adUnitDict objectForKey: tag] isKindOfClass: [HZQueue class]]) {
            HZQueue *tagAdUnitQueue = [adUnitDict objectForKey: tag];
            NSString *impressionID = [tagAdUnitQueue dequeue];
            if (impressionID != nil) {
                HZAdModel *model = [self.adImpressionDict objectForKey: impressionID];
                if (model != nil) {
                    [self.adImpressionDict removeObjectForKey: impressionID];
                    return model;
                }
            }
        }
    }
    
    return nil;
}

- (void) pushAd:(HZAdModel *)ad forAdUnit:(NSString *)adUnit andTag:(NSString *)tag {
    tag = [HZAdModel normalizeTag: tag];

    [self.adImpressionDict setObject: ad forKey: ad.impressionID];
    
    NSMutableDictionary *adUnitTags = [self.adUnitDict objectForKey: adUnit];
    if (adUnitTags == nil) {
        adUnitTags = [[NSMutableDictionary alloc] init];
    }
    
    HZQueue *tagQueue = [adUnitTags objectForKey: tag];
    if (tagQueue == nil) {
        tagQueue = [[HZQueue alloc] init];
    }
    
    [tagQueue enqueue: ad.impressionID];
    
    [adUnitTags setObject: tagQueue forKey: tag];
    [self.adUnitDict setObject: adUnitTags forKey: adUnit];
}

- (NSArray *) peekAtAllAds {
    return [self.adImpressionDict allValues];
}

- (void) purgeAd: (HZAdModel *) ad {
    [ad cleanup];
}
                     
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

@end
