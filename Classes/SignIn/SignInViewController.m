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
@synthesize imgLogo, lbCompany, viewSignIn, tfAccountID, btnAccountID, tfPassword, btnPassword, icShowPassword, btnSignIn, lbForgotPassword, lbBottom;

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

- (void)whenTapOnScreen {
    [self.view endEditing: YES];
}

- (void)setupUIForView {
    self.view.backgroundColor = [UIColor colorWithRed:(50/255.0) green:(67/255.0) blue:(92/255.0) alpha:1.0];
    
    UITapGestureRecognizer *tapOnScreen = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(whenTapOnScreen)];
    [self.view addGestureRecognizer: tapOnScreen];
    
    float hTextfield = 42.0;
    float hSignInBTN = 45.0;
    
    UIColor *textColor = [UIColor colorWithRed:(160/255.0) green:(160/255.0)
                                          blue:(160/255.0) alpha:1.0];
    
    float hSignIn = hTextfield + 20.0 + hTextfield + 30.0 + hSignInBTN + 20.0 + hTextfield;
    viewSignIn.backgroundColor = UIColor.clearColor;
    [viewSignIn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.centerY.equalTo(self.view.mas_centerY).offset(20);
        make.height.mas_equalTo(hSignIn);
    }];
    
    float padding = 40.0;
    //  account textfield
    [tfAccountID mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewSignIn);
        make.left.equalTo(viewSignIn).offset(padding);
        make.right.equalTo(viewSignIn).offset(-padding);
        make.height.mas_equalTo(hTextfield);
    }];
    tfAccountID.borderStyle = UITextBorderStyleNone;
    tfAccountID.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hTextfield, hTextfield)];
    tfAccountID.leftViewMode = UITextFieldViewModeAlways;
    
    UILabel *lbAccount = [[UILabel alloc] init];
    lbAccount.backgroundColor = textColor;
    [tfAccountID addSubview: lbAccount];
    [lbAccount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tfAccountID).offset(8.0);
        make.bottom.right.equalTo(tfAccountID);
        make.height.mas_equalTo(1.0);
    }];
    
    btnAccountID.enabled = NO;
    [btnAccountID setImage:[UIImage imageNamed:@"ic_user"] forState:UIControlStateDisabled];
    btnAccountID.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [btnAccountID mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.equalTo(tfAccountID);
        make.width.mas_equalTo(hTextfield);
    }];
    
    //  password textfield
    [tfPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfAccountID.mas_bottom).offset(20.0);
        make.left.right.equalTo(tfAccountID);
        make.height.mas_equalTo(hTextfield);
    }];
    tfPassword.borderStyle = UITextBorderStyleNone;
    tfPassword.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hTextfield, hTextfield)];
    tfPassword.leftViewMode = UITextFieldViewModeAlways;
    
    UILabel *lbPassword = [[UILabel alloc] init];
    lbPassword.backgroundColor = lbAccount.backgroundColor;
    [tfPassword addSubview: lbPassword];
    [lbPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tfPassword).offset(8.0);
        make.right.bottom.equalTo(tfPassword);
        make.height.mas_equalTo(1.0);
    }];
    
    btnPassword.enabled = NO;
    [btnPassword setImage:[UIImage imageNamed:@"ic_lock"] forState:UIControlStateDisabled];
    btnPassword.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [btnPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.equalTo(tfPassword);
        make.width.mas_equalTo(hTextfield);
    }];
    
    NSString *title = [[LanguageUtil sharedInstance] getContent:@"Show password"];
    [icShowPassword setTitle:[title uppercaseString] forState:UIControlStateNormal];
    icShowPassword.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightThin];
    [icShowPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.bottom.equalTo(tfPassword);
        make.width.mas_equalTo(60);
    }];
    
    tfPassword.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 65, hTextfield)];
    tfPassword.rightViewMode = UITextFieldViewModeAlways;
    
    //  signin button
    NSString *btnTitle = [[[LanguageUtil sharedInstance] getContent:@"Sign In"] uppercaseString];
    [btnSignIn setTitle:btnTitle forState:UIControlStateNormal];
    btnSignIn.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    btnSignIn.backgroundColor = [UIColor colorWithRed:(73/255.0) green:(207/255.0)
                                                 blue:(246/255.0) alpha:1.0];
    btnSignIn.layer.cornerRadius = 5.0;
    [btnSignIn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfPassword.mas_bottom).offset(30.0);
        make.left.right.equalTo(tfPassword);
        make.height.mas_equalTo(hSignInBTN);
    }];
    
    //  signin button
    lbForgotPassword.text = [[LanguageUtil sharedInstance] getContent:@"Forgot password"];
    lbForgotPassword.textColor = textColor;
    lbForgotPassword.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightThin];
    [lbForgotPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnSignIn.mas_bottom).offset(20.0);
        make.left.right.equalTo(tfPassword);
        make.height.mas_equalTo(hTextfield);
    }];
    
    //  header
    float top = ((SCREEN_HEIGHT - hSignIn)/2 - 160.0)/2;
    [imgLogo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view).offset(top);
        make.width.height.mas_equalTo(160.0);
    }];
    
    lbCompany.text = [[LanguageUtil sharedInstance] getContent:@"CLOUDPBX"];
    lbCompany.textColor = textColor;
    lbCompany.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightThin];
    [lbCompany mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imgLogo.mas_bottom).offset(-30.0);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(40.0);
    }];
    
    lbBottom.text = [[LanguageUtil sharedInstance] getContent:@"Phát triển bởi CloudPBX"];
    lbBottom.textColor = textColor;
    lbBottom.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightThin];
    [lbBottom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(40.0);
    }];
}

@end
