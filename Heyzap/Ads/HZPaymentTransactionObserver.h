#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface HZPaymentTransactionObserver : NSObject<SKPaymentTransactionObserver>

+(instancetype)sharedInstance;

#pragma mark - SKPaymentTransactionObserver Protocol Methods

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;


#pragma mark - IAP Purchase recording

-(void)onIAPPurchaseComplete:(NSString *)productId productName:(NSString *)productName price:(NSDecimalNumber *)price;

-(void)onIAPPurchaseComplete:(NSString *)productId productName:(NSString *)productName price:(NSDecimalNumber *)price currency:(NSString *)currency;

@end