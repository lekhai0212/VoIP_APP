//
//  ChooseDIDPopupView.m
//  linphone
//
//  Created by lam quang quan on 3/13/19.
//

#import "ChooseDIDPopupView.h"
#import "ChooseDIDCell.h"

@implementation ChooseDIDPopupView
@synthesize tbDIDList, lbHeader, tapGesture, delegate, listDID;

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame: frame];
    if (self) {
        // Initialization code
        self.backgroundColor =  UIColor.whiteColor;
        listDID = [[NSMutableArray alloc] init];
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 12.0;
        
        lbHeader = [[UILabel alloc] init];
        lbHeader.textAlignment = NSTextAlignmentCenter;
        lbHeader.text = [[LanguageUtil sharedInstance] getContent:@"Choose DID"];
        lbHeader.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold];
        lbHeader.textColor = [UIColor colorWithRed:(80/255.0) green:(208/255.0) blue:(135/255.0) alpha:1.0];
        [self addSubview: lbHeader];
        [lbHeader mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self);
            make.height.mas_equalTo(60.0);
        }];
        
        tbDIDList = [[UITableView alloc] init];
        tbDIDList.delegate = self;
        tbDIDList.dataSource = self;
        tbDIDList.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self addSubview: tbDIDList];
        
        [tbDIDList mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lbHeader.mas_bottom);
            make.left.bottom.right.equalTo(self);
        }];
    }
    return self;
}


- (void)showInView:(UIView *)aView animated:(BOOL)animated {
    //Add transparent
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePopupViewWhenTagOut)];
    UIView *viewBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    viewBackground.backgroundColor = UIColor.blackColor;
    viewBackground.alpha = 0.5;
    viewBackground.tag = 20;
    [aView addSubview:viewBackground];
    
    [viewBackground addGestureRecognizer:tapGesture];
    
    [aView addSubview:self];
    if (animated) {
        [self fadeIn];
    }
}

- (void)fadeIn {
    self.transform = CGAffineTransformMakeScale(1.3, 1.3);
    self.alpha = 0;
    [UIView animateWithDuration:.35 animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

- (void)fadeOut {
    for (UIView *subView in self.window.subviews)
    {
        if (subView.tag == 20)
        {
            [subView removeFromSuperview];
        }
    }
    
    [UIView animateWithDuration:.35 animations:^{
        self.transform = CGAffineTransformMakeScale(1.3, 1.3);
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [self removeFromSuperview];
        }
    }];
}

- (void)closePopupViewWhenTagOut{
    [LinphoneAppDelegate sharedInstance].phoneForCall = @"";
    
    [self fadeOut];
    [self.superview removeGestureRecognizer:tapGesture];
}

#pragma mark - UITableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return listDID.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"ChooseDIDCell";
    ChooseDIDCell *cell = [tableView dequeueReusableCellWithIdentifier: identifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"ChooseDIDCell" owner:self options:nil];
        cell = topLevelObjects[0];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.row == 0) {
        cell.lbDIDNumber.text = [[LanguageUtil sharedInstance] getContent:@"Default DID"];
    }else{
        NSDictionary *info = [listDID objectAtIndex: indexPath.row-1];
        NSString *did = [info objectForKey:@"did"];
        cell.lbDIDNumber.text = did;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self fadeOut];
    if (indexPath.row == 0) {
        [delegate selectDIDForCallWithPrefix:@""];
    }else{
        NSDictionary *info = [listDID objectAtIndex: indexPath.row-1];
        NSString *prefix = [info objectForKey:@"st"];
        [delegate selectDIDForCallWithPrefix: prefix];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
