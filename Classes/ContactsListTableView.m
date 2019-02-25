/* ContactsTableViewController.m
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
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ContactsListTableView.h"
#import "UIContactCell.h"
#import "LinphoneManager.h"
#import "Utils.h"

@implementation ContactsListTableView

#pragma mark - Lifecycle Functions

- (void)initContactsTableViewController {
	addressBookMap = [[OrderedDictionary alloc] init];
	[NSNotificationCenter.defaultCenter addObserver:self
										   selector:@selector(onAddressBookUpdate:)
											   name:kLinphoneAddressBookUpdate
											 object:nil];
}

- (void)onAddressBookUpdate:(NSNotification *)k {
	if (!_ongoing && (PhoneMainView.instance.currentView == ContactsListView.compositeViewDescription)) {
		[self loadData];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (IPAD) {
		if (![self selectFirstRow]) {
			ContactDetailsView *view = VIEW(ContactDetailsView);
			[view setContact:nil];
		}
	}
}

- (id)init {
	self = [super init];
	if (self) {
		[self initContactsTableViewController];
	}
	_ongoing = FALSE;
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initContactsTableViewController];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeAllContacts];
}

- (void)removeAllContacts {
	for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j) {
		for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i) {
			[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]] setContact:nil];
		}
	}
}

#pragma mark -

static int ms_strcmpfuz(const char *fuzzy_word, const char *sentence) {
	if (!fuzzy_word || !sentence) {
		return fuzzy_word == sentence;
	}
	const char *c = fuzzy_word;
	const char *within_sentence = sentence;
	for (; c != NULL && *c != '\0' && within_sentence != NULL; ++c) {
		within_sentence = strchr(within_sentence, *c);
		// Could not find c character in sentence. Abort.
		if (within_sentence == NULL) {
			break;
		}
		// since strchr returns the index of the matched char, move forward
		within_sentence++;
	}

	// If the whole fuzzy was found, returns 0. Otherwise returns number of characters left.
	return (int)(within_sentence != NULL ? 0 : fuzzy_word + strlen(fuzzy_word) - c);
}

- (NSString *)displayNameForContact:(Contact *)person {
	NSString *name = @"";
	if (name != nil && [name length] > 0 && ![name isEqualToString:NSLocalizedString(@"Unknown", nil)]) {
		// Add the contact only if it fuzzy match filter too (if any)
		if ([ContactSelection getNameOrEmailFilter] == nil ||
			(ms_strcmpfuz([[[ContactSelection getNameOrEmailFilter] lowercaseString] UTF8String],
						  [[name lowercaseString] UTF8String]) == 0)) {

			// Sort contacts by first letter. We need to translate the name to ASCII first, because of UTF-8
			// issues. For instance expected order would be:  Alberta(A tilde) before ASylvano.
			NSData *name2ASCIIdata = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			NSString *name2ASCII = [[NSString alloc] initWithData:name2ASCIIdata encoding:NSASCIIStringEncoding];
			return name2ASCII;
		}
	}
	return nil;
}

- (void)loadData {
	_ongoing = TRUE;
	LOGI(@"Load contact list");
	@synchronized(addressBookMap) {
		//Set all contacts from ContactCell to nil
		for (NSInteger j = 0; j < [self.tableView numberOfSections]; ++j)
		{
			for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:j]; ++i)
			{
				[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]] setContact:nil];
			}
		}
		
		// Reset Address book
		[addressBookMap removeAllObjects];

		
		[super loadData];

		// since we refresh the tableview, we must perform this on main thread
		dispatch_async(dispatch_get_main_queue(), ^(void) {
		  if (IPAD) {
			  if (!([self totalNumberOfItems] > 0)) {
				  ContactDetailsView *view = VIEW(ContactDetailsView);
				  [view setContact:nil];
			  }
		  }
		});
	}
	_ongoing = FALSE;
}

- (void)loadSearchedData {
	LOGI(@"Load contact list");
}


#pragma mark - UITableViewDataSource Functions

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return [addressBookMap allKeys];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [addressBookMap count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(OrderedDictionary *)[addressBookMap objectForKey:[addressBookMap keyAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *kCellId = NSStringFromClass(UIContactCell.class);
	UIContactCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIContactCell alloc] initWithIdentifier:kCellId];
	}
	NSMutableArray *subAr = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
	Contact *contact = subAr[indexPath.row];

	// Cached avatar
	UIImage *image = [UIImage imageNamed:@"no_avatar"];
	[cell.avatarImage setImage:image bordered:NO withRoundedRadius:YES];
	[cell setContact:contact];
	[super accessoryForCell:cell atPath:indexPath];

	return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect frame = CGRectMake(0, 0, tableView.frame.size.width, tableView.sectionHeaderHeight);
	UIView *tempView = [[UIView alloc] initWithFrame:frame];
	tempView.backgroundColor = [UIColor whiteColor];

	UILabel *tempLabel = [[UILabel alloc] initWithFrame:frame];
	tempLabel.backgroundColor = [UIColor clearColor];
	tempLabel.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"color_A.png"]];
	tempLabel.text = [addressBookMap keyAtIndex:section];
	tempLabel.textAlignment = NSTextAlignmentCenter;
	tempLabel.font = [UIFont boldSystemFontOfSize:17];
	tempLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[tempView addSubview:tempLabel];

	return tempView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	if (![self isEditing]) {
		NSMutableArray *subAr = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
		Contact *contact = subAr[indexPath.row];

		// Go to Contact details view
		ContactDetailsView *view = VIEW(ContactDetailsView);
		[PhoneMainView.instance changeCurrentView:view.compositeViewDescription];
		if (([ContactSelection getSelectionMode] != ContactSelectionModeEdit) || !([ContactSelection getAddAddress])) {
			[view setContact:contact];
		} else {
			[view editContact:contact address:[ContactSelection getAddAddress]];
		}
	}
}

- (void)tableView:(UITableView *)tableView
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
	 forRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)removeSelectionUsing:(void (^)(NSIndexPath *))remover {
	
}

@end
