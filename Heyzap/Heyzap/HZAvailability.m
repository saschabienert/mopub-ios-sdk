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

+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

@end
