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
#import "CustomSwitchButton.h"


@interface MoreViewController ()<UIAlertViewDelegate, WebServicesDelegate, CustomSwitchButtonDelegate> {
    float hInfo;
    NSMutableArray *listTitle;
    NSMutableArray *listIcon;
    WebServices *webService;
    
    UIActivityIndicatorView *icWaiting;
    float hCell;
    CustomSwitchButton *switchDND;
    BOOL isEnableDND;
    BOOL isDisableDND;
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
    if (webService == nil) {
        webService = [[WebServices alloc] init];
        webService.delegate = self;
    }
    
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
        NSString *accountID = [SipUtils getAccountIdOfDefaultProxyConfig];
        if (![AppUtils isNullOrEmpty: accountID] && accountID.length > 5) {
            NSString *ext = [accountID substringFromIndex: 5];
            lbPBXAccount.text = ext;
            
            lbPBXAccount.text = SFM(@"Số nội bộ: %@", ext);
            
            PhoneObject *contact = [ContactUtils getContactPhoneObjectWithNumber: ext];
            if (contact != nil) {
                _lbName.text = contact.name;
            }else{
                _lbName.text = ext;
            }
        }else{
            lbPBXAccount.text = SFM(@"Số nội bộ: %@", @"Không có");
            _lbName.text = @"Tài khoản: Chưa có";
        }
        
        NSString *pbxKeyAvatar = SFM(@"%@_%@", @"pbxAvatar", accountID);
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
    
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE])
    {
        hInfo = [LinphoneAppDelegate sharedInstance]._hRegistrationState + 40;
        wAvatar = 55.0;
        hCell = 55.0;
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
    _lbName.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [_lbName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imgAvatar);
        make.left.equalTo(_imgAvatar.mas_right).offset(5.0);
        make.right.equalTo(_viewHeader).offset(-5.0);
        make.bottom.equalTo(_imgAvatar.mas_centerY);
    }];
    
    lbPBXAccount.textColor = UIColor.whiteColor;
    lbPBXAccount.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
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
    listTitle = [[NSMutableArray alloc] initWithObjects: text_do_not_disturb, text_choose_ringtone, text_call_settings, text_app_info, text_send_reports, text_sign_out, text_privacy_policy, text_introduction, nil];
    
    listIcon = [[NSMutableArray alloc] initWithObjects: @"more_dnd", @"more_ringtone", @"more_call_settings", @"more_app_info", @"more_send_reports", @"more_signout", @"more_policy", @"more_support", nil];
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
    
    if (indexPath.row == eDNDMode) {
        cell.imgNext.hidden = YES;
        
        BOOL state = TRUE;
        NSString *dndMode = [[NSUserDefaults standardUserDefaults] objectForKey:switch_dnd];
        if (![dndMode isEqualToString:@"YES"]) {
            state = FALSE;
        }
        switchDND = [[CustomSwitchButton alloc] initWithState:state frame:CGRectMake(SCREEN_WIDTH-20-85.0, (hCell-32.0)/2, 85.0, 32.0)];
        switchDND.delegate = self;
        [cell addSubview: switchDND];
    }else{
        cell.imgNext.hidden = NO;
    }
    
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
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:text_confirm_sign_out delegate:self cancelButtonTitle:text_no otherButtonTitles:text_sign_out, nil];
            alertView.tag = 1;
            alertView.delegate = self;
            [alertView show];
            
            break;
        }
        case ePrivayPolicy:{
            [[PhoneMainView instance] changeCurrentView:[PolicyViewController compositeViewDescription] push:true];
            break;
        }
        case eIntroduction:{
            [[PhoneMainView instance] changeCurrentView:[IntroduceViewController compositeViewDescription] push:true];
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
    
    [LinphoneAppDelegate sharedInstance]._updateTokenSuccess = NO;
    NSString *params = SFM(@"pushtoken=%@&username=%@", @"", USERNAME);
    [webService callGETWebServiceWithFunction:update_token_func andParams:params];
    
    [WriteLogsUtils writeLogContent:SFM(@"[%s] params: %@", __FUNCTION__, params) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
}

- (void)startResetValueWhenLogout
{
    linphone_core_clear_proxy_config(LC);
    [self performSelector:@selector(goToSignView) withObject:nil afterDelay:1.0];
}

- (void)goToSignView {
    [icWaiting stopAnimating];
    icWaiting.hidden = YES;
    [LinphoneAppDelegate sharedInstance].configPushToken = NO;
    
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:switch_dnd];
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:key_password];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
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
    [WriteLogsUtils writeLogContent:SFM(@"[%s] link: %@, error: %@", __FUNCTION__, link, @[error]) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [icWaiting stopAnimating];
    icWaiting.hidden = TRUE;
    
    if ([link isEqualToString: update_token_func]) {
        if (isEnableDND) {
            [self.view makeToast:@"Đã xảy ra lỗi, vui lòng thử lại!" duration:2.0 position:CSToastPositionCenter];
            isEnableDND = FALSE;
            
        }else if (isDisableDND) {
            [self.view makeToast:@"Không tìm thấy push token" duration:2.0 position:CSToastPositionCenter];
            isDisableDND = FALSE;
        }else{
            [self startResetValueWhenLogout];
        }
    }
}

- (void)successfulToCallWebService:(NSString *)link withData:(NSDictionary *)data {
    [WriteLogsUtils writeLogContent:SFM(@"[%s] link: %@, data: %@", __FUNCTION__, link, @[data]) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([link isEqualToString: update_token_func]) {
        if (isEnableDND) {
            [icWaiting stopAnimating];
            icWaiting.hidden = TRUE;
            
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:switch_dnd];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self.view makeToast:@"Bạn đã bật chế độ \"Không làm phiền\"." duration:2.0 position:CSToastPositionCenter];
            isEnableDND = FALSE;
            
        }else if (isDisableDND){
            [icWaiting stopAnimating];
            icWaiting.hidden = TRUE;
            
            [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:switch_dnd];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self.view makeToast:@"Bạn đã tắt chế độ \"Không làm phiền\"." duration:2.0 position:CSToastPositionCenter];
            isDisableDND = FALSE;
        }else{
            [self startResetValueWhenLogout];
        }
    }else{
        [icWaiting stopAnimating];
        icWaiting.hidden = TRUE;
    }
}

-(void)receivedResponeCode:(NSString *)link withCode:(int)responeCode {
    
}

#pragma mark - Switch Custom Delegate
- (void)switchButtonEnabled
{
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if (![DeviceUtils checkNetworkAvailable]) {
        [self.view makeToast:text_check_network duration:2.0 position:CSToastPositionCenter];
        return;
    }
    
    [icWaiting startAnimating];
    icWaiting.hidden = NO;
    
    isEnableDND = TRUE;
    [self clearPushTokenOfUser];
}

- (void)switchButtonDisabled {
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if (![DeviceUtils checkNetworkAvailable]) {
        [self.view makeToast:text_check_network duration:2.0 position:CSToastPositionCenter];
        return;
    }
    
    [icWaiting startAnimating];
    icWaiting.hidden = NO;
    
    isDisableDND = TRUE;
    
    [self updateCustomerTokenIOS];
}

- (void)updateCustomerTokenIOS {
    if (USERNAME != nil && ![AppUtils isNullOrEmpty: [LinphoneAppDelegate sharedInstance]._deviceToken]) {
        NSString *destToken = SFM(@"ios%@", [LinphoneAppDelegate sharedInstance]._deviceToken);
        NSString *params = SFM(@"pushtoken=%@&username=%@", destToken, USERNAME);
        [webService callGETWebServiceWithFunction:update_token_func andParams:params];
        
        [WriteLogsUtils writeLogContent:SFM(@"[%s] params: %@", __FUNCTION__, params) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    }else{
        [icWaiting stopAnimating];
        icWaiting.hidden = YES;
        [self.view makeToast:@"Không tìm thấy push token" duration:2.0 position:CSToastPositionCenter];
        
        [WriteLogsUtils writeLogContent:SFM(@"[%s] >>>>> Không tìm thấy push token <<<<<", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    }
}

@end
