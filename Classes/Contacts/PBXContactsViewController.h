//
//  PBXContactsViewController.h
//  linphone
//
//  Created by Apple on 5/11/17.
//
//

#import <UIKit/UIKit.h>
#import "WebServices.h"

@interface PBXContactsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, WebServicesDelegate>

@property (weak, nonatomic) IBOutlet UITableView *_tbContacts;

@end
