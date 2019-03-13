//
//  MoreViewController.m
//  linphone
//
//  Created by user on 1/7/14.
//
//

#import "MoreViewController.h"
#import "MenuCell.h"
#import "EditProfileViewController.h"
#import "AccountSettingsViewController.h"
#import "KSettingViewController.h"
#import "PolicyViewController.h"
#import "IntroduceViewController.h"
#import "SendLogsViewController.h"
#import "AboutViewController.h"
#import "DrawingViewController.h"
#import "TabBarView.h"
#import "StatusBarView.h"
#import "NSData+Base64.h"
#import "JSONKit.h"

@interface MoreViewController () {
    float hInfo;
    NSMutableArray *listTitle;
    NSMutableArray *listIcon;
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
    
    // Tắt màn hình cảm biến
    UIDevice *device = [UIDevice currentDevice];
    [device setProximityMonitoringEnabled: NO];
    
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
    if ([SipUtils getStateOfDefaultProxyConfig] != eAccountNone) {
        NSString *accountID = [SipUtils getAccountIdOfDefaultProxyConfig];
        if (![AppUtils isNullOrEmpty: accountID] && accountID.length > 5) {
            NSString *ext = [accountID substringFromIndex: 5];
            lbPBXAccount.text = ext;
            lbPBXAccount.text = [NSString stringWithFormat:@"Số nội bộ: %@", ext];
        }else{
            lbPBXAccount.text = [NSString stringWithFormat:@"Số nội bộ: %@", @"N/A"];
        }
        
        NSString *pbxKeyName = [NSString stringWithFormat:@"%@_%@", @"pbxName", accountID];
        NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey: pbxKeyName];
        if (name != nil){
            _lbName.text = name;
        }else{
            _lbName.text = [[LanguageUtil sharedInstance] getContent:@"Not set"];
        }
        
        NSString *pbxKeyAvatar = [NSString stringWithFormat:@"%@_%@", @"pbxAvatar", accountID];
        NSString *avatar = [[NSUserDefaults standardUserDefaults] objectForKey: pbxKeyAvatar];
        if (avatar != nil && ![avatar isEqualToString:@""]){
            _imgAvatar.image = [UIImage imageWithData: [NSData dataFromBase64String: avatar]];
        }else{
            _imgAvatar.image = [UIImage imageNamed:@"no_avatar.png"];
            [self downloadMyAvatar: accountID];
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
    if ([SipUtils getStateOfDefaultProxyConfig] == eAccountNone) {
        hInfo = [LinphoneAppDelegate sharedInstance]._hRegistrationState + 100;
    }else{
        hInfo = [LinphoneAppDelegate sharedInstance]._hRegistrationState + 50;
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
        make.width.height.mas_equalTo(55.0);
    }];
    _imgAvatar.clipsToBounds = YES;
    _imgAvatar.layer.cornerRadius = 55.0/2;
    _imgAvatar.layer.borderColor = [UIColor colorWithRed:(96/255.0) green:(195/255.0)
                                                    blue:(66/255.0) alpha:1.0].CGColor;
    _imgAvatar.layer.borderWidth = 2.0;
    
    _lbName.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
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
        cell._lbTitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    }else{
        cell._lbSepa.hidden = YES;
        cell.contentView.backgroundColor = UIColor.clearColor;
        cell._lbTitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
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
            //  [[PhoneMainView instance] changeCurrentView:[AccountSettingsViewController compositeViewDescription] push:true];
            break;
        }
        case eCallSettings:{
            [[PhoneMainView instance] changeCurrentView:[SettingsView compositeViewDescription] push:true];
            break;
        }
        case eAppInfo:{
            //  [[PhoneMainView instance] changeCurrentView:[SendLogsViewController compositeViewDescription] push:true];
            break;
        }
        case eSendLogs:{
            //  [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:true];
            break;
        }
        case eSignOut:{
            //  [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:true];
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
    return 60.0;
}

- (IBAction)icEditClicked:(UIButton *)sender {
    [[PhoneMainView instance] changeCurrentView:[EditProfileViewController compositeViewDescription]
                                           push:YES];
}

- (void)downloadMyAvatar: (NSString *)myaccount
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *pbxServer = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_SERVER];
        NSString *avatarName = [NSString stringWithFormat:@"%@_%@.png", pbxServer, myaccount];
        NSString *linkAvatar = [NSString stringWithFormat:@"%@/%@", link_picture_chat_group, avatarName];
        NSData *data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: linkAvatar]];
        
        if (data != nil) {
            NSString *folder = [NSString stringWithFormat:@"/avatars/%@", avatarName];
            [AppUtils saveFileToFolder:data withName: folder];
            
            //  save avatar to get from local
            NSString *pbxKeyAvatar = [NSString stringWithFormat:@"%@_%@", @"pbxAvatar", myaccount];
            
            NSString *strAvatar = @"";
            if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
                strAvatar = [data base64EncodedStringWithOptions: 0];
            } else {
                strAvatar = [data base64Encoding];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:strAvatar forKey:pbxKeyAvatar];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                _imgAvatar.image = [UIImage imageWithData: data];
            });
        }
    });
}

- (void)btnSignOutPress {
    
}

@end
