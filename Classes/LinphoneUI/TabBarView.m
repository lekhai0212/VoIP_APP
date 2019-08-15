/* TabBarViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "TabBarView.h"

@interface TabBarView (){
    
}

@end

@implementation TabBarView
@synthesize viewIpadMenu, btnDialerIpad, btnCallHistoryIpad, btnContactsIpad, btnMoreIpad, lbMenuTopSepa, lbVersionUpdate;

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    if (!IS_IPOD && !IS_IPHONE) {
        viewIpadMenu.hidden = NO;
        [self setupUIForIpadMenuView];
    }else{
        viewIpadMenu.hidden = YES;
    }
    
    //  Added by Khai Le on 03/10/2018
    self.lbTopSepa.backgroundColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0) blue:(220/255.0) alpha:1.0];
    [self.lbTopSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(1);
    }];
    
    lbVersionUpdate.hidden = TRUE;
    lbVersionUpdate.clipsToBounds = TRUE;
    lbVersionUpdate.layer.cornerRadius = 20.0/2;
    lbVersionUpdate.backgroundColor = UIColor.redColor;
    lbVersionUpdate.textColor = UIColor.whiteColor;
    lbVersionUpdate.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:14.0];
    lbVersionUpdate.text = @"1";
    [lbVersionUpdate mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(5.0);
        make.right.equalTo(self.view).offset(-5.0);
        make.width.height.mas_equalTo(20.0);
    }];
    //  ---
    
    _historyNotificationView.clipsToBounds = YES;
    _historyNotificationView.backgroundColor = [UIColor colorWithRed:(255/255.0) green:(65/255.0)
                                                                blue:(65/255.0) alpha:1.0];
    [self setBackgroundForTabBarButton];
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(changeViewEvent:)
											   name:kLinphoneMainViewChange object:nil];
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(callUpdate:)
											   name:kLinphoneCallUpdate object:nil];
    
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(messageReceived:)
											   name:kLinphoneMessageReceived object:nil];
    //  Cập nhật số message chưa đọc
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMainBarNotifications)
                                                 name:k11UpdateBarNotifications object:nil];
    
	[self update:FALSE];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    _historyNotificationView.layer.cornerRadius = _historyNotificationView.frame.size.height/2;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self update:FALSE];
}

#pragma mark - Event Functions

- (void)callUpdate:(NSNotification *)notif {
	// LinphoneCall *call = [[notif.userInfo objectForKey: @"call"] pointerValue];
	// LinphoneCallState state = [[notif.userInfo objectForKey: @"state"] intValue];
	[self updateMissedCall:linphone_core_get_missed_calls_count(LC) appear:TRUE];
}

- (void)changeViewEvent:(NSNotification *)notif {
	UICompositeViewDescription *view = [notif.userInfo objectForKey:@"view"];
	if (view != nil) {
		[self updateSelectedButton:view];
	}
}

- (void)messageReceived:(NSNotification *)notif {
	
}

#pragma mark - UI Update

- (void)update:(BOOL)appear {
    [self updateSelectedButton:[PhoneMainView.instance currentView]];
    [self updateMissedCall:0 appear:appear];
}

- (void)updateMissedCall:(int)missedCall appear:(BOOL)appear
{
    
    //  _historyNotificationView.backgroundColor = UIColor.blueColor;
    //  _historyNotificationLabel.backgroundColor = UIColor.greenColor;
    _historyNotificationLabel.frame = CGRectMake(0, 0, _historyNotificationView.frame.size.width, _historyNotificationView.frame.size.height);
    _historyNotificationLabel.text = @"";
    
    if ([SipUtils getStateOfDefaultProxyConfig] == eAccountNone) {
        [_historyNotificationView stopAnimating:appear];
        return;
    }
    NSString *account = [SipUtils getAccountIdOfDefaultProxyConfig];
    missedCall = [NSDatabase getUnreadMissedCallHisotryWithAccount: account];
    
	if (missedCall > 0) {
        _historyNotificationView.hidden = NO;
        _historyNotificationLabel.text = [NSString stringWithFormat:@"%i", missedCall];
		[_historyNotificationView startAnimating:appear];
	} else {
        _historyNotificationView.hidden = YES;
		[_historyNotificationView stopAnimating:appear];
	}
}

- (void)updateSelectedButton:(UICompositeViewDescription *)view {
    if (IS_IPOD || IS_IPHONE) {
        _historyButton.selected = [view equal:CallsHistoryViewController.compositeViewDescription] ||
        [view equal:HistoryDetailsView.compositeViewDescription];
        
        _contactsButton.selected = [view equal:ContactsViewController.compositeViewDescription] ||
        [view equal:KContactDetailViewController.compositeViewDescription];
        _dialerButton.selected = [view equal:DialerView.compositeViewDescription];
        _moreButton.selected = [view equal:MoreViewController.compositeViewDescription];
    }else{
        btnCallHistoryIpad.selected = [view equal:CallsHistoryViewController.compositeViewDescription] ||
        [view equal:HistoryDetailsView.compositeViewDescription];
        
        btnContactsIpad.selected = [view equal:ContactsViewController.compositeViewDescription] ||
        [view equal:KContactDetailViewController.compositeViewDescription];
        btnDialerIpad.selected = [view equal:DialerView.compositeViewDescription];
        btnMoreIpad.selected = [view equal:MoreViewController.compositeViewDescription];
    }
}

#pragma mark - Action Functions

- (IBAction)onHistoryClick:(id)event {
    linphone_core_reset_missed_calls_count(LC);
    [self update:FALSE];
    [PhoneMainView.instance updateApplicationBadgeNumber];
    [PhoneMainView.instance changeCurrentView:CallsHistoryViewController.compositeViewDescription];
}

- (IBAction)onContactsClick:(id)event {
	[ContactSelection setAddAddress:nil];
	[ContactSelection enableEmailFilter:FALSE];
	[ContactSelection setNameOrEmailFilter:nil];
	//  [PhoneMainView.instance changeCurrentView:ContactsListView.compositeViewDescription];
    [PhoneMainView.instance changeCurrentView:ContactsViewController.compositeViewDescription];
}

- (IBAction)onDialerClick:(id)event {
	[PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
}

- (IBAction)onSettingsClick:(id)event {
	[PhoneMainView.instance changeCurrentView:SettingsView.compositeViewDescription];
}

- (IBAction)onChatClick:(id)event {
    [PhoneMainView.instance changeCurrentView:KMessageViewController.compositeViewDescription];
}

- (IBAction)onMoreClick:(UIButton *)sender {
    [PhoneMainView.instance changeCurrentView:MoreViewController.compositeViewDescription];
}

- (void)setBackgroundForTabBarButton
{
    [_dialerButton setBackgroundImage:[UIImage imageNamed:@"menu_dialer_def"] forState:UIControlStateNormal];
    [_dialerButton setBackgroundImage:[UIImage imageNamed:@"menu_dialer_act"] forState:UIControlStateHighlighted];
    [_dialerButton setBackgroundImage:[UIImage imageNamed:@"menu_dialer_act"] forState:UIControlStateSelected];
    
    [_historyButton setBackgroundImage:[UIImage imageNamed:@"menu_history_def"] forState:UIControlStateNormal];
    [_historyButton setBackgroundImage:[UIImage imageNamed:@"menu_history_act"] forState:UIControlStateHighlighted];
    [_historyButton setBackgroundImage:[UIImage imageNamed:@"menu_history_act"] forState:UIControlStateSelected];
    
    [_contactsButton setBackgroundImage:[UIImage imageNamed:@"menu_contact_def"] forState:UIControlStateNormal];
    [_contactsButton setBackgroundImage:[UIImage imageNamed:@"menu_contact_act"] forState:UIControlStateHighlighted];
    [_contactsButton setBackgroundImage:[UIImage imageNamed:@"menu_contact_act"] forState:UIControlStateSelected];
    
    [_moreButton setBackgroundImage:[UIImage imageNamed:@"menu_more_def"] forState:UIControlStateNormal];
    [_moreButton setBackgroundImage:[UIImage imageNamed:@"menu_more_act"] forState:UIControlStateHighlighted];
    [_moreButton setBackgroundImage:[UIImage imageNamed:@"menu_more_act"] forState:UIControlStateSelected];
}


#pragma mark - Khai Le functions

- (void)updateMainBarNotifications
{
    [self update: false];
    
    //  Get all missed call number
    NSString *ExtUser = [SipUtils getAccountIdOfDefaultProxyConfig];
    if (![AppUtils isNullOrEmpty: ExtUser]) {
        int numMissedCall = [NSDatabase getAllMissedCallUnreadofAccount: ExtUser];
        [UIApplication sharedApplication].applicationIconBadgeNumber = numMissedCall;
    }else{
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
}

- (IBAction)btnDialerIpadPress:(UIButton *)sender {
    [PhoneMainView.instance changeCurrentView:DialerView.compositeViewDescription];
}

- (IBAction)btnCallHistoryIpadPress:(UIButton *)sender {
    linphone_core_reset_missed_calls_count(LC);
    [self update:FALSE];
    [PhoneMainView.instance updateApplicationBadgeNumber];
    [PhoneMainView.instance changeCurrentView:CallsHistoryViewController.compositeViewDescription];
}

- (IBAction)btnContactsIpadPress:(UIButton *)sender {
    [ContactSelection setAddAddress:nil];
    [ContactSelection enableEmailFilter:FALSE];
    [ContactSelection setNameOrEmailFilter:nil];
    //  [PhoneMainView.instance changeCurrentView:ContactsListView.compositeViewDescription];
    [PhoneMainView.instance changeCurrentView:ContactsViewController.compositeViewDescription];
}

- (IBAction)btnMoreIpadPress:(UIButton *)sender {
    [PhoneMainView.instance changeCurrentView:MoreViewController.compositeViewDescription];
}

- (void)setupUIForIpadMenuView {
    [viewIpadMenu mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    float iconSize = 25.0;
    UIFont *textFont = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    UIColor *defColor = [UIColor colorWithRed:(172/255.0) green:(172/255.0) blue:(172/255.0) alpha:1.0];
    UIColor *actColor = [UIColor colorWithRed:(50/255.0) green:(196/255.0) blue:(124/255.0) alpha:1.0];
    
    NSAttributedString *dialerAct = [AppUtils getAttributeTitle:@" Cuộc gọi" font:textFont sizeIcon:iconSize color:actColor image:[UIImage imageNamed:@"ipad_menu_dialer_act"]];
    NSAttributedString *dialerDef = [AppUtils getAttributeTitle:@" Cuộc gọi" font:textFont sizeIcon:iconSize color:defColor image:[UIImage imageNamed:@"ipad_menu_dialer_def"]];
    
    [btnDialerIpad setAttributedTitle:dialerDef forState:UIControlStateNormal];
    [btnDialerIpad setAttributedTitle:dialerAct forState:UIControlStateSelected];
    [btnDialerIpad mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.equalTo(viewIpadMenu);
        //  make.width.mas_equalTo(SCREEN_WIDTH/4);
        make.width.equalTo(viewIpadMenu.mas_width).multipliedBy(0.25);
    }];
    btnDialerIpad.selected = YES;
    
    //  call history button
    NSAttributedString *historyAct = [AppUtils getAttributeTitle:@" Lịch sử" font:textFont sizeIcon:iconSize color:actColor image:[UIImage imageNamed:@"ipad_menu_history_act"]];
    NSAttributedString *historyDef = [AppUtils getAttributeTitle:@" Lịch sử" font:textFont sizeIcon:iconSize color:defColor image:[UIImage imageNamed:@"ipad_menu_history_def"]];
    
    [btnCallHistoryIpad setAttributedTitle:historyDef forState:UIControlStateNormal];
    [btnCallHistoryIpad setAttributedTitle:historyAct forState:UIControlStateSelected];
    
    [btnCallHistoryIpad mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(btnDialerIpad.mas_right);
        make.top.bottom.equalTo(viewIpadMenu);
        make.width.equalTo(viewIpadMenu.mas_width).multipliedBy(0.25);
        //  make.width.mas_equalTo(SCREEN_WIDTH/4);
    }];
    
    //  Contacts button
    NSAttributedString *contactsAct = [AppUtils getAttributeTitle:@" Danh bạ" font:textFont sizeIcon:iconSize color:actColor image:[UIImage imageNamed:@"ipad_menu_contacts_act"]];
    NSAttributedString *contactsDef = [AppUtils getAttributeTitle:@" Danh bạ" font:textFont sizeIcon:iconSize color:defColor image:[UIImage imageNamed:@"ipad_menu_contacts_def"]];
    
    [btnContactsIpad setAttributedTitle:contactsDef forState:UIControlStateNormal];
    [btnContactsIpad setAttributedTitle:contactsAct forState:UIControlStateSelected];
    
    [btnContactsIpad mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(btnCallHistoryIpad.mas_right);
        make.top.bottom.equalTo(viewIpadMenu);
        //  make.width.mas_equalTo(SCREEN_WIDTH/4);
        make.width.equalTo(viewIpadMenu.mas_width).multipliedBy(0.25);
    }];
    
    //  More button
    NSAttributedString *moreAct = [AppUtils getAttributeTitle:@" Xem thêm" font:textFont sizeIcon:iconSize color:actColor image:[UIImage imageNamed:@"ipad_menu_more_act"]];
    NSAttributedString *moreDef = [AppUtils getAttributeTitle:@" Xem thêm" font:textFont sizeIcon:iconSize color:defColor image:[UIImage imageNamed:@"ipad_menu_more_def"]];
    
    [btnMoreIpad setAttributedTitle:moreDef forState:UIControlStateNormal];
    [btnMoreIpad setAttributedTitle:moreAct forState:UIControlStateSelected];
    [btnMoreIpad mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.equalTo(viewIpadMenu);
        //  make.width.mas_equalTo(SCREEN_WIDTH/4);
        make.width.equalTo(viewIpadMenu.mas_width).multipliedBy(0.25);
    }];
    
    lbMenuTopSepa.backgroundColor = [UIColor colorWithRed:(225/255.0) green:(225/255.0) blue:(225/255.0) alpha:1.0];
    [lbMenuTopSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(viewIpadMenu);
        make.height.mas_equalTo(1.0);
    }];
}

@end
