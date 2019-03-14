//
//  KContactDetailViewController.m
//  linphone
//
//  Created by mac book on 11/5/15.
//
//

#import "KContactDetailViewController.h"
#import "UIKContactCell.h"
#import "UIContactPhoneCell.h"
#import "JSONKit.h"
#import "NSData+Base64.h"
#import "TypePhoneContact.h"
#import "ContactDetailObj.h"

@interface KContactDetailViewController (){
    LinphoneAppDelegate *appDelegate;
    float hCell;
    
    YBHud *waitingHud;
    BOOL isPBXContact;
    
    UIButton *btnDelete;
}
@end

@implementation KContactDetailViewController
@synthesize _viewHeader, _iconBack, _imgAvatar, _lbContactName, _tbContactInfo;
@synthesize detailsContact;

#pragma mark - UICompositeViewDelegate Functions
static UICompositeViewDescription *compositeDescription = nil;
+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:nil
                                                                 tabBar:nil
                                                               sideMenu:nil
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //  MY CODE HERE
    appDelegate = (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self autoLayoutForView];
    
    //  add waiting view
    waitingHud = [[YBHud alloc] initWithHudType:DGActivityIndicatorAnimationTypeLineScale andText:@""];
    waitingHud.tintColor = [UIColor whiteColor];
    waitingHud.dimAmount = 0.5;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [WriteLogsUtils writeForGoToScreen: @"KContactDetailViewController"];
    
    // Tắt màn hình cảm biến
    UIDevice *device = [UIDevice currentDevice];
    [device setProximityMonitoringEnabled: NO];
    
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Get contact info with id: %d", appDelegate.idContact]
                         toFilePath:appDelegate.logFilePath];
    
    detailsContact = [ContactUtils getContactWithId: appDelegate.idContact];
    if (![AppUtils isNullOrEmpty:detailsContact._sipPhone]) {
        isPBXContact = YES;
    }else{
        isPBXContact = NO;
    }
    
    [self displayContactInformation];
    [_tbContactInfo reloadData];
    
    [btnDelete setTitle:[[LanguageUtil sharedInstance] getContent:@"Delete contact"]
               forState:UIControlStateNormal];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    //  [self setupFooterForTableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    _tbContactInfo.tableFooterView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
}

- (void)viewDidUnload {
    [self set_iconBack:nil];
    [self set_imgAvatar:nil];
    [self set_lbContactName:nil];
    [self set_tbContactInfo:nil];
    [super viewDidUnload];
}

- (IBAction)_iconBackClicked:(id)sender {
    [[PhoneMainView instance] popCurrentView];
}

#pragma mark - my functions

- (void)autoLayoutForView
{
    self.view.backgroundColor = UIColor.whiteColor;
    if (SCREEN_WIDTH > 320) {
        hCell = 70.0;
    }else{
        hCell = 60.0;
    }
    
    //  header
    float hHeader = 180+[LinphoneAppDelegate sharedInstance]._hStatus;
    _viewHeader.backgroundColor = UIColor.clearColor;
    [_viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hHeader);
    }];
    
    _iconBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [_iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset(appDelegate._hStatus);
        make.left.equalTo(_viewHeader);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    float wAvatar = 100.0;
    _imgAvatar.layer.cornerRadius = wAvatar/2;
    _imgAvatar.layer.borderWidth = 2.0;
    _imgAvatar.layer.borderColor = UIColor.whiteColor.CGColor;
    _imgAvatar.clipsToBounds = YES;
    [_imgAvatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_iconBack.mas_centerY);
        make.centerX.equalTo(_viewHeader.mas_centerX);
        make.width.height.mas_equalTo(wAvatar);
    }];
    
    [_lbContactName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_imgAvatar.mas_bottom).offset(5.0);
        make.left.right.equalTo(_viewHeader);
        make.height.mas_equalTo(45.0);
    }];
    _lbContactName.marqueeType = MLContinuous;
    _lbContactName.scrollDuration = 15.0;
    _lbContactName.animationCurve = UIViewAnimationOptionCurveEaseInOut;
    _lbContactName.fadeLength = 10.0;
    _lbContactName.continuousMarqueeExtraBuffer = 10.0f;
    _lbContactName.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    _lbContactName.textColor = UIColor.whiteColor;
    
    
    //  content
    [_tbContactInfo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    _tbContactInfo.delegate = self;
    _tbContactInfo.dataSource = self;
    _tbContactInfo.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tbContactInfo.backgroundColor = UIColor.clearColor;
    
    UIBezierPath *path = [UIBezierPath new];
    [path moveToPoint: CGPointMake(0, 0)];
    [path addLineToPoint: CGPointMake(0, hHeader-50)];
    [path addQuadCurveToPoint:CGPointMake(SCREEN_WIDTH, hHeader-50) controlPoint:CGPointMake(SCREEN_WIDTH/2, hHeader+50)];
    [path addLineToPoint: CGPointMake(SCREEN_WIDTH, 0)];
    [path closePath];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer new];
    shapeLayer.path = path.CGPath;
    //  shapeLayer.fillColor = UIColor.clearColor.CGColor;
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, hHeader+100);
    gradientLayer.startPoint = CGPointMake(0, 1);
    gradientLayer.endPoint = CGPointMake(1, 0);
    gradientLayer.colors = @[(id)[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0].CGColor, (id)[UIColor colorWithRed:(60/255.0) green:(198/255.0) blue:(116/255.0) alpha:1.0].CGColor];
    
    //Add gradient layer to view
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
    gradientLayer.mask = shapeLayer;
}

//  Hiển thị thông tin của contact
- (void)displayContactInformation
{
    if ([detailsContact._fullName isEqualToString:@""] && ![detailsContact._sipPhone isEqualToString:@""]) {
        _lbContactName.text = detailsContact._sipPhone;
    }else{
        _lbContactName.text = detailsContact._fullName;
    }
    
    //  Avatar contact
    if ([AppUtils isNullOrEmpty:detailsContact._avatar]) {
        _imgAvatar.image = [UIImage imageNamed:@"no_avatar.png"];
    }else{
        _imgAvatar.image = [UIImage imageWithData: [NSData dataFromBase64String: detailsContact._avatar]];
    }
}

//  Xử lý số phone
- (NSString *)changeAddressNumber: (NSString *)phoneString
{
    phoneString = [phoneString stringByReplacingOccurrencesOfString:@" " withString:@""];
    phoneString = [phoneString stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    if ([phoneString hasPrefix:@"84"]) {
        phoneString = [phoneString substringFromIndex: 2];
        phoneString = [NSString stringWithFormat:@"0%@", phoneString];
    }
    return phoneString;
}

#pragma mark - Tableview Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int numRow = [self getRowForSection];
    return numRow;
    
    if (detailsContact._sipPhone != nil && ![detailsContact._sipPhone isEqualToString:@""]) {
        return detailsContact._listPhone.count + 1;
    }else{
        return detailsContact._listPhone.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < detailsContact._listPhone.count)
    {
        static NSString *CellIdentifier = @"UIContactPhoneCell";
        UIContactPhoneCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UIContactPhoneCell" owner:self options:nil];
            cell = topLevelObjects[0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        ContactDetailObj *anItem = [detailsContact._listPhone objectAtIndex: indexPath.row];
        cell.lbTitle.text = anItem._titleStr;
        cell.lbPhone.text = anItem._valueStr;
        
        [cell.icCall setTitle:anItem._valueStr forState:UIControlStateNormal];
        [cell.icCall addTarget:self
                        action:@selector(onIconCallClicked:)
              forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }else{
        static NSString *CellIdentifier = @"UIKContactCell";
        UIKContactCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier];
        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"UIKContactCell" owner:self options:nil];
            cell = topLevelObjects[0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.row == detailsContact._listPhone.count) {
            if (detailsContact._company != nil && ![detailsContact._company isEqualToString:@""]) {
                cell.lbTitle.text = [[LanguageUtil sharedInstance] getContent:@"Company"];
                cell.lbValue.text = detailsContact._company;
            }else if (detailsContact._email != nil && ![detailsContact._email isEqualToString:@""]){
                cell.lbTitle.text = [[LanguageUtil sharedInstance] getContent:@"Email"];
                cell.lbValue.text = detailsContact._email;
            }
        }else if (indexPath.row == detailsContact._listPhone.count + 1){
            if (detailsContact._email != nil && ![detailsContact._email isEqualToString:@""]){
                cell.lbTitle.text = [[LanguageUtil sharedInstance] getContent:@"Email"];
                cell.lbValue.text = detailsContact._email;
            }
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return hCell;
}

#pragma mark - Alertview Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Confirm delete this contact", __FUNCTION__] toFilePath:appDelegate.logFilePath];
        
        [waitingHud showInView:self.view animated:YES];
        
        // Remove khỏi addressbook
        BOOL result = [ContactUtils deleteContactFromPhoneWithId: detailsContact._id_contact];
        if(result){
            [self updateContactListAfterDeleteContact: detailsContact];
            
            NSString *msgContent = [[LanguageUtil sharedInstance] getContent:@"Contact has been deleted"];
            [self.view makeToast:msgContent duration:2.0 position:CSToastPositionCenter];
        }
        [waitingHud dismissAnimated:YES];

        [[PhoneMainView instance] popCurrentView];
    }
}


//  Added by Khai Le on 05/10/2018
- (int)getRowForSection {
    int result = (int)detailsContact._listPhone.count;
    
    if (detailsContact._company != nil && ![detailsContact._company isEqualToString:@""]) {
        result = result + 1;
    }
    if (detailsContact._email != nil && ![detailsContact._email isEqualToString:@""]) {
        result = result + 1;
    }
    return result;
}

- (void)setupFooterForTableView {
    UIView *footerView = [_tbContactInfo tableFooterView];
    if (footerView == nil) {
        float hFooterDefault = 100.0;
        footerView = [[UIView alloc] init];
        footerView.backgroundColor = UIColor.greenColor;
        if (_tbContactInfo.contentSize.height > _tbContactInfo.frame.size.height) {
            footerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, hFooterDefault);
            _tbContactInfo.scrollEnabled = YES;
        }else{
            float tmpHeight = _tbContactInfo.frame.size.height - _tbContactInfo.contentSize.height;
            if (tmpHeight <= hFooterDefault) {
                footerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, hFooterDefault);
                _tbContactInfo.scrollEnabled = YES;
            }else{
                footerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, tmpHeight);
                _tbContactInfo.scrollEnabled = NO;
            }
        }
        footerView.backgroundColor = UIColor.clearColor;
        _tbContactInfo.tableFooterView = footerView;
        
        btnDelete = [[UIButton alloc] init];
        btnDelete.backgroundColor = [UIColor colorWithRed:(202/255.0) green:(212/255.0)
                                                     blue:(223/255.0) alpha:1.0];
        [btnDelete setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [btnDelete setTitle:[[LanguageUtil sharedInstance] getContent:@"Delete contact"]
                   forState:UIControlStateNormal];
        btnDelete.titleLabel.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:20.0];
        [footerView addSubview: btnDelete];
        
        [btnDelete mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(footerView).offset(-25.0);
            make.left.equalTo(footerView).offset(50);
            make.right.equalTo(footerView).offset(-50);
            make.height.mas_equalTo(50.0);
        }];
        btnDelete.clipsToBounds = YES;
        btnDelete.layer.cornerRadius = 50.0/2;
        
        [btnDelete addTarget:self
                      action:@selector(btnDeleteContactPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    }else{
        NSLog(@"You setted FooterView for UITableview");
    }
}

- (void)btnDeleteContactPressed: (UIButton *)sender
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:appDelegate.logFilePath];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[LanguageUtil sharedInstance] getContent:@"Delete contact"] message:[[LanguageUtil sharedInstance] getContent:@"Are you sure, you want to delete this contact?"] delegate:self cancelButtonTitle:[[LanguageUtil sharedInstance] getContent:@"Cancel"] otherButtonTitles:[[LanguageUtil sharedInstance] getContent:@"Accept"], nil];
    alertView.delegate = self;
    [alertView show];
}

- (void)onIconCallClicked: (UIButton *)sender
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Call from %@ to %@", __FUNCTION__, USERNAME, sender.currentTitle] toFilePath:appDelegate.logFilePath];
    
    if (![AppUtils isNullOrEmpty: sender.currentTitle]) {
        NSString *number = [AppUtils removeAllSpecialInString: sender.currentTitle];
        if (![AppUtils isNullOrEmpty: number]) {
            [SipUtils makeCallWithPhoneNumber: number];
        }
    }else{
        [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"The phone number can not empty"]
                    duration:2.0 position:CSToastPositionCenter];
    }
}

- (void)updateContactListAfterDeleteContact: (ContactObject *)contact {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"contactId = %d", contact._id_contact];
    NSArray *filter = [appDelegate.listInfoPhoneNumber filteredArrayUsingPredicate: predicate];
    if (filter.count > 0) {
        [appDelegate.listInfoPhoneNumber removeObjectsInArray: filter];
    }
    [appDelegate.listContacts removeObject: contact];
}

@end
