//
//  HZAdInterstitialController.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZAdViewController.h"
#import "HZInterstitialAdModel.h"

@interface HZAdInterstitialViewController : HZAdViewController<HZAdPopupActionDelegate>

@property (nonatomic) HZInterstitialAdModel *ad;

- (id) initWithAd:(HZInterstitialAdModel *)ad;

@end
