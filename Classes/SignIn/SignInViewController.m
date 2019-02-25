//
//  SignInViewController.m
//  linphone
//
//  Created by lam quang quan on 2/25/19.
//

#import "SignInViewController.h"

@interface SignInViewController ()

@end

@implementation SignInViewController
@synthesize imgLogo, lbCompany, viewSignIn, tfAccountID, imgAccountID, tfPassword, imgPassword, icShowPassword, btnSignIn, lbForgotPassword, lbBottom;

#pragma mark - UICompositeViewDelegate Functions
static UICompositeViewDescription *compositeDescription = nil;
+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:nil
                                                                 tabBar:nil
                                                               sideMenu:nil
                                                             fullscreen:false
                                                         isLeftFragment:NO
                                                           fragmentWith:nil];
        compositeDescription.darkBackground = true;
    }
    return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
    return self.class.compositeViewDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupUIForView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)icShowPasswordPress:(UIButton *)sender {
    
}

- (IBAction)btnSignInPress:(UIButton *)sender {
    
}

- (void)setupUIForView {
    self.view.backgroundColor = [UIColor colorWithRed:(50/255.0) green:(67/255.0) blue:(92/255.0) alpha:1.0];
    
    float hTextfield = 38.0;
    float hSignInBTN = 45.0;
    
    float hSignIn = hTextfield + 10.0 + hTextfield + 20.0 + hSignInBTN + 10.0 + hTextfield;
    [viewSignIn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.centerY.equalTo(self.view.mas_centerY).offset(50.0);
        make.height.mas_equalTo(hSignIn);
    }];
}

@end
