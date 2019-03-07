//
//  SignInViewController.h
//  linphone
//
//  Created by lam quang quan on 2/25/19.
//

#import <UIKit/UIKit.h>
#import "UICompositeView.h"
#import "QRCodeReaderDelegate.h"

@interface SignInViewController : UIViewController<UICompositeViewDelegate, QRCodeReaderDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imgLogo;
@property (weak, nonatomic) IBOutlet UILabel *lbCompany;

@property (weak, nonatomic) IBOutlet UIView *viewSignIn;
@property (weak, nonatomic) IBOutlet UITextField *tfAccountID;
@property (weak, nonatomic) IBOutlet UIButton *btnAccountID;

@property (weak, nonatomic) IBOutlet UITextField *tfPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnPassword;

@property (weak, nonatomic) IBOutlet UIButton *icShowPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnSignIn;
@property (weak, nonatomic) IBOutlet UILabel *lbForgotPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnQRCode;
- (IBAction)btnQRCodePress:(UIButton *)sender;

- (IBAction)icShowPasswordPress:(UIButton *)sender;
- (IBAction)btnSignInPress:(UIButton *)sender;

@end
