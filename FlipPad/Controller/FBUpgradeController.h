//
//  FBUpgradeController.h
//  FlipPad
//
//  Created by Manton Reece on 10/9/13.
//  Copyright (c) 2013 DigiCel, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

#define kShowUpgradeNotification @"FBShowUpgrade"
#define kFinishedUpgradeNotification @"FBFinishedUpgrade"

@interface FBUpgradeController : UIViewController <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (weak, nonatomic) IBOutlet UILabel *upgradeTitleLabel;
@property (strong) IBOutlet UIActivityIndicatorView* progressSpinner;
@property (strong) IBOutlet UIButton* buyButton;

@property (strong) SKProduct* product;
@property (strong) SKProductsRequest* productsRequest;

+ (BOOL) checkUpgrade;
+ (BOOL) isUpgraded;

- (IBAction) buy:(id)inSender;
- (IBAction) restore:(id)inSender;

@end
