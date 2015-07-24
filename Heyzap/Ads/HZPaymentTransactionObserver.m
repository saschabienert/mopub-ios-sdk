#import "HZPaymentTransactionObserver.h"

#import "HZAPIClient.h"
#import "HZLog.h"
#import "HZDictionaryUtils.h"
#import "HeyzapMediation.h"

@interface HZPaymentTransactionObserver()<SKProductsRequestDelegate>

@end

@implementation HZPaymentTransactionObserver

+ (instancetype)sharedInstance
{
    static HZPaymentTransactionObserver *IAPObserver;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IAPObserver = [[HZPaymentTransactionObserver alloc] init];
    });
    
    return IAPObserver;
}

#pragma mark - SKPaymentTransactionObserver Protocol Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSMutableSet *productIds = [[NSMutableSet alloc] init];

    for (id transaction in transactions) {
        
        if ([transaction isKindOfClass:[SKPaymentTransaction class]]) {
            SKPaymentTransaction *paymentTransaction = (SKPaymentTransaction *)transaction;
            
            if (paymentTransaction.transactionState == SKPaymentTransactionStatePurchased) {
                [productIds addObject:paymentTransaction.payment.productIdentifier];
            }
        }
    }
    
    if ([productIds count]) {
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
        productsRequest.delegate = self;
        [productsRequest start];
    }
}

#pragma mark - SKProductsRequestDelegate Protocol Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *products = response.products;
    
    for (SKProduct *product in products) {
        [self onIAPPurchaseComplete:product.productIdentifier
                        productName:product.localizedTitle
                              price:product.price
                           currency:[product.priceLocale objectForKey:NSLocaleCurrencyCode]];
    }
}

#pragma mark - IAP Purchase recording

- (void)onIAPPurchaseComplete:(NSString *)productId productName:(NSString *)productName price:(NSDecimalNumber *)price {
    
    [self onIAPPurchaseComplete:productId
                    productName:productName
                          price:price
                       currency:[[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode]];
}

NSString * const kHZIAPMetricsEndPoint = @"in_game_api/metrics/iap";

- (void)onIAPPurchaseComplete:(NSString *)productId productName:(NSString *)productName price:(NSDecimalNumber *)price currency:(NSString *)currency {
    
    NSDictionary *params = @{
                             @"iap_id": productId ?: [NSNull null],
                             @"name": productName ?: [NSNull null],
                             @"price": price ?: [NSNull null],
                             @"currency_code": currency ?: [NSNull null], // It's possible for NSLocale to not have a currency code. I don't think this should happen because presumably purchased items have a currency associated with them.
                             };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        [[HZAPIClient sharedClient] POST:kHZIAPMetricsEndPoint parameters:params success:^(HZAFHTTPRequestOperation *operation, NSDictionary *json) {
            
            if ([json[@"success"] integerValue]) {
                
                [[[HeyzapMediation sharedInstance] settings] startIAPAdsTimeOut];
                [HZLog debug: [NSString stringWithFormat: @"(IAP Transaction) %@", json]];
                
            } else {
                [HZLog error: [NSString stringWithFormat: @"(Unable to Send IAP Transaction Data) %@", operation]];
            }
            
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            
            [HZLog error: [NSString stringWithFormat: @"(Unable to Send IAP Transaction Data) %@", error]];
        }];

    });
}

@end
