//
//  HZGADRequest.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/25/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

#define GAD_SIMULATOR_ID @"Simulator"

@interface HZGADRequest : HZClassProxy

@property(nonatomic, copy) NSArray *testDevices;

+ (HZGADRequest *)request;

+ (NSString *)sdkVersion;

- (void)setLocationWithLatitude:(CGFloat)latitude
                      longitude:(CGFloat)longitude
                       accuracy:(CGFloat)accuracyInMeters;

/// [Optional] This method allows you to specify whether you would like your app to be treated as
/// child-directed for purposes of the Children’s Online Privacy Protection Act (COPPA),
/// http:///business.ftc.gov/privacy-and-security/childrens-privacy.
///
/// If you call this method with YES, you are indicating that your app should be treated as
/// child-directed for purposes of the Children’s Online Privacy Protection Act (COPPA). If you call
/// this method with NO, you are indicating that your app should not be treated as child-directed
/// for purposes of the Children’s Online Privacy Protection Act (COPPA). If you do not call this
/// method, ad requests will include no indication of how you would like your app treated with
/// respect to COPPA.
- (void)tagForChildDirectedTreatment:(BOOL)childDirectedTreatment;

@end
