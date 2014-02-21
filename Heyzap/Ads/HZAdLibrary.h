//
//  HZAdLibrary.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/10/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HZAdModel;

@interface HZAdLibrary : NSObject

+ (instancetype) sharedLibrary;

- (HZAdModel *) peekAtAdForAdUnit: (NSString *) adUnit withTag: (NSString *) tag;
- (HZAdModel *) peekAtAdWithImpressionID: (NSString *) impressionID;
- (NSString *) peekAtImpressionIDForAdUnit: (NSString *) adUnit withTag: (NSString *) tag;

// Stack Implemention

- (HZAdModel *) popAdForAdUnit: (NSString *) adUnit andTag: (NSString *) tag;
- (void) pushAd: (HZAdModel *) ad forAdUnit: (NSString *) adUnit andTag: (NSString *) tag;
- (NSArray *) peekAtAllAds;
- (void) purgeAd: (HZAdModel *) ad;
@end
