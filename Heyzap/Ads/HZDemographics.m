//
//  HZDemographics.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/2/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZDemographics_Private.h"

NSString * const HZDemographicsUpdatedLocation = @"HZDemographicsUpdatedLocation";

@implementation HZDemographics

- (void)setLocation:(CLLocation *)location {
    _location = location;
    [[NSNotificationCenter defaultCenter] postNotificationName:HZDemographicsUpdatedLocation object:self];
}

@end
