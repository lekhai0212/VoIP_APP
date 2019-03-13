//
//  ChooseDIDPopupView.h
//  linphone
//
//  Created by lam quang quan on 3/13/19.
//

#import <UIKit/UIKit.h>

@protocol ChooseDIDPopupViewDelegate
- (void)selectContactFromSearchPopup: (NSString *)phoneNumber;
@end

@interface ChooseDIDPopupView : UIView<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic,strong) id <NSObject, ChooseDIDPopupViewDelegate> delegate;
@property (nonatomic, strong) UILabel *lbHeader;
@property (nonatomic, strong) UITableView *tbDIDList;
@property (nonatomic, retain) UITapGestureRecognizer *tapGesture;

- (void)showInView:(UIView *)aView animated:(BOOL)animated;
- (void)fadeOut;

@end
