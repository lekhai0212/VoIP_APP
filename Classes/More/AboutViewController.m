//
//  AboutViewController.m
//  linphone
//
//  Created by lam quang quan on 10/26/18.
//

#import "AboutViewController.h"

@interface AboutViewController (){
    NSString *linkToAppStore;
    NSString* appStoreVersion;
}
@end

@implementation AboutViewController
@synthesize viewHeader, icBack, bgHeader, lbHeader, imgAppLogo, lbVersion, btnCheckForUpdate;

#pragma mark - UICompositeViewDelegate Functions
static UICompositeViewDescription *compositeDescription = nil;
+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:nil
                                                                 tabBar:nil
                                                               sideMenu:nil
                                                             fullscreen:NO
                                                         isLeftFragment:YES
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
    //  my code here
    [self setupUIForView];
}

- (void)viewWillAppear:(BOOL)animated {
    [WriteLogsUtils writeForGoToScreen:@"AboutViewController"];
    
    linkToAppStore = @"";
    lbHeader.text = [[LanguageUtil sharedInstance] getContent:@"App information"];
    [btnCheckForUpdate setTitle:[[LanguageUtil sharedInstance] getContent:@"Check for update"] forState:UIControlStateNormal];
    
    NSString *str = [NSString stringWithFormat:@"%@: %@\n%@: %@", [[LanguageUtil sharedInstance] getContent:@"Version"], [AppUtils getAppVersionWithBuildVersion: YES], [[LanguageUtil sharedInstance] getContent:@"Release date"], [AppUtils getBuildDate]];
    lbVersion.text = str;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)icBackClick:(UIButton *)sender {
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)btnCheckForUpdatePress:(UIButton *)sender {
    if (![DeviceUtils checkNetworkAvailable]) {
        [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"Please check your internet connection!"] duration:1.5 position:CSToastPositionBottom style:nil];
        return;
    }
    
    //  Add new by Khai Le on 23/03/2018
    linkToAppStore = [self checkNewVersionOnAppStore];
    if (![AppUtils isNullOrEmpty: linkToAppStore] && ![AppUtils isNullOrEmpty: appStoreVersion]) {
        NSString *content = [NSString stringWithFormat:[[LanguageUtil sharedInstance] getContent:@"Current version on App Store is %@. Do you want to update right now?"], appStoreVersion];
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"] message:content delegate:self cancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"Close"] otherButtonTitles:[[LanguageUtil sharedInstance] getContent:@"Update"], nil];
        alert.tag = 2;
        [alert show];
    }else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:[[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"] message:[[LanguageUtil sharedInstance] getContent:@"You are the newest version!"] delegate:self cancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"Close"] otherButtonTitles:nil, nil];
        [alert show];
    }
    return;
    //  -----
}

#pragma mark - my functions

- (NSString *)checkNewVersionOnAppStore {
    return @"";
    
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString* appID = infoDictionary[@"CFBundleIdentifier"];
    if (appID.length > 0) {
        NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", appID]];
        NSData* data = [NSData dataWithContentsOfURL:url];
        
        if (data) {
            NSDictionary* lookup = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            if ([lookup[@"resultCount"] integerValue] == 1){
                appStoreVersion = lookup[@"results"][0][@"version"];
                NSString* currentVersion = infoDictionary[@"CFBundleShortVersionString"];
                
                if ([appStoreVersion compare:currentVersion options:NSNumericSearch] == NSOrderedDescending) {
                    // app needs to be updated
                    return lookup[@"results"][0][@"trackViewUrl"] ? lookup[@"results"][0][@"trackViewUrl"] : @"";
                }
            }
        }
    }
    
    return @"";
}

//  setup ui trong view
- (void)setupUIForView
{
    if (SCREEN_WIDTH > 320) {
        icBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        lbHeader.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
        lbVersion.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
        btnCheckForUpdate.titleLabel.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
    }else{
        icBack.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7);
        lbHeader.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
        lbVersion.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
        btnCheckForUpdate.titleLabel.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    }
    
    //  header view
    [viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo([LinphoneAppDelegate sharedInstance]._hRegistrationState);
    }];
    
    [bgHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(viewHeader);
    }];
    
    
    [lbHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.bottom.equalTo(viewHeader);
        make.centerX.equalTo(viewHeader.mas_centerX);
        make.width.mas_equalTo(200);
    }];
    
    [icBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(viewHeader);
        make.centerY.equalTo(lbHeader.mas_centerY);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    //
    imgAppLogo.clipsToBounds = YES;
    imgAppLogo.layer.cornerRadius = 10.0;
    [imgAppLogo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(viewHeader.mas_bottom).offset(30.0);
        make.width.height.mas_equalTo(120.0);
    }];
    
    
    lbVersion.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    [lbVersion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(imgAppLogo.mas_bottom).offset(40.0);
        make.left.equalTo(self.view).offset(20.0);
        make.right.equalTo(self.view).offset(-20.0);
        make.height.mas_lessThanOrEqualTo(100.0);
    }];
    
    
    [btnCheckForUpdate setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btnCheckForUpdate.backgroundColor = [UIColor colorWithRed:(101/255.0) green:(205/255.0)
                                                         blue:(70/255.0) alpha:1.0];
    btnCheckForUpdate.clipsToBounds = YES;
    btnCheckForUpdate.layer.cornerRadius = 45.0/2;
    [btnCheckForUpdate mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lbVersion.mas_bottom).offset(40.0);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.mas_equalTo(200.0);
        make.height.mas_equalTo(45.0);
    }];
}

#pragma mark - UIAlertview Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2 && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkToAppStore]];
    }
}

@end
