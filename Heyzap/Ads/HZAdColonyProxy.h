//
//  HZAdColonyProxy.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/20/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZMediatorProxy.h"

@interface HZAdColonyProxy : NSObject <HZMediatorProxy>

- (void)setupAdColonyWithAppID:(NSString *)appID zoneID:(NSString *)zoneID;

@end
