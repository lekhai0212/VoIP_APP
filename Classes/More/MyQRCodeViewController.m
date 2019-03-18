//
//  MyQRCodeViewController.m
//  linphone
//
//  Created by lam quang quan on 3/18/19.
//

#import "MyQRCodeViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import <Photos/Photos.h>

@interface MyQRCodeViewController (){
    UIImage *qrCodeValue;
}

@end

@implementation NSString (MD5)
- (NSString *)MD5String {
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (int)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
@end

@implementation MyQRCodeViewController
@synthesize viewHeader, imgHeader, lbTitle, iconBack, imgMyQRCode, icSave;

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:self.class
                                                              statusBar:StatusBarView.class
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
    // Do any additional setup after loading the view from its nib.
    [self autoLayoutForView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    lbTitle.text = [[LanguageUtil sharedInstance] getContent:@"Create QRCode"];
    icSave.enabled = NO;
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:key_login];
    if (username != nil && username.length > 5) {
        NSString *codeAgent = [username substringToIndex: 5];
        NSString *userpass = [NSString stringWithFormat:@"%@%@", USERNAME, PASSWORD];
        
        NSString *hashStr = [NSString stringWithFormat:@"%@%@", codeAgent, [[userpass MD5String] lowercaseString]];
        
        qrCodeValue = [self createQRForString: hashStr];
        if (qrCodeValue != nil) {
            imgMyQRCode.image = qrCodeValue;
            icSave.enabled = YES;
        }else{
            imgMyQRCode.image = [UIImage imageNamed:@"not_qrcode"];
        }
    }else{
        imgMyQRCode.image = [UIImage imageNamed:@"not_qrcode"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)iconBackClick:(UIButton *)sender {
    [[PhoneMainView instance] popCurrentView];
}

- (IBAction)icSaveClick:(UIButton *)sender {
}

- (void)autoLayoutForView {
    float hHeader = [LinphoneAppDelegate sharedInstance]._hRegistrationState;
    [viewHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(hHeader);
    }];
    
    [imgHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(viewHeader);
    }];
    
    iconBack.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [iconBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.left.equalTo(viewHeader);
        make.width.height.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    icSave.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [icSave mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(iconBack);
        make.right.equalTo(viewHeader);
        make.width.mas_equalTo(HEADER_ICON_WIDTH);
    }];
    
    lbTitle.font = [UIFont fontWithName:MYRIADPRO_REGULAR size:18.0];
    [lbTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewHeader).offset([LinphoneAppDelegate sharedInstance]._hStatus);
        make.bottom.equalTo(viewHeader);
        make.centerX.equalTo(viewHeader.mas_centerX);
        make.width.mas_equalTo(250);
    }];
    
    [imgMyQRCode mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.centerY.equalTo(self.view.mas_centerY);
        make.width.height.mas_equalTo(260.0);
    }];
}

- (IBAction)icSaveClicked:(UIButton *)sender {
    UIImageWriteToSavedPhotosAlbum(qrCodeValue, nil, nil, nil);
    [self.view makeToast:[[LanguageUtil sharedInstance] getContent:@"Your qrcode has been saved successful"] duration:2.0 position:CSToastPositionCenter];
    
}

- (UIImage *)createQRForString:(NSString *)qrString {
    NSData *data = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    [filter setValue:data forKey:@"inputMessage"];
    
    CIImage *outputImage = [filter outputImage];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:outputImage
                                       fromRect:[outputImage extent]];
    
    UIImage *image = [UIImage imageWithCGImage:cgImage
                                         scale:0.1
                                   orientation:UIImageOrientationUp];
    
    UIImage *resized = [self resizeImage:image withQuality:kCGInterpolationNone rate:5.0];
    
    UIImage *result = [self scaleWithFixedWidth:600 image:resized];
    
    CGImageRelease(cgImage);
    return result;
}

- (UIImage *)resizeImage:(UIImage *)image withQuality:(CGInterpolationQuality)quality rate:(CGFloat)rate
{
    UIImage *resized = nil;
    CGFloat width = image.size.width * rate;
    CGFloat height = image.size.height * rate;
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized;
}

- (UIImage *)scaleWithFixedWidth:(CGFloat)width image:(UIImage *)image
{
    float newHeight = image.size.height * (width / image.size.width);
    CGSize size = CGSizeMake(width, newHeight);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), image.CGImage);
    
    UIImage *imageOut = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return imageOut;
}

@end
