//
//  HZHeyzapExchangeAdapter.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/25/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

@interface HZHeyzapExchangeAdapter : HZBaseAdapter
- (NSNumber *) adScoreForAdType:(HZAdType)adType;
- (void) setAllMediationScoresForReadyAds;
@end
