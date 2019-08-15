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
    BOOL isPBXContact;
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [WriteLogsUtils writeForGoToScreen: @"KContactDetailViewController"];
    
    detailsContact = [ContactUtils getContactWithId: appDelegate.idContact];
    if (![AppUtils isNullOrEmpty:detailsContact._sipPhone]) {
        isPBXContact = YES;
    }else{
        isPBXContact = NO;
    }
    
    [self displayContactInformation];
    [_tbContactInfo reloadData];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (_tbContactInfo.frame.size.height >= _tbContactInfo.contentSize.height) {
        _tbContactInfo.scrollEnabled = NO;
    }else{
        _tbContactInfo.scrollEnabled = YES;
    }
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
    
    UIEdgeInsets backEdge = UIEdgeInsetsMake(5, 5, 5, 5);
    float wAvatar = 100.0;
    float hHeader = 180+[LinphoneAppDelegate sharedInstance]._hStatus;
    hCell = 70.0;
    
    NSString *deviceMode = [DeviceUtils getModelsOfCurrentDevice];
    if ([deviceMode isEqualToString: Iphone5_1] || [deviceMode isEqualToString: Iphone5_2] || [deviceMode isEqualToString: Iphone5s_1] || [deviceMode isEqualToString: Iphone5s_2] || [deviceMode isEqualToString: Iphone5c_1] || [deviceMode isEqualToString: Iphone5c_2] || [deviceMode isEqualToString: IphoneSE])
    {
        backEdge = UIEdgeInsetsMake(6.5, 6.5, 6.5, 6.5);
        wAvatar = 80.0;
        hHeader = 170+[LinphoneAppDelegate sharedInstance]._hStatus;
        hCell = 60.0;
    }
    
    //  header
    _viewHeader.backgroundColor = UIColor.clearColor;
    [_viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hHeader);
    }];
    
    _iconBack.imageEdgeInsets = backEdge;
    [_iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_viewHeader).offset(appDelegate._hStatus);
        make.left.equalTo(_viewHeader);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
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
    _lbContactName.font = [LinphoneAppDelegate sharedInstance].contentFontBold;
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
        phoneString = SFM(@"0%@", phoneString);
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
        cell.icCall.tag = AUDIO_CALL_TYPE;
        [cell.icCall addTarget:self
                        action:@selector(onIconCallClicked:)
              forControlEvents:UIControlEventTouchUpInside];
        
        [cell.icVideoCall setTitle:anItem._valueStr forState:UIControlStateNormal];
        cell.icVideoCall.tag = VIDEO_CALL_TYPE;
        [cell.icVideoCall addTarget:self
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
                cell.lbTitle.text = text_company;
                cell.lbValue.text = detailsContact._company;
            }else if (detailsContact._email != nil && ![detailsContact._email isEqualToString:@""]){
                cell.lbTitle.text = text_email;
                cell.lbValue.text = detailsContact._email;
            }
        }else if (indexPath.row == detailsContact._listPhone.count + 1){
            if (detailsContact._email != nil && ![detailsContact._email isEqualToString:@""]){
                cell.lbTitle.text = text_email;
                cell.lbValue.text = detailsContact._email;
            }
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return hCell;
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

- (void)onIconCallClicked: (UIButton *)sender
{
    [WriteLogsUtils writeLogContent:SFM(@"[%s] call to: %@", __FUNCTION__, sender.currentTitle) toFilePath:appDelegate.logFilePath];
    
    if (![AppUtils isNullOrEmpty: sender.currentTitle]) {
        NSString *phoneNumber = [AppUtils removeAllSpecialInString: sender.currentTitle];
        if (![AppUtils isNullOrEmpty: phoneNumber]) {
            if (sender.tag == AUDIO_CALL_TYPE) {
                [[NSUserDefaults standardUserDefaults] setObject:@"0" forKey:IS_VIDEO_CALL_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }else{
                [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:IS_VIDEO_CALL_KEY];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [LinphoneAppDelegate sharedInstance].phoneForCall = phoneNumber;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:getDIDListForCall object:nil];
        }
        return;
    }
    [self.view makeToast:text_phone_empty duration:2.0 position:CSToastPositionCenter];
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
