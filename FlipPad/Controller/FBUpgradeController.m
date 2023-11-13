//
//  FBUpgradeController.m
//  FlipPad
//
//  Created by Manton Reece on 10/9/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import "FBUpgradeController.h"

#import "FBConstants.h"
//#import <Crashlytics/Crashlytics.h>

#define kUpgradedPrefKey @"UpgradeUnlimited"

@implementation FBUpgradeController

- (id) init
{
    self = [super initWithNibName:@"Upgrade" bundle:nil];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }

    return self;
}

- (void) dealloc
{
    self.productsRequest.delegate = nil;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"DigiCel FlipPad Pro";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
#if FLIPBOOK
    [self.upgradeTitleLabel setText:@"Upgrade to more features with FlipBook Pro:"];
#endif
    
    [self.buyButton setTitle:@"..." forState:UIControlStateNormal];
    [self.progressSpinner startAnimating];
    
    [self downloadProducts];
}

+ (BOOL) checkUpgrade
{
    BOOL is_upgraded = [self isUpgraded];
    if (!is_upgraded) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kHideAllPopoversNotification object:self userInfo:@{@"fromUpgradeController":[NSNumber numberWithBool:YES]}];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowUpgradeNotification object:self];
        });
    }
    
    return is_upgraded;
}

+ (BOOL) isUpgraded
{
#if DEBUG
    return YES;
#endif
    return [[NSUserDefaults standardUserDefaults] boolForKey:kUpgradedPrefKey];
}

- (void) downloadProducts
{
//    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects:@"com.digicelinc.plus", nil]];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"maccatalyst.com.digicelinc.plus"]];
#if !TARGET_OS_UIKITFORMAC
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"com.digicelinc.plus"]];
#endif
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

- (void) finishPurchased
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUpgradedPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kFinishedUpgradeNotification object:self];
    }];
}

#pragma -

- (void) cancel:(id)inSender
{
//    [Answers logCustomEventWithName:@"Upgrade Cancelled" customAttributes:@{}];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction) buy:(id)inSender
{
    if ([SKPaymentQueue canMakePayments]) {
        if (self.product) {
            [self.progressSpinner startAnimating];
            SKPayment* payment = [SKPayment paymentWithProduct:self.product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }
    else {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Purchasing disabled" message:@"You cannot pay for FlipPad while purchasing is disabled for this device." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction: okAction];
        [self presentViewController:alert animated:YES completion:nil];

    }
}

- (IBAction) restore:(id)inSender
{
    [self.progressSpinner startAnimating];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark -

- (void) productsRequest:(SKProductsRequest *)inRequest didReceiveResponse:(SKProductsResponse *)inResponse
{
    dispatch_async(dispatch_get_main_queue(), ^{
            if (inResponse.products.count > 0)
        {
            self.product = [inResponse.products objectAtIndex:0];
            NSString* price_s = [NSString stringWithFormat:@"%@%@", [self.product.priceLocale objectForKey:NSLocaleCurrencySymbol], self.product.price];
            [self.buyButton setTitle:[NSString stringWithFormat:@"Upgrade for %@", price_s] forState:UIControlStateNormal];
        }
        [self.progressSpinner stopAnimating];
    });
    
}

- (void) paymentQueue:(SKPaymentQueue *)inQueue updatedTransactions:(NSArray *)inTransactions
{
    for (SKPaymentTransaction* transaction in inTransactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressSpinner stopAnimating];
                });
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//                [Answers logCustomEventWithName:@"Upgrade Purchased" customAttributes:@{}];
                [self finishPurchased];
            }    break;
            
            case SKPaymentTransactionStateFailed: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressSpinner stopAnimating];
                });
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error restoring purchase" message:[transaction.error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                    [alert addAction: okAction];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }    break;
            default:
                break;
        }
    }
}

- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressSpinner stopAnimating];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error restoring purchase" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction: okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)inQueue
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressSpinner stopAnimating];
        [self finishPurchased];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Restore purchase completed" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction: okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

@end
