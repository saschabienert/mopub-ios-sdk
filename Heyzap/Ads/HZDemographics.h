//
//  HZDemographics.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/2/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

@interface HZDemographics : NSObject

/**
 *  The user's current location.
 */
@property (nonatomic) CLLocation *location;

@end
