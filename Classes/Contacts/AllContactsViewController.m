//
//  AllContactsViewController.m
//  linphone
//
//  Created by Ei Captain on 6/30/16.
//
//

#import "AllContactsViewController.h"
#import "ContactsViewController.h"
#import "KContactDetailViewController.h"
#import "UIImage+GKContact.h"
#import "NSData+Base64.h"
#import "ContactCell.h"
#import "ContactObject.h"
#import "ContactDetailObj.h"

@interface AllContactsViewController (){
    BOOL isSearching;
    BOOL isFound;
    BOOL found;
    float hSection;
    
    NSArray *listCharacter;
    NSTimer *refreshTimer;
    
    NSMutableArray *tbDatas;
    UILabel *lbAllContacts;
    float marginLeft;
}

@end

@implementation AllContactsViewController
@synthesize _tbContacts, _lbNoContacts;
@synthesize _searchResults, _contactSections;

- (void)viewDidLoad {
    [super viewDidLoad];
    //  MY CODE HERE
    listCharacter = [[NSArray alloc] initWithObjects: @"A", @"B", @"C", @"D", @"E", @"F",
                  @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    
    _contactSections = [[NSMutableDictionary alloc] init];
    
    [self autoLayoutForView];
    [self addHeaderForTableContactsView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [WriteLogsUtils writeForGoToScreen: @"AllContactsViewController"];
    
    if (tbDatas == nil) {
        tbDatas = [[NSMutableArray alloc] init];
    }
    [tbDatas removeAllObjects]; 
    
    if (![LinphoneAppDelegate sharedInstance].contactLoaded)
    {
        [WriteLogsUtils writeLogContent:@"Contact have not loaded yet" toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
        _lbNoContacts.hidden = YES;
        
        if (refreshTimer) {
            [refreshTimer invalidate];
            refreshTimer = nil;
        }
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(showAndReloadContactList) userInfo:nil repeats:YES];
    }else{
        [self showAndReloadContactList];
        lbAllContacts.text = SFM(@"%@ (%d)", count_all_contacts, (int)tbDatas.count);
    }
    
    if ([LinphoneAppDelegate sharedInstance].needToReloadContactList) {
        [_tbContacts reloadData];
        [LinphoneAppDelegate sharedInstance].needToReloadContactList = NO;
    }
    
    //  notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whenLoadContactFinish)
                                                 name:finishLoadContacts object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSearchContactWithValue:)
                                                 name:searchContactWithValue object:nil];
    //  ---------
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    if (refreshTimer) {
        [refreshTimer invalidate];
        refreshTimer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - My Functions

- (void)addHeaderForTableContactsView {
    UIView *headerView = [[UIView alloc] init];
    headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 40.0);
    headerView.backgroundColor = UIColor.whiteColor;
    
    lbAllContacts = [[UILabel alloc] initWithFrame:CGRectMake(marginLeft, 0, SCREEN_WIDTH-2*marginLeft, headerView.frame.size.height)];
    lbAllContacts.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    lbAllContacts.textColor = [UIColor colorWithRed:(60/255.0) green:(75/255.0) blue:(102/255.0) alpha:1.0];
    [headerView addSubview: lbAllContacts];
    
    _tbContacts.tableHeaderView = headerView;
}

- (void)whenLoadContactFinish
{
    [WriteLogsUtils writeLogContent:SFM(@"[%s]", __FUNCTION__) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    //  clear timer
    if (refreshTimer) {
        [refreshTimer invalidate];
        refreshTimer = nil;
    }
    [self showAndReloadContactList];
}

- (void)autoLayoutForView {
    hSection = 30.0;
    marginLeft = 15.0;
    
    [_tbContacts mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    }];
    _tbContacts.delegate = self;
    _tbContacts.dataSource = self;
    _tbContacts.separatorStyle = UITableViewCellSeparatorStyleNone;

    //  khong co lien he
    _lbNoContacts.font = [LinphoneAppDelegate sharedInstance].contentFontNormal;
    _lbNoContacts.textColor = UIColor.grayColor;
    _lbNoContacts.text = text_no_contacts;
}

- (void)getSectionsForContactsList: (NSMutableArray *)contactList {
    [_contactSections removeAllObjects];
    
    // Loop through the books and create our keys
    for (ContactObject *contactItem in contactList){
        NSString *c = @"";
        if (contactItem._fullName.length > 1) {
            c = [[contactItem._fullName substringToIndex: 1] uppercaseString];
            c = [AppUtils convertUTF8StringToString: c];
        }
        
        if (![listCharacter containsObject:c]) {
            c = @"z#";
        }
        
        found = NO;
        for (NSString *str in [_contactSections allKeys]){
            if ([str isEqualToString:c]){
                found = YES;
            }
        }
        if (!found){
            [_contactSections setObject:[[NSMutableArray alloc] init] forKey:c];
        }
    }
    
    // Loop again and sort the books into their respective keys
    for (ContactObject *contactItem in contactList){
        NSString *c = @"";
        if (contactItem._fullName.length > 1) {
            c = [[contactItem._fullName substringToIndex: 1] uppercaseString];
            c = [AppUtils convertUTF8StringToString: c];
        }
        if (![listCharacter containsObject:c]) {
            c = @"z#";
        }
        
        [[_contactSections objectForKey: c] addObject:contactItem];
    }
    // Sort each section array
    for (NSString *key in [_contactSections allKeys]){
        [[_contactSections objectForKey:key] sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"_fullName" ascending:YES]]];
    }
}

- (NSString *)subTowString: (NSString *)str1 andString: (NSString *)str2{
    if ([str1 isEqualToString: @""] && [str2 isEqualToString: @""]) {
        return text_unknown;
    }else if ([str1 isEqualToString: @""] && ![str2 isEqualToString: @""]){
        return str2;
    }else if (![str1 isEqualToString: @""] && [str2 isEqualToString: @""]){
        return str1;
    }else{
        return SFM(@"%@ %@", str1, str2);
    }
}

#pragma mark - TableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (isSearching) {
        [self getSectionsForContactsList: _searchResults];
    }else{
        [self getSectionsForContactsList: tbDatas];
    }
    return [[_contactSections allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *str = [[[_contactSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
    return [[_contactSections objectForKey:str] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactObject *contact = [[ContactObject alloc] init];
    NSString *key = [[[_contactSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section];
    contact = [[_contactSections objectForKey: key] objectAtIndex:indexPath.row];
    
    static NSString *identifier = @"ContactCell";
    ContactCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ContactCell" owner:self options:nil];
        cell = topLevelObjects[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Tên contact
    if (contact._fullName != nil) {
        if ([AppUtils isNullOrEmpty: contact._fullName]) {
            cell.name.text = text_unknown;
        }else{
            cell.name.text = contact._fullName;
        }
    }
    
    if (![AppUtils isNullOrEmpty: contact._avatar]){
        NSData *imageData = [NSData dataFromBase64String:contact._avatar];
        cell.image.image = [UIImage imageWithData: imageData];
    }else {
        NSString *keyAvatar = @"";
        if (contact._lastName != nil && ![contact._lastName isEqualToString:@""]) {
            keyAvatar = [contact._lastName substringToIndex: 1];
        }
        
        if (contact._firstName != nil && ![contact._firstName isEqualToString:@""]) {
            if (![keyAvatar isEqualToString:@""]) {
                keyAvatar = SFM(@"%@ %@", keyAvatar, [contact._firstName substringToIndex: 1]);
            }else{
                keyAvatar = [contact._firstName substringToIndex: 1];
            }
        }
        
        UIImage *avatar = [UIImage imageForName:[keyAvatar uppercaseString] size:CGSizeMake(60.0, 60.0)
                                backgroundColor:[UIColor colorWithRed:(154/255.0) green:(215/255.0) blue:(9/255.0) alpha:1.0]
                                      textColor:UIColor.whiteColor
                                           font:nil];
        cell.image.image = avatar;
    }
    
    cell.tag = contact._id_contact;
    cell.phone.text = contact._sipPhone;
    if (![contact._sipPhone isEqualToString:@""] && contact._sipPhone != nil) {
        cell.icCall.hidden = NO;
        [cell.icCall setTitle:contact._sipPhone forState:UIControlStateNormal];
        [cell.icCall addTarget:self
                        action:@selector(onIconCallClicked:)
              forControlEvents:UIControlEventTouchUpInside];
    }else{
        cell.icCall.hidden = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactCell *curCell = (ContactCell *)[tableView cellForRowAtIndexPath: indexPath];
    [LinphoneAppDelegate sharedInstance].idContact = (int)[curCell tag];
    
    [[PhoneMainView instance] changeCurrentView:[KContactDetailViewController compositeViewDescription] push: true];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *titleHeader = [[[_contactSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, hSection)];
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
//    NSMutableArray *tmpArr = [[NSMutableArray alloc] initWithArray: [[_contactSections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
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
    return 65.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return hSection;
}

#pragma mark -

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboard" object:nil];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeKeyboard" object:nil];
}

//  Added by Khai Le on 04/10/2018
- (void)startSearchContactWithValue: (NSNotification *)notif {
    id object = [notif object];
    if ([object isKindOfClass:[NSString class]])
    {
        if ([object isEqualToString:@""]) {
            isSearching = FALSE;
            lbAllContacts.text = SFM(@"%@ (%d)", count_all_contacts, (int)tbDatas.count);
            [_tbContacts reloadData];
        }else{
            isSearching = TRUE;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self searchPhoneBook: object];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    lbAllContacts.text = SFM(@"%@ (%d)", count_all_contacts, (int)_searchResults.count);
                    [_tbContacts reloadData];
                });
            });
        }
    }
}

- (void)searchPhoneBook: (NSString *)strSearch
{
    if (_searchResults == nil) {
        _searchResults = [[NSMutableArray alloc] init];
    }
    
    NSMutableArray *tmpList = [[NSMutableArray alloc] initWithArray: tbDatas];
    
    //  search theo ten va sipPhone
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"_fullName contains[cd] %@ OR _sipPhone contains[cd] %@", strSearch, strSearch];
    [_searchResults removeAllObjects];
    NSArray *filter = [tmpList filteredArrayUsingPredicate: predicate];
    if (filter.count > 0) {
        [_searchResults addObjectsFromArray: filter];
        [tmpList removeObjectsInArray: filter];
    }
    
    predicate = [NSPredicate predicateWithFormat:@"_valueStr contains[cd] %@", strSearch];
    for (int iCount=0; iCount<tmpList.count; iCount++) {
        ContactObject *contact = [tmpList objectAtIndex: iCount];
        NSArray *filter = [contact._listPhone filteredArrayUsingPredicate: predicate];
        if (filter.count > 0) {
            [_searchResults addObject: contact];
        }
    }
}

- (void)onIconCallClicked: (UIButton *)sender
{
    [WriteLogsUtils writeLogContent:SFM(@"[%s] phone number = %@", __FUNCTION__, sender.currentTitle) toFilePath:[LinphoneAppDelegate sharedInstance].logFilePath];
    
    if (![AppUtils isNullOrEmpty: sender.currentTitle]) {
        NSString *phoneNumber = [AppUtils removeAllSpecialInString: sender.currentTitle];
        if (![phoneNumber isEqualToString:@""]) {
            [SipUtils makeCallWithPhoneNumber: phoneNumber];
        }
    }
}

- (void)showAndReloadContactList {
    [tbDatas removeAllObjects];
    [tbDatas addObjectsFromArray:[[LinphoneAppDelegate sharedInstance].listContacts copy]];
    
    if (tbDatas.count > 0) {
        _tbContacts.hidden = NO;
        _lbNoContacts.hidden = YES;
        [_tbContacts reloadData];
    }else{
        _tbContacts.hidden = YES;
        _lbNoContacts.hidden = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
    CGPoint scrollViewOffset = scrollView.contentOffset;
    if (scrollViewOffset.y < 0) {
        [scrollView setContentOffset:CGPointMake(0, 0)];
    }
}

@end
