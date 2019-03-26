/* DialerViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import "PBXSettingViewController.h"
#import "LinphoneManager.h"
#import <AVFoundation/AVFoundation.h>
#import "PhoneBookContactCell.h"
#import "NSData+Base64.h"
#import <objc/runtime.h>
#import "ContactDetailObj.h"
#import "UIVIew+Toast.h"

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "PBXContact.h"
#import "AESCrypt.h"

@interface DialerView (){
    LinphoneAppDelegate *appDelegate;
    NSMutableArray *listPhoneSearched;
    
    UITapGestureRecognizer *tapOnScreen;
    NSTimer *pressTimer;
    
    SearchContactPopupView *popupSearchContacts;
    
    WebServices *webService;
    
    UIView *resultView;
    UIImageView *imgAvatar;
    UILabel *lbName;
    UILabel *lbPhone;
    UIButton *btnSearchNum;
    UIButton *btnChooseContact;
    float hAddressField;
}
@end

@implementation DialerView
@synthesize _viewStatus, _imgLogoSmall, _lbAccount, _lbStatus;
@synthesize _viewNumber, icClear;
@synthesize lbSepa123, lbSepa456, lbSepa789, btnVideoCall;

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:self.class
															  statusBar:StatusBarView.class
																 tabBar:TabBarView.class
															   sideMenu:SideMenuView.class
															 fullscreen:false
														 isLeftFragment:YES
														   fragmentWith:nil];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
	return self.class.compositeViewDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [WriteLogsUtils writeForGoToScreen: @"DialerView"];
    
    if (webService == nil) {
        webService = [[WebServices alloc] init];
        webService.delegate = self;
    }
    
//    NSString* path = [[NSBundle mainBundle] pathForResource:@"file_encrypt"
//                                                     ofType:@"txt"];
//
//    NSString* content = [NSString stringWithContentsOfFile:path
//                                                  encoding:NSUTF8StringEncoding
//                                                     error:NULL];
//    NSString *decrypt = [AESCrypt decrypt:content password:AES_KEY];
//    NSLog(@"%@", decrypt);
    
    //  Added by Khai Le on 30/09/2018
    [self checkAccountForApp];
    
    //  setup cho key login
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"enable_first_login_view_preference"];
    
    // invisible icon add contact & icon delete address
    [self hideSearchView];
    
    //  update token of device if not yet
    if (![LinphoneAppDelegate sharedInstance]._updateTokenSuccess && ![AppUtils isNullOrEmpty: [LinphoneAppDelegate sharedInstance]._deviceToken])
    {
        [WriteLogsUtils writeLogContent:@"You haven't updated token device. Posted event updateTokenForXmpp" toFilePath:appDelegate.logFilePath];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:updateTokenForXmpp
                                                            object:nil];
    }
    
	_padView.hidden =
		!IPAD && UIInterfaceOrientationIsLandscape(PhoneMainView.instance.mainViewController.currentOrientation);

	// Set observer
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdateEvent:)
											   name:kLinphoneCallUpdate object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkDown)
                                                 name:@"NetworkDown" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whenNetworkChanged)
                                                 name:networkChanged object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(registrationUpdateEvent:)
                                               name:kLinphoneRegistrationUpdate object:nil];
    
	// Update on show
	LinphoneCall *call = linphone_core_get_current_call(LC);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state];

    [self enableNAT];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self];
    
    webService = nil;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self newAutoLayoutForView];
    [self createSearchViewIfNeed];
    
    //  my code here
    _zeroButton.digit = '0';
    _oneButton.digit = '1';
    _twoButton.digit = '2';
    _threeButton.digit = '3';
    _fourButton.digit = '4';
    _fiveButton.digit = '5';
    _sixButton.digit = '6';
    _sevenButton.digit = '7';
    _eightButton.digit = '8';
    _nineButton.digit = '9';
    _starButton.digit = '*';
    _hashButton.digit = '#';
    
    _addressField.adjustsFontSizeToFitWidth = YES;
	
	UILongPressGestureRecognizer *backspaceLongGesture =
		[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onBackspaceLongClick:)];
	[_backspaceButton addGestureRecognizer:backspaceLongGesture];

	UILongPressGestureRecognizer *zeroLongGesture =
		[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onZeroLongClick:)];
	[_zeroButton addGestureRecognizer:zeroLongGesture];

	UILongPressGestureRecognizer *oneLongGesture =
		[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onOneLongClick:)];
	[_oneButton addGestureRecognizer:oneLongGesture];
	
    //  Tap tren ban phim
	tapOnScreen = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboards)];
    tapOnScreen.delegate = self;
	[self.view addGestureRecognizer: tapOnScreen];

    _lbStatus.text = @"";
}

-(void)viewDidLayoutSubviews {
    //  _imgLogoSmall.hidden = YES;
    if ([_addressField.text isEqualToString:@""]) {
        icClear.hidden = YES;
    }else{
        icClear.hidden = NO;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			break;
		case UIInterfaceOrientationLandscapeLeft:
			break;
		case UIInterfaceOrientationLandscapeRight:
			break;
		default:
			break;
	}
	_padView.hidden = !IPAD && UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[LinphoneManager.instance shouldPresentLinkPopup];
}

#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:call state:state];
}

#pragma mark -

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state {
    LinphoneCore *lc = [LinphoneManager getLc];
    // ở keypad mà số cuộc gọi lớn hơn 0 nghĩa là đang add call cho conference hoặc transfer
    if(linphone_core_get_calls_nb(lc) > 0) {
        _callButton.hidden = YES;
    } else {
        _callButton.hidden = NO;
    }
    /*  Leo Kelvin
	BOOL callInProgress = (linphone_core_get_calls_nb(LC) > 0);
	_addContactButton.hidden = callInProgress;
	_backButton.hidden = !callInProgress;
    */
    
    //  Close by Khai Le on 06/10/2017
	//  [_callButton updateIcon];
}

- (void)setAddress:(NSString *)address {
    _addressField.text = address;
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
    [self performSelector:@selector(searchPhoneBookWithThread) withObject:nil afterDelay:0.25];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == _addressField) {
		[_addressField resignFirstResponder];
	}
	if (textField.text.length > 0) {
		LinphoneAddress *addr = [LinphoneUtils normalizeSipOrPhoneAddress:textField.text];
		[LinphoneManager.instance call:addr];
		if (addr)
			linphone_address_destroy(addr);
	}
	return YES;
}

#pragma mark - MFComposeMailDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
	[controller dismissViewControllerAnimated:TRUE
								   completion:^{
								   }];
	[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
}

#pragma mark - Action Functions

- (IBAction)btnVideoCallPress:(UIButton *)sender {
    if (_addressField.text.length > 0) {
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] With _addressField.text = %@", __FUNCTION__, _addressField.text] toFilePath:appDelegate.logFilePath];
        [self setupFrameForSearchResultWithExistsData: NO];
        icClear.hidden = NO;
        
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:IS_VIDEO_CALL_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [LinphoneAppDelegate sharedInstance].phoneForCall = _addressField.text;
        [[NSNotificationCenter defaultCenter] postNotificationName:getDIDListForCall object:nil];
        
        return;
    }
    [self fillPhoneNumberLastCall];
    
    [pressTimer invalidate];
    pressTimer = nil;
    pressTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
                                                selector:@selector(searchPhoneBookWithThread)
                                                userInfo:nil repeats:false];
}

- (IBAction)onAddressChange:(id)sender {
    if ([_addressField.text length] == 0) {
        [self.view endEditing:YES];
    }
}

- (IBAction)onBackspaceClick:(id)sender {
    if (_addressField.text.length > 0) {
        _addressField.text = [_addressField.text substringToIndex:[_addressField.text length] - 1];
    }
	
    if (_addressField.text.length > 0) {
        [pressTimer invalidate];
        pressTimer = nil;
        pressTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
                                                    selector:@selector(searchPhoneBookWithThread)
                                                    userInfo:nil repeats:false];
    }else{
        resultView.hidden = YES;
    }
}

- (void)onBackspaceLongClick:(id)sender {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    [self hideSearchView];
    [self setupFrameForSearchResultWithExistsData: NO];
}

- (void)onZeroLongClick:(id)sender {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
	// replace last character with a '+'
	NSString *newAddress =
		[[_addressField.text substringToIndex:[_addressField.text length] - 1] stringByAppendingString:@"+"];
	[_addressField setText:newAddress];
	linphone_core_stop_dtmf(LC);
}

- (void)onOneLongClick:(id)sender {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
	LinphoneManager *lm = LinphoneManager.instance;
	NSString *voiceMail = [lm lpConfigStringForKey:@"voice_mail_uri"];
	LinphoneAddress *addr = [LinphoneUtils normalizeSipOrPhoneAddress:voiceMail];
	if (addr) {
		linphone_address_set_display_name(addr, NSLocalizedString(@"Voice mail", nil).UTF8String);
		[lm call:addr];
		linphone_address_destroy(addr);
	} else {
		NSLog(@"Cannot call voice mail because URI not set or invalid!");
	}
	linphone_core_stop_dtmf(LC);
}

- (void)dismissKeyboards {
	[self.addressField resignFirstResponder];
}

- (IBAction)_btnNumberPressed:(id)sender {
    [self.view endEditing: true];
    
    [pressTimer invalidate];
    pressTimer = nil;
    pressTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
                                                selector:@selector(searchPhoneBookWithThread)
                                                userInfo:nil repeats:false];
}

- (IBAction)_btnCallPressed:(UIButton *)sender {
    if (_addressField.text.length > 0) {
        [self setupFrameForSearchResultWithExistsData: NO];
        icClear.hidden = NO;
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] With _addressField.text = %@", __FUNCTION__, _addressField.text] toFilePath:appDelegate.logFilePath];
        
        [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:IS_VIDEO_CALL_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [LinphoneAppDelegate sharedInstance].phoneForCall = _addressField.text;
        [[NSNotificationCenter defaultCenter] postNotificationName:getDIDListForCall object:nil];
        
        return;
    }
    
    [self fillPhoneNumberLastCall];
    
    [pressTimer invalidate];
    pressTimer = nil;
    pressTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
                                                selector:@selector(searchPhoneBookWithThread)
                                                userInfo:nil repeats:false];
}

- (IBAction)icClearClick:(UIButton *)sender {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    [self hideSearchView];
    [self setupFrameForSearchResultWithExistsData: NO];
}

- (void)fillPhoneNumberLastCall {
    NSString *phoneNumber = [NSDatabase getLastCallOfUser];
    if (![AppUtils isNullOrEmpty: phoneNumber]) {
        if ([phoneNumber hasPrefix:@"+84"]) {
            phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"+84" withString:@"0"];
        }
        
        if ([phoneNumber hasPrefix:@"84"]) {
            phoneNumber = [phoneNumber substringFromIndex:2];
            phoneNumber = [NSString stringWithFormat:@"0%@", phoneNumber];
        }
        phoneNumber = [AppUtils removeAllSpecialInString: phoneNumber];
        
        _addressField.text = phoneNumber;
    }
}

#pragma mark - Khai Le Functions

- (void)networkDown {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"No network"];
    _lbStatus.textColor = UIColor.orangeColor;
}

- (void)searchPhoneBookWithThread {
    if (!appDelegate.contactLoaded) {
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Contacts list have not loaded successful. Please wait for a momment", __FUNCTION__] toFilePath:appDelegate.logFilePath];
        return;
    }
    
    NSString *searchStr = _addressField.text;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        //  remove data before search
        if (listPhoneSearched == nil) {
            listPhoneSearched = [[NSMutableArray alloc] init];
        }
        [listPhoneSearched removeAllObjects];
        
        NSArray *searchArr = [self searchAllContactsWithString:searchStr inList:appDelegate.listInfoPhoneNumber];
        if (searchArr.count > 0) {
            [listPhoneSearched addObjectsFromArray: searchArr];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self searchContactDone];
        });
    });
}

- (NSArray *)searchAllContactsWithString: (NSString *)search inList: (NSArray *)list {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR number CONTAINS[cd] %@ OR nameForSearch CONTAINS[cd] %@", search, search, search];
    NSArray *filter = [list filteredArrayUsingPredicate: predicate];
    return filter;
}

// Search duoc danh sach
- (void)searchContactDone
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    if (_addressField.text.length > 0) {
        //  [khai le - 02/11/2018]
        if (listPhoneSearched.count > 0) {
            [self setupFrameForSearchResultWithExistsData: YES];
            [self showSearchResultOnSearchView: listPhoneSearched];
        }else{
            [self setupFrameForSearchResultWithExistsData: NO];
        }
    }else{
        [self setupFrameForSearchResultWithExistsData: NO];
    }
}

- (void)showSearchResultOnSearchView: (NSArray *)searchArr {
    if (searchArr.count > 0) {
        PhoneObject *contact = [searchArr firstObject];
        if (![AppUtils isNullOrEmpty: contact.avatar]) {
            imgAvatar.image = [UIImage imageWithData: [NSData dataFromBase64String: contact.avatar]];
        }else{
            imgAvatar.image = [UIImage imageNamed:@"no_avatar"];
        }
        
        if (![AppUtils isNullOrEmpty: contact.name]) {
            lbName.text = contact.name;
        }else{
            lbName.text = [[LanguageUtil sharedInstance] getContent:@"Unknown"];
        }
        lbPhone.text = contact.number;
        
        if (searchArr.count > 1) {
            [btnSearchNum setTitle:[NSString stringWithFormat:@"(%d)", (int)listPhoneSearched.count]
                          forState:UIControlStateNormal];
            btnSearchNum.enabled = YES;
        }else{
            [btnSearchNum setTitle:@"" forState:UIControlStateNormal];
            btnSearchNum.enabled = NO;
        }
        
    }
}

- (void)setupFrameForSearchResultWithExistsData: (BOOL)hasData {
    if (hasData) {
        resultView.hidden = NO;
        [_addressField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_viewNumber);
            make.bottom.equalTo(resultView.mas_top);
            make.left.equalTo(self.view).offset(80);
            make.right.equalTo(self.view).offset(-80);
        }];
        
        icClear.hidden = NO;
        [icClear mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_addressField.mas_centerY);
            make.left.equalTo(_addressField.mas_right);
            make.width.height.mas_equalTo(50.0);
        }];
    }else{
        resultView.hidden = YES;
        [_addressField mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_viewNumber.mas_centerY);
            make.left.equalTo(self.view).offset(80);
            make.right.equalTo(self.view).offset(-80);
            make.height.mas_equalTo(hAddressField);
        }];
        
        icClear.hidden = YES;
        [icClear mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(_addressField.mas_centerY);
            make.left.equalTo(_addressField.mas_right);
            make.width.height.mas_equalTo(50.0);
        }];
    }
}

- (void)enableNAT
{
    return;
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    LinphoneNatPolicy *LNP = linphone_core_get_nat_policy(LC);
    linphone_nat_policy_enable_ice(LNP, FALSE);
}


- (void)newAutoLayoutForView {
    float hLogo = 22.0;
    hAddressField = 60.0;
    UIEdgeInsets callEdgeInsets = UIEdgeInsetsZero;
    UIEdgeInsets clearEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12);
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE])
    {
        hLogo = 19.0;
        callEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        clearEdgeInsets = UIEdgeInsetsMake(16, 16, 16, 16);
        
    }else if ([deviceMode isEqualToString: Iphone6] || [deviceMode isEqualToString: Iphone6s] || [deviceMode isEqualToString: Iphone7_1] || [deviceMode isEqualToString: Iphone7_2] || [deviceMode isEqualToString: Iphone8_1] || [deviceMode isEqualToString: Iphone8_2]) {
        
    }else if ([deviceMode isEqualToString: Iphone6_Plus] || [deviceMode isEqualToString: Iphone6s_Plus] || [deviceMode isEqualToString: Iphone7_Plus1] || [deviceMode isEqualToString: Iphone7_Plus2] || [deviceMode isEqualToString: Iphone8_Plus1] || [deviceMode isEqualToString: Iphone8_Plus2] || [deviceMode isEqualToString: simulator])
    {
        
    }else if ([deviceMode isEqualToString: IphoneX_1] || [deviceMode isEqualToString: IphoneX_2] || [deviceMode isEqualToString: IphoneXR] || [deviceMode isEqualToString: IphoneXS] || [deviceMode isEqualToString: IphoneXS_Max1] || [deviceMode isEqualToString: IphoneXS_Max2]) {
        
        hAddressField = 80.0;
    }
    
    
    self.view.backgroundColor = UIColor.whiteColor;
    //  view status
    _viewStatus.backgroundColor = UIColor.clearColor;
    [_viewStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(appDelegate._hRegistrationState);
    }];
    
    UIImage *logoImg = [UIImage imageNamed:@"logo_white"];
    float wLogo = hLogo * logoImg.size.width / logoImg.size.height;
    _imgLogoSmall.image = logoImg;
    [_imgLogoSmall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_viewStatus).offset(appDelegate._hRegistrationState/4);
        make.centerY.equalTo(_viewStatus.mas_centerY).offset(appDelegate._hStatus/2-5.0);
        make.height.mas_equalTo(hLogo);
        make.width.mas_equalTo(wLogo);
    }];
    
    //  account label
    _lbAccount.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    _lbAccount.textAlignment = NSTextAlignmentCenter;
    [_lbAccount mas_makeConstraints:^(MASConstraintMaker *make) {
        //  make.top.bottom.equalTo(_imgLogoSmall);
        make.centerY.equalTo(_viewStatus.mas_centerY).offset(appDelegate._hStatus/2);
        make.centerX.equalTo(_viewStatus.mas_centerX);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40.0);
    }];
    
    //  status label
    _lbStatus.font = [LinphoneAppDelegate sharedInstance].headerFontNormal;
    _lbStatus.numberOfLines = 0;
    [_lbStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_lbAccount.mas_right);
        make.top.bottom.equalTo(_lbAccount);
        make.right.equalTo(_viewStatus).offset(-appDelegate._hRegistrationState/4);
    }];
    UITapGestureRecognizer *tapOnStatus = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(whenTappedOnStatusAccount)];
    _lbStatus.userInteractionEnabled = YES;
    [_lbStatus addGestureRecognizer: tapOnStatus];
    
    //  pad view
    float wIcon = [DeviceUtils getSizeOfKeypadButtonForDevice];
    float spaceMarginY = [DeviceUtils getSpaceYBetweenKeypadButtonsForDevice];
    float spaceMarginX = [DeviceUtils getSpaceXBetweenKeypadButtonsForDevice];
    
    float hPadView = 5*wIcon + 6*spaceMarginY;
    _padView.backgroundColor = UIColor.clearColor;
    [_padView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(hPadView);
    }];
    
    //  1, 2, 3
    _twoButton.layer.cornerRadius = wIcon/2;
    _twoButton.clipsToBounds = YES;
    [_twoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_padView).offset(0);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _oneButton.layer.cornerRadius = wIcon/2;
    _oneButton.clipsToBounds = YES;
    [_oneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_twoButton.mas_top);
        make.right.equalTo(_twoButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _threeButton.layer.cornerRadius = wIcon/2;
    _threeButton.clipsToBounds = YES;
    [_threeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_twoButton.mas_top);
        make.left.equalTo(_twoButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  4, 5, 6
    _fiveButton.layer.cornerRadius = wIcon/2;
    _fiveButton.clipsToBounds = YES;
    [_fiveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_twoButton.mas_bottom).offset(spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _fourButton.layer.cornerRadius = wIcon/2;
    _fourButton.clipsToBounds = YES;
    [_fourButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_fiveButton.mas_top);
        make.right.equalTo(_fiveButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _sixButton.layer.cornerRadius = wIcon/2;
    _sixButton.clipsToBounds = YES;
    [_sixButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_fiveButton.mas_top);
        make.left.equalTo(_fiveButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  7, 8, 9
    _eightButton.layer.cornerRadius = wIcon/2;
    _eightButton.clipsToBounds = YES;
    [_eightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_fiveButton.mas_bottom).offset(spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _sevenButton.layer.cornerRadius = wIcon/2;
    _sevenButton.clipsToBounds = YES;
    [_sevenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_eightButton.mas_top);
        make.right.equalTo(_eightButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _nineButton.layer.cornerRadius = wIcon/2;
    _nineButton.clipsToBounds = YES;
    [_nineButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_eightButton.mas_top);
        make.left.equalTo(_eightButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  *, 0, #
    _zeroButton.layer.cornerRadius = wIcon/2;
    _zeroButton.clipsToBounds = YES;
    [_zeroButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_eightButton.mas_bottom).offset(spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _starButton.layer.cornerRadius = wIcon/2;
    _starButton.clipsToBounds = YES;
    [_starButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_zeroButton.mas_top);
        make.right.equalTo(_zeroButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _hashButton.layer.cornerRadius = wIcon/2;
    _hashButton.clipsToBounds = YES;
    [_hashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_zeroButton.mas_top);
        make.left.equalTo(_zeroButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  fifth layer
    _callButton.tag = TAG_AUDIO_CALL;
    _callButton.layer.cornerRadius = wIcon/2;
    _callButton.clipsToBounds = YES;
    _callButton.imageEdgeInsets = callEdgeInsets;
    [_callButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_zeroButton.mas_bottom).offset(spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    btnVideoCall.tag = TAG_VIDEO_CALL;
    btnVideoCall.imageEdgeInsets = [DeviceUtils getEdgeOfVideoCallDialerForDevice];
    btnVideoCall.layer.cornerRadius = wIcon/2;
    btnVideoCall.clipsToBounds = YES;
    [btnVideoCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_callButton.mas_top);
        make.right.equalTo(_callButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _backspaceButton.imageEdgeInsets = [DeviceUtils getEdgeOfVideoCallDialerForDevice];
    _backspaceButton.layer.cornerRadius = wIcon/2;
    _backspaceButton.clipsToBounds = YES;
    [_backspaceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_callButton.mas_top);
        make.left.equalTo(_callButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    
    //  Number view
    [_viewNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(_viewStatus.mas_bottom);
        make.bottom.equalTo(_padView.mas_top);
    }];
    
    [_addressField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_viewNumber.mas_centerY);
        make.left.equalTo(self.view).offset(80);
        make.right.equalTo(self.view).offset(-80);
        make.height.mas_equalTo(hAddressField);
    }];
    _addressField.keyboardType = UIKeyboardTypePhonePad;
    _addressField.enabled = YES;
    _addressField.textAlignment = NSTextAlignmentCenter;
    _addressField.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:45.0];
    _addressField.adjustsFontSizeToFitWidth = YES;
    _addressField.delegate = self;
    [_addressField addTarget:self
                      action:@selector(addressfieldDidChanged:)
            forControlEvents:UIControlEventEditingChanged];
    
    icClear.hidden = YES;
    icClear.imageEdgeInsets = clearEdgeInsets;
    [icClear mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_addressField.mas_centerY);
        make.left.equalTo(_addressField.mas_right);
        make.width.height.mas_equalTo(50.0);
    }];
    
    
    lbSepa123.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                 blue:(240/255.0) alpha:1.0];
    lbSepa456.backgroundColor = lbSepa789.backgroundColor = lbSepa123.backgroundColor;
    
    [lbSepa123 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_oneButton);
        make.right.equalTo(_threeButton.mas_right);
        make.top.equalTo(_oneButton.mas_bottom).offset(spaceMarginY/2);
        make.height.mas_equalTo(1.0);
    }];
    
    [lbSepa456 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(lbSepa123);
        make.top.equalTo(_fiveButton.mas_bottom).offset(spaceMarginY/2);
        make.height.equalTo(lbSepa123.mas_height);
    }];
    
    [lbSepa789 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(lbSepa123);
        make.top.equalTo(_eightButton.mas_bottom).offset(spaceMarginY/2);
        make.height.equalTo(lbSepa123.mas_height);
    }];
}

- (void)autoLayoutForView
{
    NSString *modelName = [DeviceUtils getModelsOfCurrentDevice];
    
    self.view.backgroundColor = UIColor.whiteColor;
    //  view status
    _viewStatus.backgroundColor = [UIColor colorWithRed:(21/255.0) green:(41/255.0)
                                                   blue:(52/255.0) alpha:1.0];
    [_viewStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(appDelegate._hRegistrationState);
    }];
    
    UIImage *logoImg = [UIImage imageNamed:@"logo_white"];
    float wLogo = 23.0 * logoImg.size.width / logoImg.size.height;
    _imgLogoSmall.image = logoImg;
    [_imgLogoSmall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_viewStatus).offset(appDelegate._hRegistrationState/4);
        make.centerY.equalTo(_viewStatus.mas_centerY).offset(appDelegate._hStatus/2-5.0);
        make.height.mas_equalTo(22.0);
        make.width.mas_equalTo(wLogo);
    }];
    
    //  account label
    _lbAccount.font = [UIFont fontWithName:MYRIADPRO_BOLD size:18.0];
    _lbAccount.textAlignment = NSTextAlignmentCenter;
    [_lbAccount mas_makeConstraints:^(MASConstraintMaker *make) {
        //  make.top.bottom.equalTo(_imgLogoSmall);
        make.centerY.equalTo(_viewStatus.mas_centerY).offset(appDelegate._hStatus/2);
        make.centerX.equalTo(_viewStatus.mas_centerX);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(40.0);
    }];
    
    //  status label
    _lbStatus.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    _lbStatus.numberOfLines = 0;
    [_lbStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_lbAccount.mas_right);
        make.top.bottom.equalTo(_lbAccount);
        make.right.equalTo(_viewStatus).offset(-appDelegate._hRegistrationState/4);
    }];
    UITapGestureRecognizer *tapOnStatus = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(whenTappedOnStatusAccount)];
    _lbStatus.userInteractionEnabled = YES;
    [_lbStatus addGestureRecognizer: tapOnStatus];
    
    //  Number view
    float hNumber = 100.0;
    float hTextField = 60.0;
    if ([modelName isEqualToString: IphoneX_1] || [modelName isEqualToString: IphoneX_2] || [modelName isEqualToString: IphoneXR] || [modelName isEqualToString: IphoneXS] || [modelName isEqualToString: IphoneXS_Max1] || [modelName isEqualToString: IphoneXS_Max2])
    {
        hNumber = 120.0;
        hTextField = 80.0;
    }
    
    [_viewNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(_viewStatus.mas_bottom);
        make.height.mas_equalTo(hNumber);
    }];
    
    [_addressField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewNumber).offset(10);
        make.left.equalTo(self.view).offset(80);
        make.right.equalTo(self.view).offset(-80);
        make.height.mas_equalTo(hTextField);
    }];
    _addressField.keyboardType = UIKeyboardTypePhonePad;
    _addressField.enabled = YES;
    _addressField.textAlignment = NSTextAlignmentCenter;
    _addressField.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:45.0];
    _addressField.adjustsFontSizeToFitWidth = YES;
    _addressField.delegate = self;
    [_addressField addTarget:self
                      action:@selector(addressfieldDidChanged:)
            forControlEvents:UIControlEventEditingChanged];
    
    //  Number keypad
    float wIcon = [DeviceUtils getSizeOfKeypadButtonForDevice];
    float spaceMarginY = [DeviceUtils getSpaceYBetweenKeypadButtonsForDevice];
    float spaceMarginX = [DeviceUtils getSpaceXBetweenKeypadButtonsForDevice];
    
    _padView.backgroundColor = UIColor.clearColor;
    [_padView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewNumber.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    //  7, 8, 9
    _eightButton.layer.cornerRadius = wIcon/2;
    _eightButton.clipsToBounds = YES;
    [_eightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_padView.mas_centerX);
        make.centerY.equalTo(_padView.mas_centerY);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _sevenButton.layer.cornerRadius = wIcon/2;
    _sevenButton.clipsToBounds = YES;
    [_sevenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_eightButton.mas_top);
        make.right.equalTo(_eightButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _nineButton.layer.cornerRadius = wIcon/2;
    _nineButton.clipsToBounds = YES;
    [_nineButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_eightButton.mas_top);
        make.left.equalTo(_eightButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  4, 5, 6
    _fiveButton.layer.cornerRadius = wIcon/2;
    _fiveButton.clipsToBounds = YES;
    [_fiveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_eightButton.mas_top).offset(-spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _fourButton.layer.cornerRadius = wIcon/2;
    _fourButton.clipsToBounds = YES;
    [_fourButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_fiveButton.mas_top);
        make.right.equalTo(_fiveButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _sixButton.layer.cornerRadius = wIcon/2;
    _sixButton.clipsToBounds = YES;
    [_sixButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_fiveButton.mas_top);
        make.left.equalTo(_fiveButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  1, 2, 3
    _twoButton.layer.cornerRadius = wIcon/2;
    _twoButton.clipsToBounds = YES;
    [_twoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_fiveButton.mas_top).offset(-spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _oneButton.layer.cornerRadius = wIcon/2;
    _oneButton.clipsToBounds = YES;
    [_oneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_twoButton.mas_top);
        make.right.equalTo(_twoButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _threeButton.layer.cornerRadius = wIcon/2;
    _threeButton.clipsToBounds = YES;
    [_threeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_twoButton.mas_top);
        make.left.equalTo(_twoButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  *, 0, #
    _zeroButton.layer.cornerRadius = wIcon/2;
    _zeroButton.clipsToBounds = YES;
    [_zeroButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_eightButton.mas_bottom).offset(spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _starButton.layer.cornerRadius = wIcon/2;
    _starButton.clipsToBounds = YES;
    [_starButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_zeroButton.mas_top);
        make.right.equalTo(_zeroButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _hashButton.layer.cornerRadius = wIcon/2;
    _hashButton.clipsToBounds = YES;
    [_hashButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_zeroButton.mas_top);
        make.left.equalTo(_zeroButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    //  fifth layer
    _callButton.tag = TAG_AUDIO_CALL;
    _callButton.layer.cornerRadius = wIcon/2;
    _callButton.clipsToBounds = YES;
    [_callButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_zeroButton.mas_bottom).offset(spaceMarginY);
        make.centerX.equalTo(_padView.mas_centerX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    btnVideoCall.tag = TAG_VIDEO_CALL;
    btnVideoCall.imageEdgeInsets = [DeviceUtils getEdgeOfVideoCallDialerForDevice];
    btnVideoCall.layer.cornerRadius = wIcon/2;
    btnVideoCall.clipsToBounds = YES;
    [btnVideoCall mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_callButton.mas_top);
        make.right.equalTo(_callButton.mas_left).offset(-spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    _backspaceButton.imageEdgeInsets = [DeviceUtils getEdgeOfVideoCallDialerForDevice];
    _backspaceButton.layer.cornerRadius = wIcon/2;
    _backspaceButton.clipsToBounds = YES;
    [_backspaceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_callButton.mas_top);
        make.left.equalTo(_callButton.mas_right).offset(spaceMarginX);
        make.width.height.mas_equalTo(wIcon);
    }];
    
    lbSepa123.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                 blue:(240/255.0) alpha:1.0];
    lbSepa456.backgroundColor = lbSepa789.backgroundColor = lbSepa123.backgroundColor;
    
    [lbSepa123 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_oneButton);
        make.right.equalTo(_threeButton.mas_right);
        make.top.equalTo(_oneButton.mas_bottom).offset(spaceMarginY/2);
        make.height.mas_equalTo(1.0);
    }];
    
    [lbSepa456 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(lbSepa123);
        make.top.equalTo(_fiveButton.mas_bottom).offset(spaceMarginY/2);
        make.height.equalTo(lbSepa123.mas_height);
    }];
    
    [lbSepa789 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(lbSepa123);
        make.top.equalTo(_eightButton.mas_bottom).offset(spaceMarginY/2);
        make.height.equalTo(lbSepa123.mas_height);
    }];
}

#pragma mark - Tap Gesture delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//    if ([touch.view isDescendantOfView: _tbSearch]) {
//        return NO;
//    }
    return YES;
}

#pragma mark - Call Button Delegate
- (void)textfieldAddressChanged:(NSString *)number {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] number = %@", __FUNCTION__, number] toFilePath:appDelegate.logFilePath];
    
    [self searchPhoneBookWithThread];
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
        case LinphoneRegistrationOk: {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] State is LinphoneRegistrationOk", __FUNCTION__] toFilePath:appDelegate.logFilePath];
            
            _lbStatus.textColor = UIColor.greenColor;
            _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"Online"];
            break;
        }
        case LinphoneRegistrationNone:{
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] State is LinphoneRegistrationNone", __FUNCTION__] toFilePath:appDelegate.logFilePath];
            
            break;
        }
        case LinphoneRegistrationCleared: {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] State is LinphoneRegistrationCleared", __FUNCTION__] toFilePath:appDelegate.logFilePath];
            
            break;
        }
        case LinphoneRegistrationFailed: {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] State is LinphoneRegistrationFailed", __FUNCTION__] toFilePath:appDelegate.logFilePath];
            
            _lbStatus.textColor = UIColor.orangeColor;
            if ([SipUtils getStateOfDefaultProxyConfig] == eAccountOff) {
                _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"Disabled"];
            }else{
                _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"Offline"];
            }
            break;
        }
        case LinphoneRegistrationProgress: {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] State is LinphoneRegistrationProgress", __FUNCTION__] toFilePath:appDelegate.logFilePath];
            
            _lbStatus.textColor = UIColor.whiteColor;
            _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"Connecting"];
            break;
        }
        default:
            break;
    }
}

- (void)loadAssistantConfig:(NSString *)rcFilename {
    NSString *fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
    linphone_core_set_provisioning_uri(LC, fullPath.UTF8String);
    [LinphoneManager.instance lpConfigSetInt:1 forKey:@"transient_provisioning" inSection:@"misc"];
}

- (void)firstLoadSettingForAccount {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString: cloudfoneBundleID]) {
        NSString *hasFirstSetting = [[NSUserDefaults standardUserDefaults] objectForKey:@"hasFirstSetting"];
        if (hasFirstSetting == nil) {
            linphone_core_enable_ipv6(LC, NO);
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"hasFirstSetting"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

//  Added by Khai Le on 30/09/2018
- (void)checkAccountForApp
{
    AccountState curState = [SipUtils getStateOfDefaultProxyConfig];
    if (curState == eAccountNone) {
        _lbAccount.text = @"";
        _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"No account"];
        _lbStatus.textColor = UIColor.orangeColor;
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] NONE ACCOUNT", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    }else {
        NSString *accountID = [SipUtils getAccountIdOfDefaultProxyConfig];
        _lbAccount.text = accountID;
        if (curState == eAccountOff) {
            _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"Disabled"];
            _lbStatus.textColor = UIColor.orangeColor;
            
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] AccountId = %@, state is OFF", __FUNCTION__, accountID] toFilePath:appDelegate.logFilePath];
        }else{
            LinphoneRegistrationState state = [SipUtils getRegistrationStateOfDefaultProxyConfig];
            if (state == LinphoneRegistrationOk) {
                //  account on
                _lbStatus.textColor = UIColor.greenColor;
                _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"Online"];
            }else{
                _lbStatus.textColor = UIColor.orangeColor;
                _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"Offline"];
            }
            
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] AccountId = %@, state is ON", __FUNCTION__, accountID] toFilePath:appDelegate.logFilePath];
        }
    }
}

//  Added by Khai Le on 03/10/2018
- (void)addBoxShadowForView: (UIView *)view withColor: (UIColor *)color{
    view.layer.shadowRadius  = view.layer.cornerRadius;
    view.layer.shadowColor   = color.CGColor;
    view.layer.shadowOffset  = CGSizeMake(0.0f, 0.0f);
    view.layer.shadowOpacity = 0.9f;
    view.layer.masksToBounds = NO;
    
    UIEdgeInsets shadowInsets     = UIEdgeInsetsMake(0, 0, -5.0f, 0);
    UIBezierPath *shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(view.bounds, shadowInsets)];
    view.layer.shadowPath    = shadowPath.CGPath;
}

- (void)whenNetworkChanged {
    NetworkStatus internetStatus = [appDelegate.internetReachable currentReachabilityStatus];
    if (internetStatus == NotReachable) {
        _lbStatus.text = [[LanguageUtil sharedInstance] getContent:@"No network"];
        _lbStatus.textColor = UIColor.orangeColor;
    }else{
        [self checkAccountForApp];
    }
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] internetStatus = %d", __FUNCTION__, internetStatus] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
}

- (void)whenTappedOnStatusAccount {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    if ([LinphoneManager instance].connectivity == none){
        [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"Please check your internet connection!"] duration:2.0 position:CSToastPositionCenter];
        return;
    }
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Call %@", @"refreshRegisters"] toFilePath:appDelegate.logFilePath];
    [LinphoneManager.instance refreshRegisters];
}

- (void)addressfieldDidChanged: (UITextField *)textfield {
    if (!textfield.isFirstResponder) {
        NSLog(@"Just search when text changed and textfield is focus");
        return;
    }
    if ([textfield.text isEqualToString:@""]) {
        resultView.hidden = YES;
    }else{
        [pressTimer invalidate];
        pressTimer = nil;
        pressTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
                                                    selector:@selector(searchPhoneBookWithThread)
                                                    userInfo:nil repeats:false];
    }
}

- (void)hideSearchView {
    _addressField.text = @"";
    resultView.hidden = YES;
}

#pragma mark - UIAlertview Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1)
    {
        if (buttonIndex == 1){
            [[PhoneMainView instance] changeCurrentView:[PBXSettingViewController compositeViewDescription] push:YES];
        }
    }
    else if (alertView.tag == 2){
        if (buttonIndex == 0) {
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] You don't want to enable this account with Id = %@", __FUNCTION__, [SipUtils getAccountIdOfDefaultProxyConfig]] toFilePath:appDelegate.logFilePath];
        }else if (buttonIndex == 1){
            LinphoneProxyConfig *defaultConfig = linphone_core_get_default_proxy_config(LC);
            if (defaultConfig != NULL) {
                linphone_proxy_config_enable_register(defaultConfig, YES);
                linphone_proxy_config_refresh_register(defaultConfig);
                linphone_proxy_config_done(defaultConfig);
                
                linphone_core_refresh_registers(LC);
                
                [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] You turned on account with Id = %@", __FUNCTION__, [SipUtils getAccountIdOfDefaultProxyConfig]] toFilePath:appDelegate.logFilePath];
            }
        }
        
    }else if (alertView.tag == 2){
        [WriteLogsUtils writeLogContent:@"Make call to hotline" toFilePath:appDelegate.logFilePath];
        [SipUtils makeCallWithPhoneNumber: hotline];
    }
}

- (void)selectContactFromSearchPopup:(NSString *)phoneNumber {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] phoneNumber = %@", __FUNCTION__, phoneNumber] toFilePath:appDelegate.logFilePath];
    
    _addressField.text = phoneNumber;
    [self setupFrameForSearchResultWithExistsData: NO];
}

- (BOOL)fillToAddressField {
    if (![_addressField.text isEqualToString:@""]) {
        return YES;
    }else{
        NSString *phoneNumber = [NSDatabase getLastCallOfUser];
        if (![phoneNumber isEqualToString: @""]) {
            if ([phoneNumber isEqualToString: hotline]) {
                //  addressField.text = [[LanguageUtil sharedInstance] getContent:@"Hotline"];
            }else{
                //  addressField.text = phoneNumber;
            }
        }
        return NO;
    }
}

- (void)createSearchViewIfNeed {
    if (resultView == nil) {
        resultView = [[UIView alloc] init];
        resultView.hidden = YES;
        resultView.layer.cornerRadius = 5.0;
        resultView.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                      blue:(240/255.0) alpha:1.0];
        [_viewNumber addSubview: resultView];
        
        float hSearch = [DeviceUtils getHeightSearchViewContactForDevice];
        float hAvatar = [DeviceUtils getHeightAvatarSearchViewForDevice];
        float wPopup = [DeviceUtils getWidthPoupSearchViewForDevice];
        
        [resultView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_viewNumber.mas_centerX);
            make.bottom.equalTo(_viewNumber);
            make.width.mas_equalTo(wPopup);
            make.height.mas_equalTo(hSearch);
        }];
        
        imgAvatar = [[UIImageView alloc] init];
        imgAvatar.image = [UIImage imageNamed:@"no_avatar"];
        imgAvatar.layer.cornerRadius = hAvatar/2;
        imgAvatar.clipsToBounds = YES;
        [resultView addSubview: imgAvatar];
        [imgAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(resultView.mas_centerY);
            make.left.equalTo(resultView).offset((hSearch-hAvatar)/2);
            make.width.height.mas_equalTo(hAvatar);
        }];
        
        btnSearchNum = [[UIButton alloc] init];
        [btnSearchNum setTitleColor:[UIColor colorWithRed:(101/255.0) green:(205/255.0)
                                                     blue:(70/255.0) alpha:1.0]
                           forState:UIControlStateNormal];
        [btnSearchNum addTarget:self
                         action:@selector(showSearchPopupContact)
               forControlEvents:UIControlEventTouchUpInside];
        [resultView addSubview: btnSearchNum];
        [btnSearchNum mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.right.bottom.equalTo(resultView);
            make.width.height.mas_equalTo(60.0);
        }];
        
        lbName = [[UILabel alloc] init];
        lbName.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
        lbName.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
        lbName.text = @"Le Quang Khai";
        [resultView addSubview: lbName];
        [lbName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(resultView).offset(4.0);
            make.left.equalTo(imgAvatar.mas_right).offset(8.0);
            make.bottom.equalTo(imgAvatar.mas_centerY);
            make.right.equalTo(btnSearchNum.mas_left).offset(-8.0);
        }];
        
        lbPhone = [[UILabel alloc] init];
        lbPhone.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        lbPhone.textColor = UIColor.darkGrayColor;
        lbPhone.text = @"036 343 0737";
        [resultView addSubview: lbPhone];
        [lbPhone mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(imgAvatar.mas_centerY);
            make.left.right.equalTo(lbName);
            make.bottom.equalTo(resultView).offset(-4.0);
        }];
        
        btnChooseContact = [[UIButton alloc] init];
        btnChooseContact.backgroundColor = UIColor.clearColor;
        [btnChooseContact addTarget:self
                         action:@selector(selecteFirstContactForSearch)
               forControlEvents:UIControlEventTouchUpInside];
        [resultView addSubview: btnChooseContact];
        [btnChooseContact mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.equalTo(resultView);
            make.right.equalTo(btnSearchNum.mas_left);
        }];
        
    }
}

- (void)selecteFirstContactForSearch {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    if (listPhoneSearched.count > 0) {
        PhoneObject *contact = [listPhoneSearched firstObject];
        _addressField.text = contact.number;
        
        [self setupFrameForSearchResultWithExistsData: NO];
    }
}

- (void)showSearchPopupContact {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:appDelegate.logFilePath];
    
    float totalHeight = listPhoneSearched.count * 60.0;
    if (totalHeight > SCREEN_HEIGHT - 70.0*2) {
        totalHeight = SCREEN_HEIGHT - 70.0*2;
    }
    popupSearchContacts = [[SearchContactPopupView alloc] initWithFrame:CGRectMake(30.0, (SCREEN_HEIGHT-totalHeight)/2, SCREEN_WIDTH-60.0, totalHeight)];
    popupSearchContacts.contacts = listPhoneSearched;
    [popupSearchContacts.tbContacts reloadData];
    popupSearchContacts.delegate = self;
    [popupSearchContacts showInView:appDelegate.window animated:YES];
}

#pragma mark - Webservice delegate
- (void)failedToCallWebService:(NSString *)link andError:(NSString *)error
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Result for %@:\nResponse data: %@\n", __FUNCTION__, link, error] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
}

- (void)successfulToCallWebService:(NSString *)link withData:(NSDictionary *)data {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Result for %@:\nResponse data: %@\n", __FUNCTION__, link, @[data]] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([link isEqualToString: get_didlist_func]){
        NSLog(@"%@", data);
    }
}

-(void)receivedResponeCode:(NSString *)link withCode:(int)responeCode {
}

@end
