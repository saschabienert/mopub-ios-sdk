//
//  HZHardcodedConstantChecker.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/22/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  We sometimes need to hardcode constants because loading them at runtime doesn't always work (notably it seems to fail for Adobe Air). To make that less risky, this class checks to make sure our hardcoded constants match the ones provided by 3rd party networks.
 *
 *  Ideally this would be a test, but none of our test suites add all the mediation networks yet.
 */
@interface HZHardcodedConstantChecker : NSObject

+ (void)checkConstants;

@end
