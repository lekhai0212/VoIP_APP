//
//  AccountSettingsViewController.m
//  linphone
//
//  Created by Apple on 4/26/17.
//
//

#import "AccountSettingsViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NewSettingCell.h"
#import "PBXSettingViewController.h"
#import "ManagerPasswordViewController.h"

@interface AccountSettingsViewController (){
    LinphoneAppDelegate *appDelegate;
    AccountState stateAccount;
}
@end

@implementation AccountSettingsViewController
@synthesize _viewHeader, bgHeader, _iconBack, _lbHeader, _tbContent;

#pragma mark - UICompositeViewDelegate Functions
static UICompositeViewDescription *compositeDescription = nil;
+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:nil
                                                                 tabBar:nil
                                                               sideMenu:nil
                                                             fullscreen:FALSE
                                                         isLeftFragment:YES
                                                           fragmentWith:nil];
        compositeDescription.darkBackground = true;
    }
    return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
    return self.class.compositeViewDescription;
}

#pragma mark - My Controller Delegate

- (void)viewDidLoad {
    [super viewDidLoad];
    //  my code here
    appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self autoLayoutForMainView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    [WriteLogsUtils writeForGoToScreen:@"AccountSettingsViewController"];
    
    _lbHeader.text = [appDelegate.localization localizedStringForKey:@"Account settings"];
    stateAccount = [SipUtils getStateOfDefaultProxyConfig];
    [_tbContent reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidUnload {
    [self set_viewHeader: nil];
    [self set_iconBack:nil];
    [self set_lbHeader: nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)_iconBackClicked:(UIButton *)sender {
    [self.view endEditing: true];
    [[PhoneMainView instance] popCurrentView];
}

#pragma mark - LE KHAI

- (void)autoLayoutForMainView {
    if (SCREEN_WIDTH > 320) {
        _lbHeader.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
    }else{
        _lbHeader.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    }
    self.view.backgroundColor = [UIColor colorWithRed:(230/255.0) green:(230/255.0)
                                                 blue:(230/255.0) alpha:1.0];

    //  Header view
    [_viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(appDelegate._hRegistrationState);
    }];
    
    [bgHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(_viewHeader);
    }];
    
    [_lbHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset(appDelegate._hStatus);
        make.bottom.equalTo(_viewHeader);
        make.centerX.equalTo(_viewHeader.mas_centerX);
        make.width.mas_equalTo(200);
    }];
    
    [_iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_viewHeader);
        make.centerY.equalTo(_lbHeader.mas_centerY);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    _tbContent.backgroundColor = UIColor.clearColor;
    [_tbContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    _tbContent.delegate = self;
    _tbContent.dataSource = self;
    _tbContent.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tbContent.scrollEnabled = NO;
}

#pragma mark - UITableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([SipUtils getStateOfDefaultProxyConfig] == eAccountNone) {
        return 1;
    }
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"NewSettingCell";
    NewSettingCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"NewSettingCell" owner:self options:nil];
        cell = topLevelObjects[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch (indexPath.section) {
        case 0:{
            cell.lbTitle.text = [appDelegate.localization localizedStringForKey:@"PBX account"];
            
            switch (stateAccount) {
                case eAccountNone:
                    cell.lbDescription.text = [appDelegate.localization localizedStringForKey:@"No account"];
                    break;
                case eAccountOff:{
                    cell.lbDescription.text = [appDelegate.localization localizedStringForKey:@"Disabled"];
                    break;
                }
                case eAccountOn:{
                    cell.lbDescription.text = [appDelegate.localization localizedStringForKey:@"Enabled"];
                    break;
                }
            }
            
            break;
        }
        case 1:{
            cell.lbTitle.text = [appDelegate.localization localizedStringForKey:@"Change password"];
            [cell.lbTitle mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(cell).offset(10);
                make.right.equalTo(cell.imgArrow).offset(-10);
                make.top.bottom.equalTo(cell);
            }];
            cell.lbDescription.text = @"";
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] indexPath row = %d", __FUNCTION__, (int)indexPath.row] toFilePath:appDelegate.logFilePath];
    
    if (indexPath.section == 0) {
        [[PhoneMainView instance] changeCurrentView:[PBXSettingViewController compositeViewDescription] push:YES];
    }else if (indexPath.section == 1){
        if (stateAccount == eAccountNone) {
            [self.view makeToast:[appDelegate.localization localizedStringForKey:@"No account"] duration:3.0 position:CSToastPositionCenter];
        }else{
            [[PhoneMainView instance] changeCurrentView:[ManagerPasswordViewController compositeViewDescription] push:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    return 10;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

@end
