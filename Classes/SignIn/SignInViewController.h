//
//  SignInViewController.h
//  linphone
//
//  Created by lam quang quan on 2/25/19.
//

#import <UIKit/UIKit.h>
#import "UICompositeView.h"

@interface SignInViewController : UIViewController<UICompositeViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imgLogo;
@property (weak, nonatomic) IBOutlet UILabel *lbCompany;

@property (weak, nonatomic) IBOutlet UIView *viewSignIn;
@property (weak, nonatomic) IBOutlet UITextField *tfAccountID;
@property (weak, nonatomic) IBOutlet UIImageView *imgAccountID;

@property (weak, nonatomic) IBOutlet UITextField *tfPassword;
@property (weak, nonatomic) IBOutlet UIImageView *imgPassword;
@property (weak, nonatomic) IBOutlet UIButton *icShowPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnSignIn;
@property (weak, nonatomic) IBOutlet UILabel *lbForgotPassword;

@property (weak, nonatomic) IBOutlet UILabel *lbBottom;

- (IBAction)icShowPasswordPress:(UIButton *)sender;
- (IBAction)btnSignInPress:(UIButton *)sender;

@end
