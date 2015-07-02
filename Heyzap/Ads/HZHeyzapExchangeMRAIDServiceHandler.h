//
//  HZHeyzapExchangeMRAIDServiceHandler.h
//  Heyzap
//
//  Created by Monroe Ekilah on 7/1/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZMRAIDServiceDelegate.h"


@protocol HZHeyzapExchangeMRAIDServiceHandlerDelegate <NSObject>

- (void) serviceEventProcessed:(NSString *)serviceEvent willLeaveApplication:(BOOL)willLeaveApplication;

@end

/**
 Handles supported MRAID services like sending SMS messages, calls, calendar events, saving pictures, etc.
 */
@interface HZHeyzapExchangeMRAIDServiceHandler : NSObject <HZMRAIDServiceDelegate>
- (instancetype) initWithDelegate:(id<HZHeyzapExchangeMRAIDServiceHandlerDelegate>)delegate;

- (NSArray *) supportedFeatures;

@end