//
//  PBXContactsViewController.m
//  linphone
//
//  Created by Apple on 5/11/17.
//
//

#import "PBXContactsViewController.h"
#import "NewContactViewController.h"
#import "JSONKit.h"
#import "PBXContact.h"
#import "PBXContactTableCell.h"
#import "UIImage+GKContact.h"
#import "CustomTextAttachment.h"
#import "PBXHeaderView.h"
#import "ChooseSortCell.h"

typedef enum{
    eSortName,
    eSortPhone
}SortType;

@interface PBXContactsViewController ()<PBXHeaderViewDelegate>{
    BOOL isSearching;
    
    NSMutableArray *listSearch;
    NSMutableDictionary *contactSections;
    NSArray *listCharacter;
    BOOL isFound;
    BOOL found;
    float wIconSync;
    float hSection;
    NSMutableArray *pbxList;
    
    WebServices *webService;
    
    UIActivityIndicatorView *waitingView;
    float marginLeft;
    
    PBXHeaderView *pbxHeaderView;
    UITableView *tbSort;
    SortType eSortType;
    BOOL sortAscending;
}

@end

@implementation PBXContactsViewController
@synthesize _tbContacts;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //  my code here
    [self autoLayoutForView];
    [self addHeaderForTableContactsView];
    
    contactSections = [[NSMutableDictionary alloc] init];
    listCharacter = [[NSArray alloc] initWithObjects: @"A", @"B", @"C", @"D", @"E", @"F",
                     @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [WriteLogsUtils writeForGoToScreen: @"PBXContactsViewController"];
    
    if (webService == nil) {
        webService = [[WebServices alloc] init];
        webService.delegate = self;
    }
    
    //  create temp pbx contacts list
    if (pbxList == nil) {
        pbxList = [[NSMutableArray alloc] init];
    }
    [pbxList removeAllObjects];
    //  -----
    [self setupSortInformation];
    
    isSearching = NO;
    
    if (listSearch == nil) {
        listSearch = [[NSMutableArray alloc] init];
    }
    [listSearch removeAllObjects];
    
    if (![LinphoneAppDelegate sharedInstance].contactLoaded)
    {
        [WriteLogsUtils writeLogContent:@"Contact have not loaded yet" toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        NSNumber *pbxId = [[NSUserDefaults standardUserDefaults] objectForKey:PBX_ID_CONTACT];
        if (pbxId != nil) {
            NSArray *contacts = [[LinphoneAppDelegate sharedInstance] getPBXContactPhone:[pbxId intValue]];
            [pbxList addObjectsFromArray: contacts];
            
            [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"Get PBX contacts with id = %d with list = %lu items", [pbxId intValue], (unsigned long)pbxList.count] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
            
            if (pbxList.count > 0) {
                _tbContacts.hidden = NO;
                [_tbContacts reloadData];
            }else{
                _tbContacts.hidden = YES;
            }
        }else{
            _tbContacts.hidden = YES;
        }
    }else{
        if ([LinphoneAppDelegate sharedInstance].pbxContacts != nil) {
            [pbxList addObjectsFromArray: [[LinphoneAppDelegate sharedInstance].pbxContacts copy]];
        }
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"List pbx contact count: %lu", (unsigned long)pbxList.count]
                             toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        pbxHeaderView.lbTitle.text = [NSString stringWithFormat:@"Tất cả liên hện (%d)", (int)pbxList.count];
        
        if (pbxList.count > 0) {
            [_tbContacts reloadData];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSearchContactWithValue:)
                                                 name:searchContactWithValue object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterFinishGetPBXContactsList:)
                                                 name:finishGetPBXContacts object:nil];
}

-(void)viewDidLayoutSubviews {
    CGRect rect = [pbxHeaderView convertRect:pbxHeaderView.tfSort.frame toView:self.view];
    float newYFrame = rect.origin.y + pbxHeaderView.tfSort.frame.size.height + 1;
    if (tbSort == nil) {
        tbSort = [[UITableView alloc] initWithFrame:CGRectMake(rect.origin.x, newYFrame, rect.size.width, 0)];
        tbSort.backgroundColor = UIColor.whiteColor;
        tbSort.separatorStyle = UITableViewCellSelectionStyleNone;
        tbSort.delegate = self;
        tbSort.dataSource = self;
        tbSort.layer.cornerRadius = 5.0;
        tbSort.layer.borderWidth = 1.0;
        tbSort.layer.borderColor = [UIColor colorWithRed:(220/255.0) green:(220/255.0)
                                                    blue:(220/255.0) alpha:1.0].CGColor;
        [self.view addSubview: tbSort];
    }else{
        tbSort.frame = CGRectMake(rect.origin.x, newYFrame, rect.size.width, tbSort.frame.size.height);
    }
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    tbSort.frame = CGRectMake(tbSort.frame.origin.x, tbSort.frame.origin.y, tbSort.frame.size.width, 0);
    
    CGPoint scrollViewOffset = scrollView.contentOffset;
    if (scrollViewOffset.y < 0) {
        [scrollView setContentOffset:CGPointMake(0, 0)];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)_iconClearClicked:(UIButton *)sender {
    [self.view endEditing: true];
    isSearching = NO;
    [_tbContacts reloadData];
}

#pragma mark - Header delegate
- (void)onSyncButtonPress {
    if (USERNAME != nil) {
        pbxHeaderView.btnSync.enabled = NO;
        [self hideWaitingView: NO];
        
        NSString *params = [NSString stringWithFormat:@"username=%@", USERNAME];
        [webService callGETWebServiceWithFunction:get_contacts_func andParams:params];
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] params = %@", __FUNCTION__, params] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    }
}

-(void)onIconSortClick {
    sortAscending = !sortAscending;
    if (sortAscending) {
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:sort_ascending];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:sort_ascending];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [pbxHeaderView updateSortViewInfo];
    [_tbContacts reloadData];
}

- (void)onSortTypeButtonPress {
    if (tbSort.frame.size.height == 0) {
        [UIView animateWithDuration:0.15 animations:^{
            tbSort.frame = CGRectMake(tbSort.frame.origin.x, tbSort.frame.origin.y, tbSort.frame.size.width, 70.0);
        }];
    }else{
        [UIView animateWithDuration:0.15 animations:^{
            tbSort.frame = CGRectMake(tbSort.frame.origin.x, tbSort.frame.origin.y, tbSort.frame.size.width, 0);
        }];
    }
}

#pragma mark - my functions

- (void)addHeaderForTableContactsView {
    NSArray *toplevelObject = [[NSBundle mainBundle] loadNibNamed:@"PBXHeaderView" owner:nil options:nil];
    for(id currentObject in toplevelObject){
        if ([currentObject isKindOfClass:[PBXHeaderView class]]) {
            pbxHeaderView = (PBXHeaderView *) currentObject;
            break;
        }
    }
    pbxHeaderView.delegate = self;
    pbxHeaderView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 80.0);
    [pbxHeaderView setupUIForView];
    _tbContacts.tableHeaderView = pbxHeaderView;
}

//  setup thông tin cho tableview
- (void)autoLayoutForView {
    wIconSync = 17.0;
    hSection = 30.0;
    marginLeft = 15.0;
    
    //  table contacts
    _tbContacts.alwaysBounceVertical = NO;
    _tbContacts.alwaysBounceHorizontal = NO;
    _tbContacts.delegate = self;
    _tbContacts.dataSource = self;
    _tbContacts.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tbContacts mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
}

#pragma mark - UITableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == tbSort) {
        return 1;
    }else{
        if (isSearching) {
            [self getSectionsForContactsList: listSearch];
        }else{
            [self getSectionsForContactsList: pbxList];
        }
        return [[contactSections allKeys] count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == tbSort) {
        return 2;
    }else{
        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:sortAscending selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray* sortedArray = [[contactSections allKeys] sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSString *str = [sortedArray objectAtIndex:section];
        
        return [[contactSections objectForKey:str] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == tbSort) {
        static NSString *identifier = @"ChooseSortCell";
        ChooseSortCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ChooseSortCell" owner:self options:nil];
            cell = topLevelObjects[0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.row == 0) {
            cell.lbName.text = @"Số điện thoại";
            cell.lbSepa.hidden = FALSE;
        }else{
            cell.lbName.text = @"Tên";
            cell.lbSepa.hidden = TRUE;
        }
        return cell;
    }else{
        static NSString *identifier = @"PBXContactTableCell";
        PBXContactTableCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
        if (cell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"PBXContactTableCell" owner:self options:nil];
            cell = topLevelObjects[0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:sortAscending selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray* sortedArray = [[contactSections allKeys] sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSString *key = [sortedArray objectAtIndex:indexPath.section];
        
        PBXContact *contact = [[contactSections objectForKey: key] objectAtIndex:indexPath.row];
        
        // Tên contact
        if (contact._name != nil && ![contact._name isKindOfClass:[NSNull class]]) {
            cell._lbName.text = contact._name;
        }else{
            cell._lbName.text = @"";
        }
        
        if (contact._number != nil && ![contact._number isKindOfClass:[NSNull class]]) {
            cell._lbPhone.text = contact._number;
            
            [cell.icCall setTitle:contact._number forState:UIControlStateNormal];
            cell.icCall.hidden = NO;
            cell.icCall.tag = AUDIO_CALL_TYPE;
            [cell.icCall addTarget:self
                            action:@selector(onIconCallClicked:)
                  forControlEvents:UIControlEventTouchUpInside];
            
            [cell.icVideoCall setTitle:contact._number forState:UIControlStateNormal];
            cell.icVideoCall.hidden = NO;
            cell.icVideoCall.tag = VIDEO_CALL_TYPE;
            [cell.icVideoCall addTarget:self
                                 action:@selector(onIconCallClicked:)
                       forControlEvents:UIControlEventTouchUpInside];
        }else{
            cell._lbPhone.text = @"";
            cell.icCall.hidden = YES;
            cell.icVideoCall.hidden = YES;
        }
        
        if (![LinphoneAppDelegate sharedInstance].supportVideoCall) {
            cell.icVideoCall.hidden = YES;
        }
        
        if (![AppUtils isNullOrEmpty: contact._avatar]) {
            NSData *imageData = [NSData dataFromBase64String:contact._avatar];
            cell._imgAvatar.image = [UIImage imageWithData: imageData];
        }else{
            NSString *firstChar = [contact._name substringToIndex:1];
            UIImage *avatar = [UIImage imageForName:[firstChar uppercaseString] size:CGSizeMake(60.0, 60.0)
                                    backgroundColor:[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0]
                                          textColor:UIColor.whiteColor
                                               font:[UIFont fontWithName:HelveticaNeue size:30.0]];
            cell._imgAvatar.image = avatar;
        }
        
        if ([contact._name isEqualToString:@""]) {
            UIImage *avatar = [UIImage imageForName:@"#" size:CGSizeMake(60.0, 60.0)
                                    backgroundColor:[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0]
                                          textColor:UIColor.whiteColor
                                               font:[UIFont fontWithName:HelveticaNeue size:30.0]];
            cell._imgAvatar.image = avatar;
        }
        
        int count = (int)[[contactSections objectForKey:key] count];
        if (indexPath.row == count-1) {
            cell._lbSepa.hidden = YES;
        }else{
            cell._lbSepa.hidden = NO;
        }
        
        return cell;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == tbSort) {
        if (indexPath.row == 0) {
            eSortType = eSortPhone;
            pbxHeaderView.tfSort.text = @"Số điện thoại";
            
            [[NSUserDefaults standardUserDefaults] setObject:sort_with_phone forKey:key_sort_type];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else{
            eSortType = eSortName;
            pbxHeaderView.tfSort.text = @"Tên";
            
            [[NSUserDefaults standardUserDefaults] setObject:sort_with_name forKey:key_sort_type];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [self onSortTypeButtonPress];
        [pbxHeaderView updateSortViewInfo];
        
        [_tbContacts reloadData];
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == tbSort) {
        return nil;
    }
    
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:sortAscending selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray* sortedArray = [[contactSections allKeys] sortedArrayUsingDescriptors:@[sortDescriptor]];
    NSString *titleHeader = [sortedArray objectAtIndex:section];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, hSection)];
    headerView.backgroundColor = [UIColor colorWithRed:(240/255.0) green:(240/255.0)
                                                  blue:(240/255.0) alpha:1.0];
    
    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(marginLeft, 0, 150, hSection)];
    descLabel.textColor = [UIColor colorWithRed:(50/255.0) green:(50/255.0)
                                           blue:(50/255.0) alpha:1.0];
    descLabel.font = [LinphoneAppDelegate sharedInstance].contentFontBold;
    if ([titleHeader isEqualToString:@"z#"]) {
        descLabel.text = @"#";
    }else{
        descLabel.text = titleHeader;
    }
    descLabel.backgroundColor = UIColor.clearColor;
    [headerView addSubview: descLabel];
    return headerView;
}

//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
//    NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithArray: [[contactSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
//
//    int iCount = 0;
//    while (iCount < tmpArr.count) {
//        NSString *title = [tmpArr objectAtIndex: iCount];
//        if ([title isEqualToString:@"z#"]) {
//            [tmpArr replaceObjectAtIndex:iCount withObject:@"#"];
//            break;
//        }
//        iCount++;
//    }
//    return tmpArr;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == tbSort) {
        return 35.0;
    }
    return 65.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView == tbSort) {
        return 0;
    }
    return hSection;
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboard" object:nil];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboard" object:nil];
}

//  Added by Khai Le on 04/10/2018
- (void)startSearchContactWithValue: (NSNotification *)notif {
    
    id object = [notif object];
    if ([object isKindOfClass:[NSString class]])
    {
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"%s search value = %@", __FUNCTION__, object] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        if ([object isEqualToString:@""]) {
            isSearching = NO;
            [_tbContacts reloadData];
            
        }else{
            isSearching = YES;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self startSearchPBXContactsWithContent: object];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"%s Finished search contact with value = %@", __FUNCTION__, object] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
                    
                    [_tbContacts reloadData];
                });
            });
        }
    }
}

- (void)startSearchPBXContactsWithContent: (NSString *)content {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] search contact = %@", __FUNCTION__, content] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [listSearch removeAllObjects];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"_name CONTAINS[cd] %@ OR _number CONTAINS[cd] %@", content, content];
    NSArray *filter = [pbxList filteredArrayUsingPredicate: predicate];
    if (filter.count > 0) {
        [listSearch addObjectsFromArray: filter];
    }
}

- (void)getSectionsForContactsList: (NSMutableArray *)contactList {
    if (eSortType == eSortName) {
        [contactSections removeAllObjects];
        
        // Loop through the books and create our keys
        for (PBXContact *contactItem in contactList){
            NSString *c = @"";
            if (contactItem._name.length > 1) {
                c = [[contactItem._name substringToIndex: 1] uppercaseString];
                c = [AppUtils convertUTF8StringToString: c];
            }
            
            if (![listCharacter containsObject:c]) {
                c = @"z#";
            }
            
            found = NO;
            for (NSString *str in [contactSections allKeys]){
                if ([str isEqualToString:c]){
                    found = YES;
                }
            }
            if (!found){
                [contactSections setObject:[[NSMutableArray alloc] init] forKey:c];
            }
        }
        
        // Loop again and sort the books into their respective keys
        for (PBXContact *contactItem in contactList){
            NSString *c = @"";
            if (contactItem._name.length > 1) {
                c = [[contactItem._name substringToIndex: 1] uppercaseString];
                c = [AppUtils convertUTF8StringToString: c];
            }
            if (![listCharacter containsObject:c]) {
                c = @"z#";
            }
            if (contactItem != nil) {
                [[contactSections objectForKey: c] addObject:contactItem];
            }
        }
        // Sort each section array
        for (NSString *key in [contactSections allKeys]){
            [[contactSections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"_name" ascending:sortAscending]]];
        }
        
    }else{
        [contactSections removeAllObjects];
        
        // Loop through the books and create our keys
        for (PBXContact *contactItem in contactList){
            NSString *c = @"";
            if (contactItem._number.length > 1) {
                c = [contactItem._number substringToIndex: 1];
            }
            
            found = NO;
            for (NSString *str in [contactSections allKeys]){
                if ([str isEqualToString:c]){
                    found = YES;
                }
            }
            if (!found){
                [contactSections setObject:[[NSMutableArray alloc] init] forKey:c];
            }
        }
        
        // Loop again and sort the books into their respective keys
        for (PBXContact *contactItem in contactList){
            NSString *c = @"";
            if (contactItem._number.length > 1) {
                c = [contactItem._number substringToIndex: 1];
            }
            if (contactItem != nil) {
                [[contactSections objectForKey: c] addObject:contactItem];
            }
        }
        // Sort each section array
        for (NSString *key in [contactSections allKeys]){
            [[contactSections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"_number" ascending:sortAscending]]];
        }
    }
}

- (void)onIconCallClicked: (UIButton *)sender
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] phone number = %@", __FUNCTION__, sender.currentTitle]
                         toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if (![AppUtils isNullOrEmpty: sender.currentTitle]) {
        NSString *phoneNumber = [AppUtils removeAllSpecialInString: sender.currentTitle];
        if (![AppUtils isNullOrEmpty: phoneNumber])
        {
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
    [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"The phone number can not empty"]
                duration:2.0 position:CSToastPositionCenter];
}

- (void)afterFinishGetPBXContactsList: (NSNotification *)notif
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    id object = [notif object];
    if ([object isKindOfClass:[NSNumber class]]) {
        if (pbxList == nil) {
            pbxList = [[NSMutableArray alloc] init];
        }
        [pbxList removeAllObjects];
        if ([LinphoneAppDelegate sharedInstance].pbxContacts != nil) {
            [pbxList addObjectsFromArray:[[LinphoneAppDelegate sharedInstance].pbxContacts copy]];
        }
        
        [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] pbxContacts count = %lu contacts", __FUNCTION__, (unsigned long)pbxList.count] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        
        if (pbxList.count > 0) {
            [_tbContacts reloadData];
        }
    }
}

- (NSAttributedString *)getSyncTitleContentWithFont: (UIFont *)textFont andSizeIcon: (float)size
{
    CustomTextAttachment *attachment = [[CustomTextAttachment alloc] init];
    attachment.image = [UIImage imageNamed:@"sync.png"];
    [attachment setImageHeight: size];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSString *content = [NSString stringWithFormat:@"  %@", [[LanguageUtil sharedInstance] getContent:@"Sync contacts"]];
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] initWithString:content];
    [contentString addAttribute:NSFontAttributeName value:textFont range:NSMakeRange(0, contentString.length)];
    [contentString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0] range:NSMakeRange(0, contentString.length)];
    
    NSMutableAttributedString *verString = [[NSMutableAttributedString alloc] initWithAttributedString: attachmentString];
    //
    [verString appendAttributedString: contentString];
    return verString;
}

- (void)hideWaitingView: (BOOL)hide {
    if (hide) {
        if (waitingView) {
            [waitingView stopAnimating];
            waitingView.hidden = YES;
            [waitingView removeFromSuperview];
            waitingView = nil;
        }
    }else{
        if (waitingView == nil) {
            waitingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
            waitingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            waitingView.backgroundColor = UIColor.whiteColor;
            waitingView.alpha = 0.5;
            [[LinphoneAppDelegate sharedInstance].window addSubview: waitingView];
        }
        //  [[LinphoneAppDelegate sharedInstance].window bringSubviewToFront: waitingView];
        [waitingView startAnimating];
        waitingView.hidden = NO;
    }
}

#pragma mark - Webservice delegate
- (void)failedToCallWebService:(NSString *)link andError:(NSString *)error
{
    pbxHeaderView.btnSync.enabled = YES;
    [self hideWaitingView: YES];
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Result for %@:\nResponse data: %@\n", __FUNCTION__, link, error] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
}

- (void)successfulToCallWebService:(NSString *)link withData:(NSDictionary *)data {
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s] Result for %@:\nResponse data: %@\n", __FUNCTION__, link, @[data]] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if ([link isEqualToString: get_contacts_func]){
        if (data != nil && [data isKindOfClass:[NSArray class]]) {
            [self whenStartSyncPBXContacts: (NSArray *)data];
        }else{
            [self hideWaitingView: YES];
            pbxHeaderView.btnSync.enabled = YES;
        }
    }
}

-(void)receivedResponeCode:(NSString *)link withCode:(int)responeCode {
    
}

//  Xử lý pbx contacts trả về
- (void)whenStartSyncPBXContacts: (NSArray *)data
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self savePBXContactInPhoneBook: data];
        [self getListPhoneWithCurrentContactPBX];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self syncContactsSuccessfully];
        });
    });
}

- (void)savePBXContactInPhoneBook: (NSArray *)pbxData
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__]
                         toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    NSString *pbxContactName = @"";
    
    ABAddressBookRef addressListBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    NSArray *arrayOfAllPeople = (__bridge  NSArray *) ABAddressBookCopyArrayOfAllPeople(addressListBook);
    NSUInteger peopleCounter = 0;
    
    BOOL exists = NO;
    
    for (peopleCounter = 0; peopleCounter < [arrayOfAllPeople count]; peopleCounter++)
    {
        ABRecordRef aPerson = (__bridge ABRecordRef)[arrayOfAllPeople objectAtIndex:peopleCounter];
        NSString *sipNumber = (__bridge NSString *)ABRecordCopyValue(aPerson, kABPersonFirstNamePhoneticProperty);
        if (sipNumber != nil && [sipNumber isEqualToString: keySyncPBX]) {
            pbxContactName = [AppUtils getNameOfContact: aPerson];
            exists = YES;
            
            ABRecordSetValue(aPerson, kABPersonPhoneProperty, nil, nil);
            BOOL isSaved = ABAddressBookSave (addressListBook, nil);
            if (isSaved) {
                NSLog(@"Update thanh cong");
            }
            // Phone number
            ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            for (int iCount=0; iCount<pbxData.count; iCount++) {
                NSDictionary *dict = [pbxData objectAtIndex: iCount];
                NSString *name = [dict objectForKey:@"name"];
                NSString *number = [dict objectForKey:@"num"];
                if (![AppUtils isNullOrEmpty: name] && ![AppUtils isNullOrEmpty: number]) {
                    ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(number), (__bridge  CFStringRef)name, NULL);
                }
            }
            
            ABRecordSetValue(aPerson, kABPersonPhoneProperty, multiPhone,nil);
            isSaved = ABAddressBookSave (addressListBook, nil);
            if (isSaved) {
                NSLog(@"Update thanh cong");
            }
        }
    }
    if (!exists) {
        [self addContactsWithData:pbxData withContactName:nameContactSyncPBX andCompany:nameSyncCompany];
    }
}

- (void)getListPhoneWithCurrentContactPBX {
    if ([LinphoneAppDelegate sharedInstance].pbxContacts == nil) {
        [LinphoneAppDelegate sharedInstance].pbxContacts = [[NSMutableArray alloc] init];
    }
    [[LinphoneAppDelegate sharedInstance].pbxContacts removeAllObjects];
    
    ABAddressBookRef addressListBook = ABAddressBookCreateWithOptions(NULL, NULL);
    NSArray *arrayOfAllPeople = (__bridge  NSArray *) ABAddressBookCopyArrayOfAllPeople(addressListBook);
    for (int peopleCounter = (int)arrayOfAllPeople.count-1; peopleCounter >= 0; peopleCounter--)
    {
        ABRecordRef aPerson = (__bridge ABRecordRef)[arrayOfAllPeople objectAtIndex:peopleCounter];
        
        ABRecordID idContact = ABRecordGetRecordID(aPerson);
        NSLog(@"-----id: %d", idContact);
        
        NSString *sipNumber = (__bridge NSString *)ABRecordCopyValue(aPerson, kABPersonFirstNamePhoneticProperty);
        if (sipNumber != nil && [sipNumber isEqualToString: keySyncPBX])
        {
            ABMultiValueRef phones = ABRecordCopyValue(aPerson, kABPersonPhoneProperty);
            if (ABMultiValueGetCount(phones) > 0)
            {
                for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
                {
                    CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
                    CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(phones, j);
                    
                    NSString *curPhoneValue = (__bridge NSString *)phoneNumberRef;
                    curPhoneValue = [[curPhoneValue componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                    
                    NSString *nameValue = (__bridge NSString *)locLabel;
                    
                    if (curPhoneValue != nil && nameValue != nil) {
                        PBXContact *aContact = [[PBXContact alloc] init];
                        aContact._name = nameValue;
                        aContact._number = curPhoneValue;
                        
                        [[LinphoneAppDelegate sharedInstance].pbxContacts addObject: aContact];
                    }
                }
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:idContact]
                                                          forKey:PBX_ID_CONTACT];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
}

//  Thêm mới contact
- (void)addContactsWithData: (NSArray *)pbxData withContactName: (NSString *)contactName andCompany: (NSString *)company
{
    NSString *strEmail = @"";
    
    NSString *strAvatar = @"";
    UIImage *logoImage = [UIImage imageNamed:@"logo"];
    NSData *avatarData = UIImagePNGRepresentation(logoImage);
    if (avatarData != nil) {
        if ([avatarData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
            strAvatar = [avatarData base64EncodedStringWithOptions: 0];
        } else {
            strAvatar = [avatarData base64Encoding];
        }
    }
    
    ABRecordRef aRecord = ABPersonCreate();
    CFErrorRef  anError = NULL;
    
    // Lưu thông tin
    ABRecordSetValue(aRecord, kABPersonFirstNameProperty, (__bridge CFTypeRef)(contactName), &anError);
    ABRecordSetValue(aRecord, kABPersonLastNameProperty, (__bridge CFTypeRef)(@""), &anError);
    ABRecordSetValue(aRecord, kABPersonOrganizationProperty, (__bridge CFTypeRef)(company), &anError);
    ABRecordSetValue(aRecord, kABPersonFirstNamePhoneticProperty, (__bridge CFTypeRef)(keySyncPBX), &anError);
    
    ABMutableMultiValueRef email = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(email, (__bridge CFTypeRef)(strEmail), CFSTR("email"), NULL);
    ABRecordSetValue(aRecord, kABPersonEmailProperty, email, &anError);
    
//    if (avatarData != nil) {
//        CFDataRef cfdata = CFDataCreate(NULL,[avatarData bytes], [avatarData length]);
//        ABPersonSetImageData(aRecord, cfdata, &anError);
//    }
    
    // Phone number
    //  NSMutableArray *listPhone = [[NSMutableArray alloc] init];
    ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    
    for (int iCount=0; iCount<pbxData.count; iCount++) {
        NSDictionary *dict = [pbxData objectAtIndex: iCount];
        NSString *name = [dict objectForKey:@"name"];
        NSString *number = [dict objectForKey:@"num"];
        
        ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(number), (__bridge  CFStringRef)name, NULL);
    }
    
    ABRecordSetValue(aRecord, kABPersonPhoneProperty, multiPhone,nil);
    CFRelease(multiPhone);
    
    // Instant Message
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"SIP", (NSString*)kABPersonInstantMessageServiceKey,
                                @"", (NSString*)kABPersonInstantMessageUsernameKey, nil];
    CFStringRef label = NULL; // in this case 'IM' will be set. But you could use something like = CFSTR("Personal IM");
    CFErrorRef errorf = NULL;
    ABMutableMultiValueRef values =  ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    BOOL didAdd = ABMultiValueAddValueAndLabel(values, (__bridge CFTypeRef)(dictionary), label, NULL);
    BOOL didSet = ABRecordSetValue(aRecord, kABPersonInstantMessageProperty, values, &errorf);
    if (!didAdd || !didSet) {
        CFStringRef errorDescription = CFErrorCopyDescription(errorf);
        NSLog(@"%s error %@ while inserting multi dictionary property %@ into ABRecordRef", __FUNCTION__, dictionary, errorDescription);
        CFRelease(errorDescription);
    }
    CFRelease(values);
    
    //Address
    ABMutableMultiValueRef address = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    NSMutableDictionary *addressDict = [[NSMutableDictionary alloc] init];
    [addressDict setObject:@"" forKey:(NSString *)kABPersonAddressStreetKey];
    [addressDict setObject:@"" forKey:(NSString *)kABPersonAddressZIPKey];
    [addressDict setObject:@"" forKey:(NSString *)kABPersonAddressStateKey];
    [addressDict setObject:@"" forKey:(NSString *)kABPersonAddressCityKey];
    [addressDict setObject:@"" forKey:(NSString *)kABPersonAddressCountryKey];
    ABMultiValueAddValueAndLabel(address, (__bridge CFTypeRef)(addressDict), kABWorkLabel, NULL);
    ABRecordSetValue(aRecord, kABPersonAddressProperty, address, &anError);
    
    if (anError != NULL) {
        NSLog(@"error while creating..");
    }
    
    ABAddressBookRef addressBook;
    CFErrorRef error = NULL;
    addressBook = ABAddressBookCreateWithOptions(nil, &error);
    
    BOOL isAdded = ABAddressBookAddRecord (addressBook,aRecord,&error);
    
    if(isAdded){
        NSLog(@"added..");
    }
    if (error != NULL) {
        NSLog(@"ABAddressBookAddRecord %@", error);
    }
    error = NULL;
    
    BOOL isSaved = ABAddressBookSave (addressBook,&error);
    if(isSaved){
        NSLog(@"saved..");
    }
    
    if (error != NULL) {
        NSLog(@"ABAddressBookSave %@", error);
    }
}

//  Thông báo kết thúc sync contacts
- (void)syncContactsSuccessfully
{
    [WriteLogsUtils writeLogContent:[NSString stringWithFormat:@"[%s]", __FUNCTION__] toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    [pbxList removeAllObjects];
    if ([LinphoneAppDelegate sharedInstance].pbxContacts != nil) {
        [pbxList addObjectsFromArray:[[LinphoneAppDelegate sharedInstance].pbxContacts copy]];
    }
    pbxHeaderView.lbTitle.text = [NSString stringWithFormat:@"Tất cả liên hện (%d)", (int)pbxList.count];
    pbxHeaderView.btnSync.enabled = YES;
    [self hideWaitingView: YES];
    [_tbContacts reloadData];
    
    [[LinphoneAppDelegate sharedInstance].window makeToast:[[LanguageUtil sharedInstance] getContent:@"Successful"] duration:2.0 position:CSToastPositionCenter];
}

- (void)setupSortInformation {
    NSString *sortType = [[NSUserDefaults standardUserDefaults] objectForKey:key_sort_type];
    if ([AppUtils isNullOrEmpty: sortType]) {
        [AppUtils setupFirstValueForSortPBXContactList];
    }
    
    if ([sortType isEqualToString: sort_with_phone]) {
        eSortType = eSortPhone;
    }else{
        eSortType = eSortName;
    }
    
    NSString *ascending = [[NSUserDefaults standardUserDefaults] objectForKey:sort_ascending];
    if ([ascending isEqualToString:@"YES"]) {
        sortAscending = TRUE;
    }else{
        sortAscending = FALSE;
    }
    
    [pbxHeaderView updateSortViewInfo];
}


@end
