//
//  HZChartboostProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZBaseAdapter.h"

@interface HZChartboostAdapter : HZBaseAdapter

- (void)setupChartboostWithAppID:(NSString *)appID appSignature:(NSString *)appSignature;

@end