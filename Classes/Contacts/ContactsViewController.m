//
//  ContactsViewController.m
//  linphone
//
//  Created by Ei Captain on 6/30/16.
//
//

#import "ContactsViewController.h"
#import "AllContactsViewController.h"
#import "PBXContactsViewController.h"
#import "StatusBarView.h"
#import "TabBarView.h"

@interface ContactsViewController (){
    AllContactsViewController *allContactsVC;
    PBXContactsViewController *pbxContactsVC;
    int currentView;
    float hIcon;
    float paddingContent;
    
    NSTimer *searchTimer;
}
@end

@implementation ContactsViewController
@synthesize _pageViewController, _viewHeader, _iconAll, _iconPBX, icGroupPBX, _tfSearch, imgBackground, _icClearSearch, lbSepa, lbSepa2;
@synthesize _listSyncContact, _phoneForSync;

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:nil
                                                                 tabBar:TabBarView.class
                                                               sideMenu:nil
                                                             fullscreen:false
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
    //  MY CODE HERE
    _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.view.backgroundColor = UIColor.clearColor;
    
    [self autoLayoutForMainView];
    
    currentView = eContactAll;
    [self updateStateIconWithView: currentView];
    
    _pageViewController.view.backgroundColor = UIColor.clearColor;
    _pageViewController.delegate = self;
    _pageViewController.dataSource = self;
    
    pbxContactsVC = [[PBXContactsViewController alloc] init];
    allContactsVC = [[AllContactsViewController alloc] init];
    
    NSArray *viewControllers = [NSArray arrayWithObject:allContactsVC];
    [_pageViewController setViewControllers:viewControllers
                                  direction:UIPageViewControllerNavigationDirectionForward
                                   animated:true completion:nil];
    _pageViewController.view.layer.shadowColor = UIColor.clearColor.CGColor;
    _pageViewController.view.layer.borderWidth = 0.0;
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
    
    if (![_tfSearch.text isEqualToString:@""]) {
        _icClearSearch.hidden = NO;
    }else{
        _icClearSearch.hidden = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeKeyboard)
                                                 name:@"closeKeyboard" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [AppUtils addBoxShadowForView:_tfSearch withColor:[UIColor colorWithRed:(100/255.0) green:(100/255.0) blue:(100/255.0) alpha:1.0]];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark – UIPageViewControllerDelegate Method

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if (viewController == allContactsVC){
        currentView = eContactAll;
        [self updateStateIconWithView: currentView];
        return nil;
    }else{
        currentView = eContactPBX;
        [self updateStateIconWithView: currentView];
        return allContactsVC;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if (viewController == allContactsVC){
        currentView = eContactAll;
        [self updateStateIconWithView: currentView];
        return pbxContactsVC;
    }else{
        currentView = eContactPBX;
        [self updateStateIconWithView: currentView];
        return nil;
    }
}

- (IBAction)_iconAllClicked:(id)sender {
    currentView = eContactAll;
    [self updateStateIconWithView:currentView];
    [_pageViewController setViewControllers: @[allContactsVC]
                                  direction: UIPageViewControllerNavigationDirectionReverse
                                   animated: false completion: nil];
    
    _tfSearch.text = @"";
    _icClearSearch.hidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:searchContactWithValue
                                                        object:_tfSearch.text];
}

- (IBAction)_iconPBXClicked:(UIButton *)sender {
    currentView = eContactPBX;
    [self updateStateIconWithView:currentView];
    [_pageViewController setViewControllers: @[pbxContactsVC]
                                  direction: UIPageViewControllerNavigationDirectionForward
                                   animated: false completion: nil];
    
    _tfSearch.text = @"";
}

- (IBAction)_icClearSearchClicked:(UIButton *)sender {
    _icClearSearch.hidden = YES;
    _tfSearch.text = @"";
    [[NSNotificationCenter defaultCenter] postNotificationName:searchContactWithValue
                                                        object:_tfSearch.text];
}

- (IBAction)iconGroupPBXPress:(UIButton *)sender {
}

//  setup trạng thái cho các button
- (void)autoLayoutForMainView {
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    
    float hTextfield = 40.0;
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE])
    {
        hTextfield = 33.0;
        
    }
    
    
    float hButton = 40.0;
    paddingContent = 30.0;
    
    hIcon = [LinphoneAppDelegate sharedInstance]._hRegistrationState - [LinphoneAppDelegate sharedInstance]._hStatus;
    _viewHeader.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                   blue:(240/255.0) alpha:1.0];
    float hHeader = [LinphoneAppDelegate sharedInstance]._hRegistrationState + 40.0;
    [_viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hHeader);
    }];
    
    [imgBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(_viewHeader);
        make.bottom.equalTo(_viewHeader).offset(-(hTextfield+10.0)/2);
    }];
    
    float marginTop = [LinphoneAppDelegate sharedInstance]._hStatus + (hHeader - [LinphoneAppDelegate sharedInstance]._hStatus - hTextfield - 10 - hButton)/ 2;
    
    
    lbSepa.backgroundColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                              blue:(220/255.0) alpha:1.0];
    [lbSepa mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset(marginTop + 10);
        make.centerX.equalTo(_viewHeader.mas_centerX);
        make.width.mas_equalTo(1.0);
        make.height.mas_equalTo(hButton - 20);
    }];
    
    float padding = 30.0;
    _iconAll.backgroundColor = UIColor.clearColor;
    [_iconAll setTitle:[[LanguageUtil sharedInstance] getContent:@"All contacts"] forState:UIControlStateNormal];
    [_iconAll setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _iconAll.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [_iconAll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(lbSepa.mas_left).offset(-padding);
        make.top.equalTo(_viewHeader).offset(marginTop);
        make.left.equalTo(_viewHeader).offset(5.0);
        make.height.mas_equalTo(hButton);
    }];
    
    _iconPBX.backgroundColor = UIColor.clearColor;
    [_iconPBX setTitle:[[LanguageUtil sharedInstance] getContent:@"PBX contacts"] forState:UIControlStateNormal];
    [_iconPBX setTitleColor:[UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                             blue:(220/255.0) alpha:1.0]
                   forState:UIControlStateNormal];
    _iconPBX.titleLabel.font = [LinphoneAppDelegate sharedInstance].headerFontBold;
    [_iconPBX mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset(marginTop);
        make.left.equalTo(lbSepa.mas_right).offset(padding);
        make.right.equalTo(_viewHeader).offset(-5.0);
        make.height.mas_equalTo(hButton);
    }];
    
    _tfSearch.backgroundColor = UIColor.whiteColor;
    _tfSearch.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    _tfSearch.placeholder = [[LanguageUtil sharedInstance] getContent:@"Search name or phone number"];
    _tfSearch.textColor = UIColor.darkGrayColor;

    [_tfSearch addTarget:self
                  action:@selector(onSearchContactChange:)
        forControlEvents:UIControlEventEditingChanged];
    
    UIView *pLeft = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22.0, hTextfield)];
    _tfSearch.leftView = pLeft;
    _tfSearch.leftViewMode = UITextFieldViewModeAlways;
    
    [_tfSearch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_viewHeader).offset(-5.0);
        make.left.equalTo(self.view).offset(paddingContent);
        make.right.equalTo(self.view).offset(-paddingContent);
        make.height.mas_equalTo(hTextfield);
    }];
    
    _tfSearch.clipsToBounds = YES;
    _tfSearch.layer.cornerRadius = 7.0;
    
    UIImageView *imgSearch = [[UIImageView alloc] init];
    imgSearch.image = [UIImage imageNamed:@"ic_search_gray"];
    [_tfSearch addSubview: imgSearch];
    [imgSearch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_tfSearch.mas_centerY);
        make.left.equalTo(_tfSearch).offset(8.0);
        make.width.height.mas_equalTo(17.0);
    }];
    
    _icClearSearch.backgroundColor = UIColor.clearColor;
    [_icClearSearch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.bottom.equalTo(_tfSearch);
        make.width.mas_equalTo(hTextfield);
    }];
}

//  Cập nhật trạng thái của các icon trên header
- (void)updateStateIconWithView: (int)view
{
    if (view == eContactAll){
        [_iconAll setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_iconPBX setTitleColor:[UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                                 blue:(220/255.0) alpha:1.0]
                       forState:UIControlStateNormal];
    }else{
        [_iconAll setTitleColor:[UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                                 blue:(220/255.0) alpha:1.0]
                       forState:UIControlStateNormal];
        [_iconPBX setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
}

//  Added by Khai Le on 04/10/2018
- (void)onSearchContactChange: (UITextField *)textField {
    if (![textField.text isEqualToString:@""]) {
        _icClearSearch.hidden = NO;
    }else{
        _icClearSearch.hidden = YES;
    }
    
    [searchTimer invalidate];
    searchTimer = nil;
    searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self
                                                 selector:@selector(startSearchPhoneBook)
                                                 userInfo:nil repeats:NO];
}

- (void)startSearchPhoneBook {
    [[NSNotificationCenter defaultCenter] postNotificationName:searchContactWithValue
                                                        object:_tfSearch.text];
}

- (void)closeKeyboard {
    [self.view endEditing: YES];
}

@end
