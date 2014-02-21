//
//  HZAvailability.h
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import <Foundation/Foundation.h>

@interface HZAvailability : NSObject

BOOL isRetina(void);

BOOL iPhone4Minus(void);

+ (NSString *)platform;
+ (BOOL)iPad;

@end
