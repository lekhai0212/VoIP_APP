//
//  MoreViewController.m
//  linphone
//
//  Created by user on 1/7/14.
//
//

#import "MoreViewController.h"
#import "MenuCell.h"
#import "ChooseRingtoneViewController.h"
#import "KSettingViewController.h"
#import "SignInViewController.h"
#import "AboutViewController.h"
#import "SendLogsViewController.h"
#import "PolicyViewController.h"
#import "IntroduceViewController.h"
#import "TabBarView.h"
#import "StatusBarView.h"
#import "NSData+Base64.h"
#import "JSONKit.h"
#import "WebServices.h"


@interface MoreViewController ()<UIAlertViewDelegate, WebServicesDelegate> {
    float hInfo;
    NSMutableArray *listTitle;
    NSMutableArray *listIcon;
    WebServices *webService;
    
    UIActivityIndicatorView *icWaiting;
    float hCell;
}

@end

@implementation MoreViewController
@synthesize _viewHeader, bgHeader, _imgAvatar, _lbName, lbPBXAccount, _tbContent;

#pragma mark - UICompositeViewDelegate Functions
static UICompositeViewDescription *compositeDescription = nil;
+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:nil
                                                                 tabBar:TabBarView.class
                                                               sideMenu:nil
                                                             fullscreen:FALSE
                                                         isLeftFragment:YES
                                                           fragmentWith:0];
//        compositeDescription.darkBackground = true;
    }
    return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
    return self.class.compositeViewDescription;
}

#pragma mark - my controller

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createDataForMenuView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    
    [WriteLogsUtils writeForGoToScreen: @"MoreViewController"];
    
    [self autoLayoutForMainView];
    
    [self showContentWithCurrentLanguage];
    
    [self updateInformationOfUser];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - my functions

- (void)showContentWithCurrentLanguage {
    [self createDataForMenuView];
    [_tbContent reloadData];
}

- (void)updateInformationOfUser
{
    if ([SipUtils getStateOfDefaultProxyConfig] != eAccountNone)
    {
        _lbName.text = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Account"], USERNAME];
        
        NSString *accountID = [SipUtils getAccountIdOfDefaultProxyConfig];
        if (![AppUtils isNullOrEmpty: accountID] && accountID.length > 5) {
            NSString *ext = [accountID substringFromIndex: 5];
            lbPBXAccount.text = ext;
            
            lbPBXAccount.text = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Extension"], ext];
        }else{
            lbPBXAccount.text = [NSString stringWithFormat:@"%@: %@", [[LanguageUtil sharedInstance] getContent:@"Extension"], @"N/A"];
        }
        
        NSString *pbxKeyAvatar = [NSString stringWithFormat:@"%@_%@", @"pbxAvatar", accountID];
        NSString *avatar = [[NSUserDefaults standardUserDefaults] objectForKey: pbxKeyAvatar];
        if (avatar != nil && ![avatar isEqualToString:@""]){
            _imgAvatar.image = [UIImage imageWithData: [NSData dataFromBase64String: avatar]];
        }else{
            _imgAvatar.image = [UIImage imageNamed:@"no_avatar.png"];
        }
        [self showProfileView: YES];
    }else{
        [self showProfileView: NO];
    }
}

- (void)showProfileView: (BOOL)show {
    _imgAvatar.hidden = !show;
    lbPBXAccount.hidden = !show;
    _lbName.hidden = !show;
}

//  Cập nhật vị trí cho view
- (void)autoLayoutForMainView {
    self.view.backgroundColor = [UIColor colorWithRed:(243/255.0) green:(244/255.0)
                                                 blue:(248/255.0) alpha:1.0];
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    hInfo = [LinphoneAppDelegate sharedInstance]._hRegistrationState + 50;
    float wAvatar = 65.0;
    hCell = 60.0;
    
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE] || [deviceMode isEqualToString: simulator])
    {
        hInfo = [LinphoneAppDelegate sharedInstance]._hRegistrationState + 40;
        wAvatar = 55.0;
        _lbName.font = [UIFont fontWithName:MYRIADPRO_BOLD size: 16.0];
        lbPBXAccount.font = [UIFont fontWithName:MYRIADPRO_REGULAR size: 15.0];
        hCell = 55.0;
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2])
    {
        _lbName.font = [UIFont fontWithName:MYRIADPRO_BOLD size: 16.0];
        lbPBXAccount.font = [UIFont fontWithName:MYRIADPRO_REGULAR size: 15.0];
        
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2])
    {
        _lbName.font = [UIFont fontWithName:MYRIADPRO_BOLD size: 17.0];
        lbPBXAccount.font = [UIFont fontWithName:MYRIADPRO_REGULAR size: 16.0];
        
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2])
    {
        _lbName.font = [UIFont fontWithName:MYRIADPRO_BOLD size: 17.0];
        lbPBXAccount.font = [UIFont fontWithName:MYRIADPRO_REGULAR size: 16.0];
        
    }
    //  Header view
    [_viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hInfo);
    }];
    
    [bgHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(_viewHeader);
    }];
    
    [_imgAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_viewHeader).offset(10);
        make.centerY.equalTo(_viewHeader.mas_centerY).offset([LinphoneAppDelegate sharedInstance]._hStatus/2);
        make.width.height.mas_equalTo(wAvatar);
    }];
    _imgAvatar.clipsToBounds = YES;
    _imgAvatar.layer.cornerRadius = wAvatar/2;
    _imgAvatar.layer.borderColor = [UIColor colorWithRed:(96/255.0) green:(195/255.0)
                                                    blue:(66/255.0) alpha:1.0].CGColor;
    _imgAvatar.layer.borderWidth = 2.0;
    
    _lbName.textColor = UIColor.whiteColor;
    [_lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imgAvatar);
        make.left.equalTo(_imgAvatar.mas_right).offset(5.0);
        make.right.equalTo(_viewHeader).offset(-5.0);
        make.bottom.equalTo(_imgAvatar.mas_centerY);
    }];
    
    lbPBXAccount.textColor = UIColor.whiteColor;
    [lbPBXAccount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lbName.mas_bottom);
        make.left.right.equalTo(_lbName);
        make.bottom.equalTo(_imgAvatar.mas_bottom);
    }];
    
    _tbContent.backgroundColor = UIColor.clearColor;
    [_tbContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader.mas_bottom);
        make.left.bottom.right.equalTo(self.view);
    }];
    _tbContent.delegate = self;
    _tbContent.dataSource = self;
    _tbContent.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tbContent.scrollEnabled = NO;
    
    icWaiting = [[UIActivityIndicatorView alloc] init];
    icWaiting.backgroundColor = UIColor.whiteColor;
    icWaiting.alpha = 0.5;
    icWaiting.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    icWaiting.hidden = YES;
    [self.view addSubview: icWaiting];
    [icWaiting mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//  Khoi tao du lieu cho view
- (void)createDataForMenuView {
    listTitle = [[NSMutableArray alloc] initWithObjects: [[LanguageUtil sharedInstance] getContent:@"Choose ringtone"], [[LanguageUtil sharedInstance] getContent:@"Call settings"], [[LanguageUtil sharedInstance] getContent:@"App information"], [[LanguageUtil sharedInstance] getContent:@"Send reports"], [[LanguageUtil sharedInstance] getContent:@"Sign out"], [[LanguageUtil sharedInstance] getContent:@"Privacy & Policy"], [[LanguageUtil sharedInstance] getContent:@"Answer & Support"], nil];
    
    listIcon = [[NSMutableArray alloc] initWithObjects: @"more_ringtone", @"more_call_settings", @"more_app_info", @"more_send_reports", @"more_signout", @"more_policy", @"more_support", nil];
}

#pragma mark - uitableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return listTitle.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"MenuCell";
    MenuCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MenuCell" owner:self options:nil];
        cell = topLevelObjects[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row <= eSignOut) {
        cell.contentView.backgroundColor = UIColor.whiteColor;
        if (indexPath.row == eSendLogs) {
            cell._lbSepa.hidden = NO;
            cell._lbSepa.backgroundColor = self.view.backgroundColor;
        }else{
            cell._lbSepa.hidden = YES;
        }
    }else{
        cell._lbSepa.hidden = YES;
        cell.contentView.backgroundColor = UIColor.clearColor;
    }
    
    cell._iconImage.image = [UIImage imageNamed:[listIcon objectAtIndex: indexPath.row]];
    cell._lbTitle.text = [listTitle objectAtIndex:indexPath.row];
    cell._iconImage.hidden = NO;
    cell._lbTitle.textAlignment = NSTextAlignmentLeft;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case eRingtone:{
            [[PhoneMainView instance] changeCurrentView:[ChooseRingtoneViewController compositeViewDescription] push:true];
            break;
        }
        case eCallSettings:{
            [[PhoneMainView instance] changeCurrentView:[SettingsView compositeViewDescription] push:true];
            break;
        }
        case eAppInfo:{
            [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:true];
            break;
        }
        case eSendLogs:{
            [[PhoneMainView instance] changeCurrentView:[SendLogsViewController compositeViewDescription] push:true];
            break;
        }
        case eSignOut:{
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:[[LanguageUtil sharedInstance] getContent:@"Do you want to log out?"] delegate:self cancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"No"] otherButtonTitles:[[LanguageUtil sharedInstance] getContent:@"Sign out"], nil];
            alertView.tag = 1;
            alertView.delegate = self;
            [alertView show];
            
            break;
        }
        case ePrivayPolicy:{
            //  [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:true];
            break;
        }
        case eAnswerSupport:{
            //  [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:true];
            break;
        }
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return hCell;
}

- (void)startLogout {
    [icWaiting startAnimating];
    icWaiting.hidden = NO;
    
    [[LinphoneAppDelegate sharedInstance] showWaiting: YES];
    
    //  clear token to avoid push when user signed out
    [self clearPushTokenOfUser];
}

- (void)clearPushTokenOfUser {
    if (webService == nil) {
        webService = [[WebServices alloc] init];
        webService.delegate = self;
    }
    [LinphoneAppDelegate sharedInstance]._updateTokenSuccess = NO;
    
    NSString *destToken = [NSString stringWithFormat:@"ios%@",  [LinphoneAppDelegate sharedInstance]._deviceToken];
    NSString *params = [NSString stringWithFormat:@"pushToken=%@&userName=%@&del=1", destToken, USERNAME];
    [webService callGETWebServiceWithFunction:update_token_func andParams:params];
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] params = %@", __FUNCTION__, params] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
}

- (void)startResetValueWhenLogout
{
    linphone_core_clear_proxy_config(LC);
    [icWaiting stopAnimating];
    icWaiting.hidden = YES;
    [LinphoneAppDelegate sharedInstance].configPushToken = NO;
    
    [[PhoneMainView instance] changeCurrentView:[SignInViewController compositeViewDescription]];
}

#pragma mark - UIAlertview delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [self startLogout];
        }
    }
}

#pragma mark - Webservice delegate
- (void)failedToCallWebService:(NSString *)link andError:(id)error {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] link: %@\nError: %@", __FUNCTION__ , link, @[error]] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([link isEqualToString: update_token_func]) {
        [self startResetValueWhenLogout];
    }
}

- (void)successfulToCallWebService:(NSString *)link withData:(NSDictionary *)data {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] link: %@\nData: %@", __FUNCTION__ , link, @[data]] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    if ([link isEqualToString: update_token_func]) {
        [self startResetValueWhenLogout];
    }
}

-(void)receivedResponeCode:(NSString *)link withCode:(int)responeCode {
    
}



@end
