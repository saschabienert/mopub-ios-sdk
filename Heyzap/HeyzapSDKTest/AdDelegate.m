//
//  AdDelegate.m
//  Heyzap
//
//  Created by Daniel Rhodes on 5/31/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "AdDelegate.h"

@implementation AdDelegate

- (void) didReceiveAdWithTag:(NSString *)tag {
    NSLog(@"(CALLBACK) Received Ad: %@", tag);
}

- (void) didFailToReceiveAdWithTag:(NSString *)tag {
    NSLog(@"(CALLBACK) Failed to Receive Ad: %@", tag);
}

- (void) didShowAdWithTag:(NSString *)tag {
    NSLog(@"(CALLBACK) Showed: %@", tag);
}

- (void) didHideAdWithTag:(NSString *)tag {
    NSLog(@"(CALLBACK) Hid Ad: %@", tag);
}

//- (void) didFailToShowAdWithTag:(NSString *)tag andError:(NSError *)error {
//    NSLog(@"(CALLBACK) Fail to show ad: %@ error: %@", tag, error);
//}

- (void) didClickAdWithTag:(NSString *)tag {
    NSLog(@"(CALLBACK) Clicked: %@", tag);
}

- (void) didCompleteAd {
    NSLog(@"(CALLBACK) COMPLETED");
}

- (void) didFailToCompleteAd {
    NSLog(@"(CALLBACK) DID NOT COMPLETE AD");
}

@end
