//
//  SignInViewController.m
//  linphone
//
//  Created by lam quang quan on 2/25/19.
//

#import "SignInViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "QRCodeReaderViewController.h"
#import "QRCodeReader.h"
#import "CustomTextAttachment.h"
#import <CommonCrypto/CommonDigest.h>

@interface SignInViewController (){
    QRCodeReaderViewController *scanQRCodeVC;
    UIButton *btnScanFromPhoto;
    UIActivityIndicatorView *icWaiting;
    
    WebServices *webService;
    NSString *port;
    NSString *domain;
    
    NSTimer *loginTimer;
}
@end

@implementation NSString (MD5)
- (NSString *)MD5String {
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (int)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
@end

@implementation SignInViewController
@synthesize viewWelcome, imgWelcome, imgLogoWelcome, lbSlogan, btnStart;
@synthesize viewSignIn, iconBack, imgLogo, lbHeader, btnAccountID, tfAccountID, btnPassword, tfPassword, btnSignIn, btnQRCode, btnShowPass;

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
    
    icWaiting = [[UIActivityIndicatorView alloc] init];
    icWaiting.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    icWaiting.backgroundColor = UIColor.whiteColor;
    icWaiting.alpha = 0.5;
    icWaiting.hidden = TRUE;
    [self.view addSubview: icWaiting];
    [icWaiting mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    //  Init for webservice
    webService = [[WebServices alloc] init];
    webService.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [WriteLogsUtils writeForGoToScreen: @"SignInViewController"];
    
    domain = @"";
    port = @"";
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(registrationUpdateEvent:)
                                               name:kLinphoneRegistrationUpdate object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    //  [self showWelcomeView];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnSignInPress:(UIButton *)sender {
    if ([AppUtils isNullOrEmpty: tfAccountID.text] || [AppUtils isNullOrEmpty: tfPassword.text]) {
        [self.view makeToast:pls_fill_full_info duration:2.0 position:CSToastPositionCenter];
        return;
    }
    [sender setTitleColor:[UIColor colorWithRed:(50/255.0) green:(196/255.0) blue:(124/255.0) alpha:1.0]
                 forState:UIControlStateNormal];
    sender.backgroundColor = UIColor.whiteColor;

    [self performSelector:@selector(startLogin:) withObject:sender afterDelay:0.15];
}

- (IBAction)btnShowPassPress:(UIButton *)sender {
    if (sender.tag == 0) {
        sender.tag = 1;
        [sender setImage:[UIImage imageNamed:@"ic_show_pass"] forState:UIControlStateNormal];
        tfPassword.secureTextEntry = NO;
    }else{
        sender.tag = 0;
        [sender setImage:[UIImage imageNamed:@"ic_hide_pass"] forState:UIControlStateNormal];
        tfPassword.secureTextEntry = TRUE;
    }
}

- (void)startLogin: (UIButton *)sender {
    [WriteLogsUtils writeLogContent:SFM(@"[%s] user: %@, pass: %@", __FUNCTION__, tfAccountID.text, tfPassword.text) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [sender setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor colorWithRed:(50/255.0) green:(196/255.0) blue:(124/255.0) alpha:1.0];
    
    //  start register pbx
    [self.view endEditing: TRUE];
    icWaiting.hidden = NO;
    [icWaiting startAnimating];
    
    NSString *total = SFM(@"%@%@%@", tfPassword.text, [LinphoneAppDelegate sharedInstance].randomKey, tfAccountID.text);
    [LinphoneAppDelegate sharedInstance].hashStr = [[total MD5String] lowercaseString];
    
    NSString *params = SFM(@"username=%@", tfAccountID.text);
    [webService callGETWebServiceWithFunction:login_func andParams:params];
}

- (IBAction)iconBackPress:(UIButton *)sender {
    [self showWelcomeView];
}

- (BOOL)checkAccountLoginInformationReady {
    if (![tfAccountID.text isEqualToString:@""] && ![tfPassword.text isEqualToString:@""]) {
        return TRUE;
    }else{
        return NO;
    }
}

- (void)showWelcomeView {
    [self.view endEditing: TRUE];
    
    [viewWelcome mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    [viewSignIn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.view);
        make.left.equalTo(self.view).offset(SCREEN_WIDTH);
        make.width.mas_equalTo(SCREEN_WIDTH);
    }];
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)whenTextfieldDidChange:(UITextField *)textfield {
    BOOL ready = [self checkAccountLoginInformationReady];
    if (ready) {
        btnSignIn.enabled = TRUE;
        btnSignIn.backgroundColor = [UIColor colorWithRed:(50/255.0) green:(196/255.0) blue:(124/255.0) alpha:1.0];
        btnSignIn.layer.borderColor = btnSignIn.backgroundColor.CGColor;
    }else{
        btnSignIn.enabled = NO;
        btnSignIn.backgroundColor = [UIColor colorWithRed:(234/255.0) green:(238/255.0) blue:(243/255.0) alpha:1.0];
        btnSignIn.layer.borderColor = btnSignIn.backgroundColor.CGColor;
    }
}

- (void)setupUIForView {
    //  Welcome view
    viewWelcome.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(235/255.0) blue:(235/255.0) alpha:1.0];
    [viewWelcome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    /*
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    gradient.colors = @[(id)[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0].CGColor, (id)[UIColor colorWithRed:(60/255.0) green:(198/255.0) blue:(116/255.0) alpha:1.0].CGColor];
    [viewWelcome.layer insertSublayer:gradient atIndex:0];
    */
    
    float wImgWelcome;
    if (IS_IPHONE || IS_IPOD) {
        wImgWelcome = SCREEN_WIDTH*4/6;
    }else{
        wImgWelcome = 300.0;
    }
    
    imgWelcome.clipsToBounds = TRUE;
    imgWelcome.layer.cornerRadius = wImgWelcome/2;
    [imgWelcome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewWelcome.mas_centerX);
        make.bottom.equalTo(viewWelcome.mas_centerY).offset(-20.0);
        make.width.height.mas_equalTo(wImgWelcome);
    }];
    imgWelcome.layer.cornerRadius = wImgWelcome/2;
    imgWelcome.layer.borderWidth = 5.0;
    imgWelcome.layer.borderColor = [UIColor colorWithRed:(246/255.0) green:(183/255.0) blue:(150/255.0) alpha:1.0].CGColor;
    imgWelcome.clipsToBounds = TRUE;
    
    float topPadding = 30.0;
    float hLogo;
    float hLogoColor = 60.0;
    float marginTop = 35.0;
    float marginSlogan = 40.0;
    float wButtonStart = 180;
    float hButtonStart = 55.0;
    UIFont *sloganFont = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    UIFont *headerFont = [UIFont systemFontOfSize:28.0 weight:UIFontWeightBold];
    UIFont *textfieldFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
    UIFont *buttonFont = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    
    float accMargin = 30.0;
    float topHeader = 20.0;
    float hBTN = 45.0;
    float hSepa = 45.0;
    float hTextfield = 42.0;
    float edge = 8.0;
    float sizeIconQR = 24.0;
    float edgeBack = 12.0;
    float padding = 30.0;
    float btnMarginTop = 20.0;
    
    if (!IS_IPHONE && !IS_IPOD) {
        //  Screen width: 375.000000 - Screen height: 812.000000;
        hLogo = 60.0;
        sloganFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightRegular];
        marginTop = 50.0;
        marginSlogan = 30.0;
        
        topPadding = [UIApplication sharedApplication].statusBarFrame.size.height + 5;
        padding = 50.0;
        hLogoColor = 50.0;
        headerFont = [UIFont systemFontOfSize:30.0 weight:UIFontWeightBold];
        accMargin = 20.0;
        hTextfield = 50.0;
        btnMarginTop = 40.0;
        edge = 10.0;
        hBTN = 55.0;
        
        btnStart.titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightMedium];
    }else{
        NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
        if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: IphoneSE])
        {
            //  Screen width: 320.000000 - Screen height: 667.000000
            hLogo = 40.0;
            marginTop = 10.0;
            marginSlogan = 20.0;
            wButtonStart = 150.0;
            hButtonStart = 40.0;
            sloganFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
            
            padding = 30.0;
            hLogoColor = 30.0;
            topPadding = 10.0;
            headerFont = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
            accMargin = 5.0;
            
            topHeader = 15.0;
            hBTN = 38.0;
            hSepa = 30.0;
            hTextfield = 40.0;
            edge = 10.0;
            sizeIconQR = 20.0;
            btnMarginTop = 20.0;
            
            textfieldFont = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
            buttonFont = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
            
            edgeBack = 15.0;
            
            btnStart.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
            
        }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
        {
            //  Screen width: 375.000000 - Screen height: 667.000000
            hLogo = 65.0;
            marginTop = 20.0;
            marginSlogan = 30.0;
            wButtonStart = 170.0;
            hButtonStart = 50.0;
            sloganFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:19.0];
            
            padding = 25.0;
            topPadding = 15.0;
            hLogoColor = 55.0;
            accMargin = 10.0;
            edgeBack = 14.0;
            edge = 9.0;
            headerFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
            
            btnMarginTop = 20.0;
            btnStart.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
            
        }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
        {
            //  Screen width: 414.000000 - Screen height: 736.000000
            hLogo = 65.0;
            
            padding = 30.0;
            hLogoColor = 50.0;
            topPadding = 10.0;
            edgeBack = 14.0;
            edge = 12.0;
            sloganFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:22.0];
            
            accMargin = 20.0;
            headerFont = [UIFont systemFontOfSize:26.0 weight:UIFontWeightBold];
            hTextfield = 46.0;
            hBTN = 50.0;
            buttonFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:22.0];
            btnMarginTop = 30.0;
            btnStart.titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightMedium];
            
        }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2] || [deviceMode isEqualToString: simulator]){
            //  Screen width: 375.000000 - Screen height: 812.000000;
            hLogo = 65.0;
            sloganFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightRegular];
            marginTop = 30.0;
            marginSlogan = 30.0;
            
            topPadding = [UIApplication sharedApplication].statusBarFrame.size.height + 5;
            padding = 30.0;
            hLogoColor = 50.0;
            headerFont = [UIFont systemFontOfSize:25.0 weight:UIFontWeightBold];
            accMargin = 20.0;
            
            btnStart.titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightMedium];
        }else{
            //  Screen width: 375.000000 - Screen height: 812.000000;
            hLogo = 55.0;
            sloganFont = [UIFont systemFontOfSize:20.0 weight:UIFontWeightRegular];
            marginTop = 30.0;
            marginSlogan = 30.0;
            
            topPadding = [UIApplication sharedApplication].statusBarFrame.size.height + 5;
            padding = 30.0;
            hLogoColor = 50.0;
            headerFont = [UIFont systemFontOfSize:25.0 weight:UIFontWeightBold];
            accMargin = 20.0;
            
            btnStart.titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightMedium];
        }
    }
    
    UIImage *logoImg = [UIImage imageNamed:@"logo_transparent.png"];
    float wLogo = logoImg.size.width * hLogo / logoImg.size.height;
    [imgLogoWelcome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewWelcome.mas_centerX);
        make.top.equalTo(imgWelcome.mas_bottom).offset(marginTop);
        make.width.mas_equalTo(wLogo);
        make.height.mas_equalTo(hLogo);
    }];
    
    CGSize textSize = [AppUtils getSizeWithText:text_slogent withFont:sloganFont andMaxWidth:(SCREEN_WIDTH-50.0)];
    
    lbSlogan.font = sloganFont;
    lbSlogan.text = text_slogent;
    lbSlogan.numberOfLines = 5;
    lbSlogan.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    [lbSlogan mas_makeConstraints:^(MASConstraintMaker *make) {
        //  make.centerX.equalTo(viewWelcome.mas_centerX);
        make.top.equalTo(imgLogoWelcome.mas_bottom).offset(marginSlogan);
        make.left.equalTo(viewWelcome).offset(5.0);
        make.right.equalTo(viewWelcome).offset(-5.0);
        //  make.width.mas_equalTo(textSize.width + 20);
        make.height.mas_equalTo(textSize.height + 10);
    }];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, wButtonStart, hButtonStart);
    gradient.colors = @[(id)[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0].CGColor, (id)[UIColor colorWithRed:(60/255.0) green:(198/255.0) blue:(116/255.0) alpha:1.0].CGColor];
    gradient.startPoint = CGPointMake(1, 0);
    gradient.endPoint = CGPointMake(0, 1);
    
    [btnStart.layer insertSublayer:gradient atIndex:0];
    [btnStart setTitle:text_start forState:UIControlStateNormal];
    [btnStart setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btnStart.layer.cornerRadius = 5.0;
    btnStart.clipsToBounds = TRUE;
    btnStart.backgroundColor = [UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0];
    
    [btnStart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewWelcome.mas_centerX);
        make.top.equalTo(lbSlogan.mas_bottom).offset(40.0);
        make.width.mas_equalTo(wButtonStart);
        make.height.mas_equalTo(hButtonStart);
    }];
    
    //  view sign in
    viewSignIn.backgroundColor = UIColor.whiteColor;
    [viewSignIn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(SCREEN_WIDTH);
        make.top.bottom.equalTo(self.view);
        make.width.mas_equalTo(SCREEN_WIDTH);
    }];
    
    logoImg = [UIImage imageNamed:@"logo_color.png"];
    wLogo = logoImg.size.width * hLogoColor / logoImg.size.height;
    [imgLogo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewSignIn.mas_centerX);
        make.top.equalTo(viewSignIn).offset(topPadding);
        make.width.mas_equalTo(wLogo);
        make.height.mas_equalTo(hLogoColor);
    }];
    
    iconBack.imageEdgeInsets = UIEdgeInsetsMake(edgeBack, edgeBack, edgeBack, edgeBack);
    [iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(imgLogo.mas_centerY);
        make.left.equalTo(viewSignIn);
        make.width.height.mas_equalTo(50.0);
    }];
    
    NSString *headerContent = text_welcome;
    headerContent = [headerContent stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    textSize = [AppUtils getSizeWithText:headerContent withFont:headerFont andMaxWidth:(SCREEN_WIDTH - 2*padding)];
    lbHeader.text = headerContent;
    lbHeader.numberOfLines = 0;
    lbHeader.font = headerFont;
    [lbHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imgLogo.mas_bottom).offset(topHeader);
        make.left.equalTo(viewSignIn).offset(padding);
        make.right.equalTo(viewSignIn).offset(-padding);
        make.height.mas_equalTo(textSize.height + 20);
    }];
    
    //  account textfield
    float textfieldPadding;
    if (IS_IPOD || IS_IPHONE) {
        textfieldPadding = 10.0;
    }else{
        textfieldPadding = 20.0;
    }
    
    tfAccountID.placeholder = text_account;
    [tfAccountID addTarget:self
                    action:@selector(whenTextfieldDidChange:)
          forControlEvents:UIControlEventEditingChanged];
    
    tfAccountID.font = textfieldFont;
    tfAccountID.textColor = UIColor.blackColor;
    [tfAccountID mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbHeader.mas_bottom).offset(accMargin);
        make.left.right.equalTo(lbHeader);
        make.height.mas_equalTo(hTextfield);
    }];
    tfAccountID.borderStyle = UITextBorderStyleNone;
    tfAccountID.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hTextfield-edge, hTextfield)];
    tfAccountID.leftViewMode = UITextFieldViewModeAlways;
    
    UILabel *lbAccount = [[UILabel alloc] init];
    lbAccount.backgroundColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                                 blue:(220/255.0) alpha:1.0];
    [viewSignIn addSubview: lbAccount];
    [lbAccount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(btnAccountID).offset(edge);
        make.bottom.equalTo(tfAccountID.mas_bottom);
        make.right.equalTo(tfAccountID);
        make.height.mas_equalTo(1.0);
    }];
    
    btnAccountID.enabled = NO;
    [btnAccountID setImage:[UIImage imageNamed:@"icon_acc"] forState:UIControlStateDisabled];
    btnAccountID.imageEdgeInsets = UIEdgeInsetsMake(edge,edge, edge, edge);
    [btnAccountID mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tfAccountID).offset(-edge);
        make.top.bottom.equalTo(tfAccountID);
        make.width.mas_equalTo(hTextfield);
    }];
    
    //  password textfield
    tfPassword.placeholder = text_password;
    [tfPassword addTarget:self
                   action:@selector(whenTextfieldDidChange:)
         forControlEvents:UIControlEventEditingChanged];
    
    tfPassword.font = textfieldFont;
    tfPassword.secureTextEntry = TRUE;
    tfPassword.textColor = tfAccountID.textColor;
    [tfPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfAccountID.mas_bottom).offset(textfieldPadding);
        make.left.right.equalTo(tfAccountID);
        make.height.mas_equalTo(hTextfield);
    }];
    tfPassword.borderStyle = UITextBorderStyleNone;
    tfPassword.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hTextfield-edge, hTextfield)];
    tfPassword.leftViewMode = UITextFieldViewModeAlways;
    
    tfPassword.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hTextfield, hTextfield)];
    tfPassword.rightViewMode = UITextFieldViewModeAlways;
    
    //  show, hide password
    btnShowPass.tag = 0;
    if (IS_IPOD || IS_IPHONE) {
        btnShowPass.imageEdgeInsets = UIEdgeInsetsMake(6,6, 6, 6);
        [btnShowPass mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(tfPassword).offset(edge);
            make.top.bottom.equalTo(tfPassword);
            make.width.mas_equalTo(hTextfield);
        }];
    }else{
        btnShowPass.imageEdgeInsets = UIEdgeInsetsMake(9, 9, 9, 9);
        [btnShowPass mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(tfPassword).offset(edge);
            make.top.bottom.equalTo(tfPassword);
            make.width.mas_equalTo(hTextfield);
        }];
    }
    
    UILabel *lbPassword = [[UILabel alloc] init];
    lbPassword.backgroundColor = lbAccount.backgroundColor;
    [viewSignIn addSubview: lbPassword];
    [lbPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(btnPassword).offset(edge);
        make.right.equalTo(tfPassword);
        make.bottom.equalTo(tfPassword.mas_bottom);
        make.height.mas_equalTo(1.0);
    }];
    
    btnPassword.enabled = NO;
    [btnPassword setImage:[UIImage imageNamed:@"icon_pass"] forState:UIControlStateDisabled];
    btnPassword.imageEdgeInsets = UIEdgeInsetsMake(edge,edge, edge, edge);
    [btnPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tfPassword).offset(-edge);
        make.top.left.bottom.equalTo(tfPassword);
        make.width.mas_equalTo(hTextfield);
    }];
    
    //  signin button
    btnSignIn.enabled = NO;
    [btnSignIn setTitle:text_sign_in forState:UIControlStateNormal];
    btnSignIn.titleLabel.font = buttonFont;
    btnSignIn.backgroundColor = [UIColor colorWithRed:(234/255.0) green:(238/255.0) blue:(243/255.0) alpha:1.0];
    btnSignIn.layer.borderColor = [UIColor colorWithRed:(234/255.0) green:(238/255.0) blue:(243/255.0) alpha:1.0].CGColor;
    btnSignIn.layer.borderWidth = 1.0;
    [btnSignIn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [btnSignIn setTitleColor:UIColor.lightGrayColor forState:UIControlStateDisabled];
    btnSignIn.layer.cornerRadius = 5.0;
    [btnSignIn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfPassword.mas_bottom).offset(btnMarginTop);
        make.left.right.equalTo(tfPassword);
        make.height.mas_equalTo(hBTN);
    }];
    
    float hDot = 3.0;
    UILabel *lbDot1 = [[UILabel alloc] init];
    lbDot1.clipsToBounds = TRUE;
    lbDot1.layer.cornerRadius = hDot/2;
    lbDot1.backgroundColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0)
                                              blue:(102/255.0) alpha:1.0];
    [viewSignIn addSubview: lbDot1];
    [lbDot1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnSignIn.mas_bottom).offset((hSepa-hDot)/2);
        make.centerX.equalTo(viewSignIn.mas_centerX);
        make.width.height.mas_equalTo(hDot);
    }];
    
    UILabel *lbDot2 = [[UILabel alloc] init];
    lbDot2.clipsToBounds = TRUE;
    lbDot2.layer.cornerRadius = hDot/2;
    lbDot2.backgroundColor = lbDot1.backgroundColor;
    [viewSignIn addSubview: lbDot2];
    [lbDot2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(lbDot1);
        make.right.equalTo(lbDot1.mas_left).offset(-4.0);
        make.width.mas_equalTo(hDot);
    }];
    
    UILabel *lbDot3 = [[UILabel alloc] init];
    lbDot3.clipsToBounds = TRUE;
    lbDot3.layer.cornerRadius = hDot/2;
    lbDot3.backgroundColor = lbDot1.backgroundColor;
    [viewSignIn addSubview: lbDot3];
    [lbDot3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(lbDot1);
        make.left.equalTo(lbDot1.mas_right).offset(4.0);
        make.width.mas_equalTo(hDot);
    }];
    
    [btnQRCode setAttributedTitle:[self getQRCodeTitleContentWithFont: buttonFont andSizeIcon:sizeIconQR] forState:UIControlStateNormal];
    //  btnQRCode.titleLabel.font = buttonFont;
    btnQRCode.backgroundColor = [UIColor colorWithRed:(234/255.0) green:(238/255.0) blue:(243/255.0) alpha:1.0];
    btnQRCode.layer.cornerRadius = 5.0;
    [btnQRCode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbDot1.mas_bottom).offset((hSepa-hDot)/2);
        make.left.right.equalTo(btnSignIn);
        make.height.equalTo(btnSignIn.mas_height);
    }];
}

- (void)registrationUpdateEvent:(NSNotification *)notif {
    NSString *message = [notif.userInfo objectForKey:@"message"];
    [self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue]
                    forProxy:[[notif.userInfo objectForKeyedSubscript:@"cfg"] pointerValue]
                     message:message];
}

- (void)registrationUpdate:(LinphoneRegistrationState)state forProxy:(LinphoneProxyConfig *)proxy message:(NSString *)message
{
    switch (state) {
        case LinphoneRegistrationOk:
        {
            [WriteLogsUtils writeLogContent:SFM(@"[%s] state is LinphoneRegistrationOk", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            [self clearLoginTimerIfNeed];
            icWaiting.hidden = TRUE;
            [icWaiting stopAnimating];
            
            [[NSUserDefaults standardUserDefaults] setObject:tfAccountID.text forKey:key_login];
            [[NSUserDefaults standardUserDefaults] setObject:tfPassword.text forKey:key_password];
            if (tfAccountID.text.length > 5) {
                NSString *accountID = [tfAccountID.text substringFromIndex: 5];
                if ([AppUtils isNullOrEmpty: accountID]) {
                    [[NSUserDefaults standardUserDefaults] setObject:accountID forKey:PBX_ID];
                }
            }
            [[NSUserDefaults standardUserDefaults] setObject:domain forKey:PBX_SERVER];
            [[NSUserDefaults standardUserDefaults] setObject:port forKey:PBX_PORT];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
            [PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
            break;
        }
        case LinphoneRegistrationNone:{
            [WriteLogsUtils writeLogContent:SFM(@"[%s] state is LinphoneRegistrationNone", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            break;
        }
        case LinphoneRegistrationCleared: {
            [WriteLogsUtils writeLogContent:SFM(@"[%s] state is LinphoneRegistrationCleared", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            break;
        }
        case LinphoneRegistrationFailed:
        {
            [WriteLogsUtils writeLogContent:SFM(@"[%s] state is LinphoneRegistrationFailed", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            [self clearLoginTimerIfNeed];
            icWaiting.hidden = TRUE;
            [icWaiting stopAnimating];
            
            [self.view makeToast:pls_check_signin_info duration:2.0 position:CSToastPositionCenter];
            
            break;
        }
        case LinphoneRegistrationProgress: {
            [WriteLogsUtils writeLogContent:SFM(@"[%s] state is LinphoneRegistrationProgress", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            break;
        }
        default:
            break;
    }
}

- (IBAction)btnQRCodePress:(UIButton *)sender {
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([DeviceUtils isAvailableVideo]) {
        QRCodeReader *reader = [QRCodeReader readerWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
        scanQRCodeVC = [QRCodeReaderViewController readerWithCancelButtonTitle:text_cancel codeReader:reader startScanningAtLoad:TRUE showSwitchCameraButton:TRUE showTorchButton:TRUE];
        scanQRCodeVC.modalPresentationStyle = UIModalPresentationFormSheet;
        scanQRCodeVC.delegate = self;
        
        btnScanFromPhoto = [UIButton buttonWithType: UIButtonTypeCustom];
        btnScanFromPhoto.frame = CGRectMake((SCREEN_WIDTH-250)/2, SCREEN_HEIGHT-38-60, 250, 38);
        btnScanFromPhoto.backgroundColor = [UIColor colorWithRed:(101/255.0) green:(205/255.0)
                                                            blue:(70/255.0) alpha:1.0];
        [btnScanFromPhoto setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btnScanFromPhoto.layer.cornerRadius = btnScanFromPhoto.frame.size.height/2;
        btnScanFromPhoto.layer.borderColor = btnScanFromPhoto.backgroundColor.CGColor;
        btnScanFromPhoto.layer.borderWidth = 1.0;
        
        [btnScanFromPhoto setTitle:text_scan_from_photo forState:UIControlStateNormal];
        btnScanFromPhoto.titleLabel.font = [UIFont systemFontOfSize: 16.0];
        [btnScanFromPhoto addTarget:self
                             action:@selector(btnScanFromPhotoPressed)
                   forControlEvents:UIControlEventTouchUpInside];
        
        [scanQRCodeVC.view addSubview: btnScanFromPhoto];
        
        [scanQRCodeVC setCompletionWithBlock:^(NSString *resultAsString) {
            
        }];
        [self presentViewController:scanQRCodeVC animated:TRUE completion:NULL];
    }else{
        [self.view makeToast:cannot_access_camera duration:3.0 position:CSToastPositionCenter];
    }
}

- (void)btnScanFromPhotoPressed {
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    btnScanFromPhoto.backgroundColor = [UIColor whiteColor];
    [btnScanFromPhoto setTitleColor:[UIColor colorWithRed:(101/255.0) green:(205/255.0)
                                                     blue:(70/255.0) alpha:1.0]
                           forState:UIControlStateNormal];
    [self performSelector:@selector(choosePictureForScanQRCode) withObject:nil afterDelay:0.05];
}

- (void)choosePictureForScanQRCode {
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    btnScanFromPhoto.backgroundColor = [UIColor colorWithRed:(101/255.0) green:(205/255.0)
                                                        blue:(70/255.0) alpha:1.0];
    [btnScanFromPhoto setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    pickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    pickerController.allowsEditing = NO;
    pickerController.delegate = self;
    [scanQRCodeVC presentViewController:pickerController animated:TRUE completion:nil];
}

#pragma mark - Image picker delegate
- (void)readerDidCancel:(QRCodeReaderViewController *)reader {
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [self dismissViewControllerAnimated:TRUE completion:^{
        [tfAccountID becomeFirstResponder];
    }];
}

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result {
    [reader stopScanning];
    
    [self dismissViewControllerAnimated:TRUE completion:^{
        [WriteLogsUtils writeLogContent:SFM(@"[%s] result: %@", __FUNCTION__, result) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        icWaiting.hidden = NO;
        [icWaiting startAnimating];
        
        [self checkRegistrationInfoFromQRCode: result];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [picker dismissViewControllerAnimated:TRUE completion:^{
        [self dismissViewControllerAnimated:TRUE completion:NULL];
        NSString* type = [info objectForKey:UIImagePickerControllerMediaType];
        if ([type isEqualToString: (NSString*)kUTTypeImage] ) {
            [self hideWaitingView: NO];
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            [self getQRCodeContentFromImage: image];
        }
    }];
}

- (void)getQRCodeContentFromImage: (UIImage *)image {
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    NSArray *qrcodeContent = [self detectQRCode: image];
    if (qrcodeContent != nil && qrcodeContent.count > 0) {
        for (CIQRCodeFeature* qrFeature in qrcodeContent)
        {
            [self checkRegistrationInfoFromQRCode: qrFeature.messageString];
            break;
        }
    }else{
        [self showDialerQRCodeNotCorrect];
    }
}

- (NSArray *)detectQRCode:(UIImage *) image
{
    @autoreleasepool {
        CIImage* ciImage = [[CIImage alloc] initWithCGImage: image.CGImage]; // to use if the underlying data is a CGImage
        NSDictionary* options;
        CIContext* context = [CIContext context];
        options = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh }; // Slow but thorough
        //options = @{ CIDetectorAccuracy : CIDetectorAccuracyLow}; // Fast but superficial
        
        CIDetector* qrDetector = [CIDetector detectorOfType:CIDetectorTypeQRCode
                                                    context:context
                                                    options:options];
        if ([[ciImage properties] valueForKey:(NSString*) kCGImagePropertyOrientation] == nil) {
            options = @{ CIDetectorImageOrientation : @1};
        } else {
            options = @{ CIDetectorImageOrientation : [[ciImage properties] valueForKey:(NSString*) kCGImagePropertyOrientation]};
        }
        NSArray * features = [qrDetector featuresInImage:ciImage
                                                 options:options];
        return features;
    }
}

- (void)checkRegistrationInfoFromQRCode: (NSString *)qrcodeResult {
    [WriteLogsUtils writeLogContent:SFM(@"[%s] qrcodeResult: %@", __FUNCTION__, qrcodeResult) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if (![AppUtils isNullOrEmpty: qrcodeResult]) {
        if (qrcodeResult.length > 5) {
            NSString *password = [qrcodeResult substringFromIndex: 5];
            
            NSString *total = SFM(@"%@%@%@", password, [LinphoneAppDelegate sharedInstance].randomKey, qrcodeResult);
            [LinphoneAppDelegate sharedInstance].hashStr = [[total MD5String] lowercaseString];
            
            NSString *params = SFM(@"hashstring=%@", qrcodeResult);
            [webService callGETWebServiceWithFunction:decryptRSA_func andParams:params];
            return;
        }
    }
    icWaiting.hidden = TRUE;
    [icWaiting stopAnimating];
    [self showDialerQRCodeNotCorrect];
}

- (void)showDialerQRCodeNotCorrect {
    [self hideWaitingView: TRUE];
    [self.view makeToast:cannot_detect_QRCode duration:2.0 position:CSToastPositionCenter];
}

- (IBAction)btnStartPress:(UIButton *)sender {
    sender.enabled = FALSE;
    [sender setTitleColor:[UIColor colorWithRed:(60/255.0) green:(198/255.0) blue:(116/255.0) alpha:1.0] forState:UIControlStateNormal];
    [self performSelector:@selector(goToLoginScreen:) withObject:sender afterDelay:0.1];
}

- (void)goToLoginScreen: (UIButton *)sender {
    NSString *accountID = [[NSUserDefaults standardUserDefaults] objectForKey:key_login];
    if (![AppUtils isNullOrEmpty: accountID]) {
        tfAccountID.text = accountID;
        [tfPassword becomeFirstResponder];
    }else{
        [tfAccountID becomeFirstResponder];
    }
    
    sender.enabled = TRUE;
    [sender setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];

    BOOL ready = [self checkAccountLoginInformationReady];
    if (ready) {
        btnSignIn.enabled = TRUE;
        btnSignIn.backgroundColor = [UIColor colorWithRed:(50/255.0) green:(196/255.0) blue:(124/255.0) alpha:1.0];
        btnSignIn.layer.borderColor = btnSignIn.backgroundColor.CGColor;
    }else{
        btnSignIn.enabled = FALSE;
        btnSignIn.backgroundColor = [UIColor colorWithRed:(234/255.0) green:(238/255.0) blue:(243/255.0) alpha:1.0];
        btnSignIn.layer.borderColor = btnSignIn.backgroundColor.CGColor;
    }
    
    [viewWelcome mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view.mas_left);
        make.top.bottom.equalTo(self.view);
        make.width.mas_equalTo(SCREEN_WIDTH);
    }];
    
    [viewSignIn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (NSAttributedString *)getQRCodeTitleContentWithFont: (UIFont *)textFont andSizeIcon: (float)size
{
    CustomTextAttachment *attachment = [[CustomTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"qrcode.png"];
    [attachment setImageHeight: size];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSString *content = SFM(@" %@", or_sign_in_with_QRCode);
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] initWithString:content];
    [contentString addAttribute:NSFontAttributeName value:textFont range:NSMakeRange(0, contentString.length)];
    [contentString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0] range:NSMakeRange(0, contentString.length)];
    
    NSMutableAttributedString *verString = [[NSMutableAttributedString alloc] initWithAttributedString: attachmentString];
    //
    [verString appendAttributedString: contentString];
    return verString;
}

- (void)hideWaitingView: (BOOL)hide {
    if (hide) {
        [icWaiting stopAnimating];
        icWaiting.hidden = TRUE;
    }else{
        [icWaiting startAnimating];
        icWaiting.hidden = NO;
    }
}

- (void)processingWithQRCodeInfo: (NSDictionary *)info {
    domain = [info objectForKey:@"domain"];
    port = [info objectForKey:@"port"];
    if ([port isKindOfClass:[NSNumber class]]) {
        port = SFM(@"%d", [port intValue]);
    }
    NSString *userName = [info objectForKey:@"username"];
    NSString *password = [info objectForKey:@"password"];
    if (![AppUtils isNullOrEmpty: userName] && ![AppUtils isNullOrEmpty: password] && ![AppUtils isNullOrEmpty: port] && ![AppUtils isNullOrEmpty: domain]) {
        tfAccountID.text = userName;
        tfPassword.text = password;
        
        [self startTimerToCheckRegisterSIP];
        [SipUtils registerPBXAccount:userName password:password ipAddress:domain port:port];
    }else{
        [self hideWaitingView: TRUE];
        [self showDialerQRCodeNotCorrect];
    }
}

- (void)startTimerToCheckRegisterSIP {
    if (loginTimer != nil) {
        [loginTimer invalidate];
        loginTimer = nil;
    }
    loginTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(cannotRegisterSIP) userInfo:nil repeats:NO];
}

- (void)clearLoginTimerIfNeed {
    if (loginTimer != nil) {
        [loginTimer invalidate];
        loginTimer = nil;
    }
}

- (void)cannotRegisterSIP {
    linphone_core_clear_proxy_config(LC);
    
    [self clearLoginTimerIfNeed];
    
    icWaiting.hidden = TRUE;
    [icWaiting stopAnimating];
    
    [self.view makeToast:@"Không thể đăng nhập. Vui lòng kiểm tra thông tin tài khoản!" duration:2.0 position:CSToastPositionCenter];
}

#pragma mark - Webservice Delegate

- (void)failedToCallWebService:(NSString *)link andError:(id)error
{
    [WriteLogsUtils writeLogContent:SFM(@"[%s] link: %@, error: %@", __FUNCTION__, link, @[error]) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [self hideWaitingView: TRUE];
    if ([link isEqualToString: login_func]) {
        if ([error isKindOfClass:[NSDictionary class]]) {
            [self.view makeToast:@"Sai tên đăng nhập hoặc mật khẩu"
                        duration:2.0 position:CSToastPositionCenter];
        }
        
    }else if ([link isEqualToString: decryptRSA_func]) {
        [self showDialerQRCodeNotCorrect];
    }
    
}

- (void)successfulToCallWebService:(NSString *)link withData:(NSDictionary *)data
{
    [WriteLogsUtils writeLogContent:SFM(@"[%s] link: %@, data: %@", __FUNCTION__, link, @[data]) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([link isEqualToString: login_func]) {
        if (data != nil && [data isKindOfClass:[NSDictionary class]]) {
            domain = [data objectForKey:@"domain"];
            port = [data objectForKey:@"port"];
            if ([port isKindOfClass:[NSNumber class]]) {
                port = SFM(@"%d", [port intValue]);
            }
            
            [self startTimerToCheckRegisterSIP];
            [SipUtils registerPBXAccount:tfAccountID.text password:tfPassword.text ipAddress:domain port:port];
        }
    }else if ([link isEqualToString: decryptRSA_func]) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            [self processingWithQRCodeInfo: data];
        }
    }else{
        [self hideWaitingView: TRUE];
    }
}

- (void)receivedResponeCode:(NSString *)link withCode:(int)responeCode {
    NSLog(@"%d", responeCode);
}

@end
