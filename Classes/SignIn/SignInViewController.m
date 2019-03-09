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

@interface SignInViewController (){
    QRCodeReaderViewController *scanQRCodeVC;
    UIButton *btnScanFromPhoto;
    UIActivityIndicatorView *icWaiting;
}

@end

@implementation SignInViewController
@synthesize viewWelcome, bgWelcome, imgWelcome, imgLogoWelcome, lbSlogan, btnStart;
@synthesize viewSignIn, iconBack, imgLogo, lbHeader, btnAccountID, tfAccountID, btnPassword, tfPassword, btnSignIn, lbSepa, btnQRCode;

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
    
    //  tfAccountID.text = @"nhcla150";
    //  tfPassword.text = @"f7NnFKI1Kv";
    tfAccountID.text = @"nhcla151";
    tfPassword.text = @"5obr8jHH2q";
    
    icWaiting = [[UIActivityIndicatorView alloc] init];
    icWaiting.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    icWaiting.backgroundColor = UIColor.whiteColor;
    icWaiting.alpha = 0.5;
    icWaiting.hidden = YES;
    [self.view addSubview: icWaiting];
    [icWaiting mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    /*
    nhanhoa.cloudcall.vn:51000
    nhcla150/f7NnFKI1Kv
    nhcla151/5obr8jHH2q
    nhcla152/FNn1bHF12z
    nhcla153/qkprudKnm9 */
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(registrationUpdateEvent:)
                                               name:kLinphoneRegistrationUpdate object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)icShowPasswordPress:(UIButton *)sender {
    
}

- (IBAction)btnSignInPress:(UIButton *)sender {
    if ([AppUtils isNullOrEmpty: tfAccountID.text] || [AppUtils isNullOrEmpty: tfPassword.text]) {
        NSString *content = [[LanguageUtil sharedInstance] getContent:@"Please fill full information"];
        [self.view makeToast:content duration:2.0 position:CSToastPositionCenter];
        return;
    }
    
    //  start register pbx
    icWaiting.hidden = NO;
    [icWaiting startAnimating];
    
    [SipUtils registerPBXAccount:tfAccountID.text password:tfPassword.text ipAddress:DOMAIN_DEFAULT port:PORT_DEFAULT];
}

- (IBAction)iconBackPress:(UIButton *)sender {
}

- (void)setupUIForView {
    //  Welcome view
    [viewWelcome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = viewWelcome.bounds;
    gradient.colors = @[(id)[UIColor colorWithRed:(60/255.0) green:(198/255.0) blue:(116/255.0) alpha:1.0].CGColor, (id)[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0].CGColor];
    
    [viewWelcome.layer insertSublayer:gradient atIndex:0];
    
    [bgWelcome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(viewWelcome);
    }];
    
    float wImgWelcome = SCREEN_WIDTH*3/5;
    imgWelcome.clipsToBounds = YES;
    imgWelcome.layer.cornerRadius = wImgWelcome/2;
    [imgWelcome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewWelcome.mas_centerX);
        make.bottom.equalTo(viewWelcome.mas_centerY);
        make.width.height.mas_equalTo(wImgWelcome);
    }];
    
    UIImage *logoImg = [UIImage imageNamed:@"logo_white.png"];
    float hLogo = 60.0;
    float wLogo = logoImg.size.width * hLogo / logoImg.size.height;
    [imgLogoWelcome mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewWelcome.mas_centerX);
        make.top.equalTo(imgWelcome.mas_bottom).offset(50.0);
        make.width.mas_equalTo(wLogo);
        make.height.mas_equalTo(hLogo);
    }];
    
    NSString *sloganContent = [[LanguageUtil sharedInstance] getContent:@"Dịch vụ tổng đài số hàng đầu Việt Nam.\nCung cấp dịch vụ thoại qua Internet tiên tiến nhất."];
    CGSize textSize = [AppUtils getSizeWithText:sloganContent withFont:[UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular] andMaxWidth:(SCREEN_WIDTH-40.0)];
    
    lbSlogan.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    lbSlogan.text = sloganContent;
    [lbSlogan mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewWelcome.mas_centerX);
        make.top.equalTo(imgLogoWelcome.mas_bottom).offset(25.0);
        make.width.mas_equalTo(textSize.width);
        make.height.mas_equalTo(textSize.height);
    }];
    
    btnStart.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    [btnStart setTitle:[[[LanguageUtil sharedInstance] getContent:@"Start"] uppercaseString] forState:UIControlStateNormal];
    [btnStart setTitleColor:[UIColor colorWithRed:(60/255.0) green:(75/255.0)
                                             blue:(102/255.0) alpha:1.0] forState:UIControlStateNormal];
    [btnStart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewWelcome.mas_centerX);
        make.top.equalTo(lbSlogan.mas_bottom).offset(25.0);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(45.0);
    }];
    
    //  view sign in
    float padding = 20.0;
    viewSignIn.backgroundColor = UIColor.whiteColor;
    [viewSignIn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    
    logoImg = [UIImage imageNamed:@"logo_color.png"];
    wLogo = logoImg.size.width * 60.0 / logoImg.size.height;
    [imgLogo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(viewSignIn.mas_centerX);
        make.top.equalTo(viewSignIn).offset(50.0);
        make.width.mas_equalTo(wLogo);
        make.height.mas_equalTo(60.0);
    }];
    
    iconBack.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    [iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(imgLogo.mas_centerY);
        make.left.equalTo(viewSignIn).offset(10.0);
        make.width.height.mas_equalTo(60.0);
    }];
    
    NSString *headerContent = [[LanguageUtil sharedInstance] getContent:@"Welcome! SignIn to experience."];
    textSize = [AppUtils getSizeWithText:headerContent withFont:[UIFont systemFontOfSize:28.0 weight:UIFontWeightBold] andMaxWidth:(SCREEN_WIDTH - 2*padding)];
    
    lbHeader.text = headerContent;
    lbHeader.numberOfLines = 5;
    lbHeader.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightBold];
    [lbHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imgLogo.mas_bottom).offset(20.0);
        make.left.equalTo(viewSignIn).offset(padding);
        make.right.equalTo(viewSignIn).offset(-padding);
        make.height.mas_equalTo(textSize.height);
    }];
    
    float hTextfield = 42.0;
    
    //  account textfield
    tfAccountID.textColor = UIColor.blackColor;
    [tfAccountID mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbHeader.mas_bottom).offset(30.0);
        make.left.right.equalTo(lbHeader);
        make.height.mas_equalTo(hTextfield);
    }];
    tfAccountID.borderStyle = UITextBorderStyleNone;
    tfAccountID.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hTextfield, hTextfield)];
    tfAccountID.leftViewMode = UITextFieldViewModeAlways;
    
    UILabel *lbAccount = [[UILabel alloc] init];
    lbAccount.backgroundColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                                 blue:(220/255.0) alpha:1.0];
    [tfAccountID addSubview: lbAccount];
    [lbAccount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(tfAccountID).offset(8.0);
        make.bottom.right.equalTo(tfAccountID);
        make.height.mas_equalTo(1.0);
    }];
    
    btnAccountID.enabled = NO;
    [btnAccountID setImage:[UIImage imageNamed:@"icon_acc"] forState:UIControlStateDisabled];
    btnAccountID.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [btnAccountID mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.equalTo(tfAccountID);
        make.width.mas_equalTo(hTextfield);
    }];
    
    //  password textfield
    tfPassword.secureTextEntry = YES;
    tfPassword.textColor = tfAccountID.textColor;
    [tfPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfAccountID.mas_bottom).offset(10.0);
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
    [btnPassword setImage:[UIImage imageNamed:@"icon_pass"] forState:UIControlStateDisabled];
    btnPassword.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [btnPassword mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.equalTo(tfPassword);
        make.width.mas_equalTo(hTextfield);
    }];
    
    //  signin button
    [btnSignIn setTitle:[[LanguageUtil sharedInstance] getContent:@"Sign In"] forState:UIControlStateNormal];
    btnSignIn.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    btnSignIn.backgroundColor = [UIColor colorWithRed:(50/255.0) green:(196/255.0) blue:(124/255.0) alpha:1.0];
    [btnSignIn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btnSignIn.layer.cornerRadius = 5.0;
    [btnSignIn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfPassword.mas_bottom).offset(20.0);
        make.left.right.equalTo(tfPassword);
        make.height.mas_equalTo(45.0);
    }];
    
    lbSepa.text = @"...";
    lbSepa.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0)
                                        blue:(102/255.0) alpha:1.0];
    [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnSignIn.mas_bottom);
        make.left.right.equalTo(btnSignIn);
        make.height.mas_equalTo(45.0);
    }];
    
    [btnQRCode setTitle:[[LanguageUtil sharedInstance] getContent:@"Or sign in with QRCode"] forState:UIControlStateNormal];
    btnQRCode.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
    btnQRCode.backgroundColor = [UIColor colorWithRed:(234/255.0) green:(238/255.0) blue:(243/255.0) alpha:1.0];
    [btnQRCode setTitleColor:[UIColor colorWithRed:(60/255.0) green:(75/255.0)
                                              blue:(102/255.0) alpha:1.0]
                    forState:UIControlStateNormal];
    btnQRCode.layer.cornerRadius = 5.0;
    [btnQRCode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbSepa.mas_bottom);
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
            icWaiting.hidden = YES;
            [icWaiting stopAnimating];
            
            [[NSUserDefaults standardUserDefaults] setObject:tfAccountID.text forKey:key_login];
            [[NSUserDefaults standardUserDefaults] setObject:tfPassword.text forKey:key_password];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
            break;
        }
        case LinphoneRegistrationNone:{
            NSLog(@"LinphoneRegistrationNone");
            
            break;
        }
        case LinphoneRegistrationCleared: {
            NSLog(@"LinphoneRegistrationCleared");
            break;
        }
        case LinphoneRegistrationFailed:
        {
            icWaiting.hidden = YES;
            [icWaiting stopAnimating];
            
            [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"Please check sign in information"] duration:2.0 position:CSToastPositionCenter];
            
            break;
        }
        case LinphoneRegistrationProgress: {
            NSLog(@"LinphoneRegistrationProgress");
            break;
        }
        default:
            break;
    }
}

- (IBAction)btnQRCodePress:(UIButton *)sender {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([QRCodeReader supportsMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]]) {
        QRCodeReader *reader = [QRCodeReader readerWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
        scanQRCodeVC = [QRCodeReaderViewController readerWithCancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"Cancel"] codeReader:reader startScanningAtLoad:YES showSwitchCameraButton:YES showTorchButton:YES];
        scanQRCodeVC.modalPresentationStyle = UIModalPresentationFormSheet;
        scanQRCodeVC.delegate = self;
        
        btnScanFromPhoto = [UIButton buttonWithType: UIButtonTypeCustom];
        btnScanFromPhoto.frame = CGRectMake((SCREEN_WIDTH-250)/2, SCREEN_HEIGHT-38-60, 250, 38);
        btnScanFromPhoto.backgroundColor = [UIColor colorWithRed:(2/255.0) green:(164/255.0)
                                                            blue:(247/255.0) alpha:1.0];
        [btnScanFromPhoto setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btnScanFromPhoto.layer.cornerRadius = btnScanFromPhoto.frame.size.height/2;
        btnScanFromPhoto.layer.borderColor = btnScanFromPhoto.backgroundColor.CGColor;
        btnScanFromPhoto.layer.borderWidth = 1.0;
        
        [btnScanFromPhoto setTitle:[[LanguageUtil sharedInstance] getContent:@"SCAN FROM PHOTO"]
                          forState:UIControlStateNormal];
        btnScanFromPhoto.titleLabel.font = [UIFont systemFontOfSize: 16.0];
        [btnScanFromPhoto addTarget:self
                             action:@selector(btnScanFromPhotoPressed)
                   forControlEvents:UIControlEventTouchUpInside];
        
        [scanQRCodeVC.view addSubview: btnScanFromPhoto];
        
        [scanQRCodeVC setCompletionWithBlock:^(NSString *resultAsString) {
            NSLog(@"Completion with result: %@", resultAsString);
        }];
        [self presentViewController:scanQRCodeVC animated:YES completion:NULL];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Reader not supported by the current device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
}

- (void)btnScanFromPhotoPressed {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    btnScanFromPhoto.backgroundColor = [UIColor whiteColor];
    [btnScanFromPhoto setTitleColor:[UIColor colorWithRed:(2/255.0) green:(164/255.0)
                                                     blue:(247/255.0) alpha:1.0]
                           forState:UIControlStateNormal];
    [self performSelector:@selector(choosePictureForScanQRCode) withObject:nil afterDelay:0.05];
}

- (void)choosePictureForScanQRCode {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    btnScanFromPhoto.backgroundColor = [UIColor colorWithRed:(2/255.0) green:(164/255.0)
                                                        blue:(247/255.0) alpha:1.0];
    [btnScanFromPhoto setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    pickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    pickerController.allowsEditing = NO;
    pickerController.delegate = self;
    [scanQRCodeVC presentViewController:pickerController animated:YES completion:nil];
}

#pragma mark - Image picker delegate
- (void)readerDidCancel:(QRCodeReaderViewController *)reader {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result {
    [reader stopScanning];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] result = %@", __FUNCTION__, result]
                             toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        
        icWaiting.hidden = NO;
        [icWaiting startAnimating];
        
        [self checkRegistrationInfoFromQRCode: result];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        [self dismissViewControllerAnimated:YES completion:NULL];
        
        NSString* type = [info objectForKey:UIImagePickerControllerMediaType];
        if ([type isEqualToString: (NSString*)kUTTypeImage] ) {
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            [self getQRCodeContentFromImage: image];
        }
    }];
}

- (void)getQRCodeContentFromImage: (UIImage *)image {
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
    if (![AppUtils isNullOrEmpty: qrcodeResult]) {
        NSArray *tmpArr = [qrcodeResult componentsSeparatedByString:@"/"];
        if (tmpArr != nil) {
            if (tmpArr.count == 2 || tmpArr.count == 4) {
                NSString *account = [tmpArr objectAtIndex: 0];
                NSString *password = [tmpArr objectAtIndex: 1];
                NSString *domain = DOMAIN_DEFAULT;
                NSString *port = PORT_DEFAULT;
                if (tmpArr.count == 4) {
                    domain = [tmpArr objectAtIndex: 2];
                    port = [tmpArr objectAtIndex: 3];
                }
                if (![AppUtils isNullOrEmpty: account] && ![AppUtils isNullOrEmpty: password] && ![AppUtils isNullOrEmpty: domain] && ![AppUtils isNullOrEmpty: port])
                {
                    icWaiting.hidden = NO;
                    [icWaiting startAnimating];
                    
                    tfAccountID.text = account;
                    tfPassword.text = password;
                    
                    [SipUtils registerPBXAccount:account password:password ipAddress:domain port:port];
                    return;
                }
            }
        }
    }
    icWaiting.hidden = YES;
    [icWaiting stopAnimating];
    [self showDialerQRCodeNotCorrect];
}

- (void)showDialerQRCodeNotCorrect {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[[LanguageUtil sharedInstance] getContent:@"Can not detect QRCode. Please check again!"] delegate:self cancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"Close"] otherButtonTitles: nil];
    [alertView show];
}

- (IBAction)btnStartPress:(UIButton *)sender {
}
@end
