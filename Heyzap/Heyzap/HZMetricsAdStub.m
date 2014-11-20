#import <Foundation/Foundation.h>
#import "HZMetricsAdStub.h"

@implementation HZMetricsAdStub

- (HZMetricsAdStub *)initWithTag:(NSString *)tag adUnit:(NSString *)adUnit {
    NSParameterAssert(tag);
    NSParameterAssert(adUnit);
    self = [super init];
    if (self) {
        _tag = tag;
        _adUnit = adUnit;
    }
    return self;
}

@end
