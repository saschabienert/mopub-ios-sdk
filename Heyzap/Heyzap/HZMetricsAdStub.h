#import <Foundation/Foundation.h>
#import "HZMetrics.h"

@interface HZMetricsAdStub : NSObject <HZMetricsProtocol>

@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *adUnit;

- (HZMetricsAdStub *)initWithTag:(NSString *)tag adUnit:(NSString *)adUnit;

@end
