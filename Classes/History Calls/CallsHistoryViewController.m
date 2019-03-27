//
//  CallsHistoryViewController.m
//  linphone
//
//  Created by Ei Captain on 7/5/16.
//
//

#import "CallsHistoryViewController.h"
#import "AllCallsViewController.h"
#import "MissedCallViewController.h"
#import "RecordsCallViewController.h"
#import "TabBarView.h"

@interface CallsHistoryViewController () {
    int currentView;
    AllCallsViewController *allCallsVC;
    MissedCallViewController *missedCallsVC;
    RecordsCallViewController *recordCallsVC;
    UIColor *noActiveColor;
    float hIcon;
}

@end

@implementation CallsHistoryViewController
@synthesize _viewHeader, _btnEdit, _iconAll, _iconMissed, bgHeader, lbSepa, lbSepa2, _iconRecord;
@synthesize _pageViewController, _vcIndex;

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
                                                           fragmentWith:nil];
    }
    return compositeDescription;
}

- (UICompositeViewDescription *)compositeViewDescription {
    return self.class.compositeViewDescription;
}

#pragma mark - My controller
- (void)viewDidLoad {
    [super viewDidLoad];
    // MY CODE HERE
    
    //  notifications
    //  Sau khi xoá tất cả các cuộc gọi
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetUIForView)
                                                 name:k11ReloadAfterDeleteAllCall object:nil];
    
    self.view.backgroundColor = UIColor.whiteColor;
    noActiveColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0) blue:(220/255.0) alpha:1.0];
    [self autoLayoutForView];
    currentView = eAllCalls;
    [self updateStateIconWithView: currentView];
    
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                          navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                        options:nil];
    
    _pageViewController.view.backgroundColor = UIColor.clearColor;
    _pageViewController.delegate = self;
    //_pageViewController.dataSource = self;
    
    allCallsVC = [[AllCallsViewController alloc] init];
    missedCallsVC = [[MissedCallViewController alloc] init];
    recordCallsVC = [[RecordsCallViewController alloc] init];
    
    NSArray *viewControllers = [NSArray arrayWithObject:allCallsVC];
    [_pageViewController setViewControllers:viewControllers
                                  direction:UIPageViewControllerNavigationDirectionForward
                                   animated:false
                                 completion:nil];
    _pageViewController.view.layer.shadowColor = UIColor.clearColor.CGColor;
    _pageViewController.view.layer.borderWidth = 0;
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    
    [_pageViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _btnEdit.tag = 0;
    [_btnEdit setImage:[UIImage imageNamed:@"ic_trash"] forState:UIControlStateNormal];
    
    [self showContentWithCurrentLanguage];
    
    //  Reset lại các UI khi vào màn hình
    [self resetUIForView];
    
    // Reset missed call
    linphone_core_reset_missed_calls_count([LinphoneManager getLc]);
    
    // Fake event
    [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneCallUpdate object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDeleteCallHistory:)
                                                 name:showOrHideDeleteCallHistoryButton object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)_iconAllClicked:(id)sender {
    if (currentView == eAllCalls) {
        return;
    }
    
    currentView = eAllCalls;
    [self updateStateIconWithView:currentView];
    [_pageViewController setViewControllers:@[allCallsVC]
                                  direction:UIPageViewControllerNavigationDirectionReverse
                                   animated:false completion:nil];
}

- (IBAction)_iconMissedClicked:(id)sender {
    if (currentView == eMissedCalls) {
        return;
    }
    
    currentView = eMissedCalls;
    [self updateStateIconWithView:currentView];
    [_pageViewController setViewControllers: @[missedCallsVC]
                                  direction: UIPageViewControllerNavigationDirectionReverse
                                   animated: false completion: nil];
}

- (IBAction)_iconRecordClicked:(UIButton *)sender {
    _btnEdit.hidden = YES;
    
    if (currentView == eRecordCalls) {
        return;
    }
    
    currentView = eRecordCalls;
    [self updateStateIconWithView:currentView];
    [_pageViewController setViewControllers: @[recordCallsVC]
                                  direction: UIPageViewControllerNavigationDirectionReverse
                                   animated: false completion: nil];
}

- (IBAction)_btnEditPressed:(id)sender {
    if (_btnEdit.tag == 0) {
        _btnEdit.tag = 1;
        [_btnEdit setImage:[UIImage imageNamed:@"ic_tick"]
                  forState:UIControlStateNormal];
    }else{
        _btnEdit.tag = 0;
        [_btnEdit setImage:[UIImage imageNamed:@"ic_trash"]
                  forState:UIControlStateNormal];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:deleteHistoryCallsChoosed
                                                        object:[NSNumber numberWithInt:(int)_btnEdit.tag]];
}

- (void)showDeleteCallHistory: (NSNotification *)notif {
    if (currentView == eRecordCalls) {
        _btnEdit.hidden = YES;
        return;
    }
    
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString *value = [notif object];
        if ([value isEqualToString:@"1"]) {
            _btnEdit.hidden = NO;
        }else{
            _btnEdit.hidden = YES;
        }
    }
}

#pragma mark – UIPageViewControllerDelegate Method

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if (viewController == allCallsVC) {
        currentView = eAllCalls;
        [self updateStateIconWithView: currentView];
        return nil;
    }else if (viewController == missedCallsVC){
        currentView = eMissedCalls;
        [self updateStateIconWithView: currentView];
        return allCallsVC;
    }else{
        currentView = eRecordCalls;
        [self updateStateIconWithView: currentView];
        return missedCallsVC;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if (viewController == allCallsVC) {
        currentView = eAllCalls;
        [self updateStateIconWithView: currentView];
        return missedCallsVC;
    }else if (viewController == missedCallsVC) {
        currentView = eMissedCalls;
        [self updateStateIconWithView: currentView];
        return recordCallsVC;
    }else {
        currentView = eRecordCalls;
        [self updateStateIconWithView: currentView];
        return nil;
    }
}

#pragma mark - My functions

- (void)showContentWithCurrentLanguage {
    [_iconAll setTitle:[[LanguageUtil sharedInstance] getContent:@"All history"] forState:UIControlStateNormal];
    [_iconMissed setTitle:[[LanguageUtil sharedInstance] getContent:@"Missed history"] forState:UIControlStateNormal];
}

//  Reset lại các UI khi vào màn hình
- (void)resetUIForView {
    _btnEdit.hidden = NO;
    _iconAll.hidden = NO;
    _iconMissed.hidden = NO;
}

//  Cập nhật trạng thái của các icon trên header
- (void)updateStateIconWithView: (int)view
{
    if (view == eAllCalls){
        [_iconAll setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_iconMissed setTitleColor:noActiveColor forState:UIControlStateNormal];
        [_iconRecord setTitleColor:noActiveColor forState:UIControlStateNormal];
    }else if (view == eMissedCalls){
        [_iconAll setTitleColor:noActiveColor forState:UIControlStateNormal];
        [_iconMissed setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_iconRecord setTitleColor:noActiveColor forState:UIControlStateNormal];
    }else{
        [_iconAll setTitleColor:noActiveColor forState:UIControlStateNormal];
        [_iconMissed setTitleColor:noActiveColor forState:UIControlStateNormal];
        [_iconRecord setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
}


//  setup trạng thái cho các button
- (void)autoLayoutForView {
    float hHeader = [LinphoneAppDelegate sharedInstance]._hRegistrationState;
    float hButton = 40.0;
    float padding = 15.0;
    
    hIcon = [LinphoneAppDelegate sharedInstance]._hRegistrationState - [LinphoneAppDelegate sharedInstance]._hStatus;
    
    [_viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hHeader);
    }];
    
    [bgHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(_viewHeader);
    }];
    
    float marginTop = [LinphoneAppDelegate sharedInstance]._hStatus + (hHeader - [LinphoneAppDelegate sharedInstance]._hStatus - hButton)/ 2;
    
    CGSize sizeButton = [AppUtils getSizeWithText:[[LanguageUtil sharedInstance] getContent:@"Missed history"] withFont:[LinphoneAppDelegate sharedInstance].headerFontBold andMaxWidth:SCREEN_WIDTH];
    
    _iconMissed.backgroundColor = UIColor.clearColor;
    _iconMissed.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_iconMissed setTitle:[[LanguageUtil sharedInstance] getContent:@"Missed history"] forState:UIControlStateNormal];
    [_iconMissed setTitleColor:noActiveColor forState:UIControlStateNormal];
    _iconMissed.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [_iconMissed mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset(marginTop);
        make.centerX.equalTo(_viewHeader.mas_centerX);
        make.width.mas_equalTo(sizeButton.width);
        make.height.mas_equalTo(hButton);
    }];
    
    lbSepa.backgroundColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                              blue:(220/255.0) alpha:1.0];
    [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset(marginTop + 10);
        make.right.equalTo(_iconMissed.mas_left).offset(-padding);
        make.width.mas_equalTo(1.0);
        make.height.mas_equalTo(hButton - 20);
    }];
    
    _iconAll.backgroundColor = UIColor.clearColor;
    _iconAll.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_iconAll setTitle:[[LanguageUtil sharedInstance] getContent:@"All history"] forState:UIControlStateNormal];
    [_iconAll setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _iconAll.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [_iconAll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(lbSepa.mas_left).offset(-padding);
        make.top.equalTo(_viewHeader).offset(marginTop);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(hButton);
    }];
    
    lbSepa2.backgroundColor = lbSepa.backgroundColor;
    [lbSepa2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(lbSepa);
        make.left.equalTo(_iconMissed.mas_right).offset(padding);
        make.width.mas_equalTo(1.0);
    }];
    
    _iconRecord.backgroundColor = UIColor.clearColor;
    [_iconRecord setTitle:[[LanguageUtil sharedInstance] getContent:@"Records call"] forState:UIControlStateNormal];
    [_iconRecord setTitleColor:noActiveColor forState:UIControlStateNormal];
    _iconRecord.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [_iconRecord mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(lbSepa2.mas_right).offset(padding);
        make.top.equalTo(_viewHeader).offset(marginTop);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(hButton);
    }];
    
    _btnEdit.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [_btnEdit mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_viewHeader.mas_right).offset(-2.0);
        make.centerY.equalTo(_iconAll.mas_centerY);
        make.width.height.equalTo(_iconAll.mas_height);
    }];
}

@end
