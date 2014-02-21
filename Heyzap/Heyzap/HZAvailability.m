//
//  HZAvailability.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/7/12.
//
//

#import "HZAvailability.h"
#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation HZAvailability

BOOL isRetina(void)
{
    if ([[UIScreen mainScreen] scale] >= 2.0f) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (BOOL)iPad {
    return [[HZAvailability platform] rangeOfString:@"ipad" options:NSCaseInsensitiveSearch].location != NSNotFound;
}
    
BOOL iPhone4Minus(void)
{
    NSString *platform = [[HZAvailability class] platform];
    if ([platform isEqualToString:@"iPhone1,1"])    return YES;
    if ([platform isEqualToString:@"iPhone1,2"])    return YES;
    if ([platform isEqualToString:@"iPhone2,1"])    return YES;
    if ([platform isEqualToString:@"iPhone3,1"])    return YES;
    if ([platform isEqualToString:@"iPhone3,3"])    return YES;
    if ([platform isEqualToString:@"iPhone4,1"])    return YES;
    if ([platform isEqualToString:@"iPod1,1"])      return YES;
    if ([platform isEqualToString:@"iPod2,1"])      return YES;
    if ([platform isEqualToString:@"iPod3,1"])      return YES;
    if ([platform isEqualToString:@"iPod4,1"])      return YES;
    if ([platform isEqualToString:@"iPad1,1"])      return YES;
    if ([platform isEqualToString:@"iPad2,1"])      return YES;
    if ([platform isEqualToString:@"iPad2,2"])      return YES;
    if ([platform isEqualToString:@"iPad2,3"])      return YES;
    if ([platform isEqualToString:@"i386"])         return NO;
    if ([platform isEqualToString:@"x86_64"])       return NO;
    return NO;
}

@end
