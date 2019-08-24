//
//  AppStrings.h
//  linphone
//
//  Created by admin on 11/5/17.
//
//
//  linphone_proxy_config_enable_publish

#ifndef AppStrings_h
#define AppStrings_h

#define SFM(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

#define idSyncPBX           @"keySyncPBX"

#define SILENCE_RINGTONE    @"silence.mp3"
#define DEFAULT_RINGTONE    @"DEFAULT_RINGTONE"
#define IS_VIDEO_CALL_KEY   @"IS_VIDEO_CALL_KEY"
#define TAG_AUDIO_CALL  1
#define TAG_VIDEO_CALL  2

#define AUDIO_CALL_TYPE 1
#define VIDEO_CALL_TYPE 2

#define MAX_TIME_FOR_LOGIN  3


#define getDIDListForCall                   @"getDIDListForCall"
#define speakerEnabledForVideoCall          @"speakerEnabledForVideoCall"
#define showOrHideDeleteCallHistoryButton   @"showOrHideDeleteCallHistoryButton"


#pragma mark - API

#define link_api                @"https://api.vfone.vn:51100"
#define login_func              @"logininfo"
#define update_token_func       @"updatepushtoken"
#define get_contacts_func       @"getservercontacts"
#define get_didlist_func        @"getdidlist"
#define get_missedcall_func     @"getinfomisscall"
#define decryptRSA_func         @"decryptrsa"
#define get_list_record_file    @"getlistrecordfile"
#define get_file_record         @"getfilerecord"





#define errorLoginCode  @"002"


#define link_appstore   @""
#define link_introduce  @"https://vfone.vn/about.html"
#define link_policy     @"https://vfone.vn/privacy.html"
#define youtube_channel @""
#define facebook_link   @""

#define SHOW_LOGS @"[Show logs]"
#define HEADER_ICON_WIDTH 35.0
#define PADDING_DRAW_CONTROL_VIEW   5.0
#define IPAD_HEIGHT_TF   38.0

#define STATUS_BAR_HEIGHT   ([UIApplication sharedApplication].statusBarFrame.size.height)
#define PADDING_HEADER_ICON 10.0
#define HEIGHT_IPAD_NAV 80.0
#define HEIGHT_IPAD_HEADER_BUTTON 38.0
#define HEIGHT_HEADER_BTN 32.0
#define IPAD_HEADER_FONT_SIZE   24
#define SPLIT_MASTER_WIDTH  320

//  #define IPAD_BG_COLOR ([UIColor colorWithRed:(240/255.0) green:(240/255.0) blue:(240/255.0) alpha:1.0])
#define IPAD_BG_COLOR ([UIColor colorWithRed:(255/255.0) green:(255/255.0) blue:(255/255.0) alpha:1.0])
#define IPAD_HEADER_BG_COLOR ([UIColor colorWithRed:(29/255.0) green:(106/255.0) blue:(207/255.0) alpha:1.0])
#define IPAD_SELECT_TAB_BG_COLOR [UIColor colorWithRed:(15/255.0) green:(73/255.0) blue:(165/255.0) alpha:1.0]
#define SELECT_TAB_BG_COLOR [UIColor colorWithRed:(42/255.0) green:(172/255.0) blue:(255/255.0) alpha:1.0]
#define GRAY_COLOR ([UIColor colorWithRed:(150/255.0) green:(150/255.0) blue:(150/255.0) alpha:1.0])

#define reloadHistoryCallForIpad            @"reloadHistoryCallForIpad"
#define reloadContactsListForIpad           @"reloadContactsListForIpad"
#define reloadContactAfterAdd               @"reloadContactAfterAdd"
#define reloadContactsAfterDeleteForIpad    @"reloadContactsAfterDeleteForIpad"
#define reloadProfileContentForIpad         @"reloadProfileContentForIpad"

#define cloudfoneBundleID   @"com.ods.cloudfoneapp"
#define AES_KEY         @"OdsCloudfone@123"

#define simulator       @"x86_64"
#define Iphone4s        @"iPhone4,1"
#define Iphone5_1       @"iPhone5,1"
#define Iphone5_2       @"iPhone5,2"
#define Iphone5c_1      @"iPhone5,3"
#define Iphone5c_2      @"iPhone5,4"
#define Iphone5s_1      @"iPhone6,1"
#define Iphone5s_2      @"iPhone6,2"
#define Iphone6         @"iPhone7,2"
#define Iphone6_Plus    @"iPhone7,1"
#define Iphone6s        @"iPhone8,1"
#define Iphone6s_Plus   @"iPhone8,2"
#define IphoneSE        @"iPhone8,4"
#define Iphone7_1       @"iPhone9,1"
#define Iphone7_2       @"iPhone9,3"
#define Iphone7_Plus1   @"iPhone9,2"
#define Iphone7_Plus2   @"iPhone9,4"
#define Iphone8_1       @"iPhone10,1"
#define Iphone8_2       @"iPhone10,4"
#define Iphone8_Plus1   @"iPhone10,2"
#define Iphone8_Plus2   @"iPhone10,5"
#define IphoneX_1       @"iPhone10,3"
#define IphoneX_2       @"iPhone10,6"
#define IphoneXR        @"iPhone11,8"
#define IphoneXS        @"iPhone11,2"
#define IphoneXS_Max1   @"iPhone11,6"
#define IphoneXS_Max2   @"iPhone11,4"

//  [Khai le - 25/10/2018]
#define logsFolderName      @"LogFiles"
#define recordsFolderName   @"RecordsFiles"
#define DAY_FOR_LOGS    7
#define PBX_ID_CONTACT  @"PBX_ID_CONTACT"
#define VOICE_CONTROL   @"VOICE_CONTROL"

#define USERNAME ([[NSUserDefaults standardUserDefaults] objectForKey:key_login])
#define PASSWORD ([[NSUserDefaults standardUserDefaults] objectForKey:key_password])
#define SIP_DOMAIN ([[NSUserDefaults standardUserDefaults] objectForKey:key_ip])
#define PORT ([[NSUserDefaults standardUserDefaults] objectForKey:key_port])

//detect iphone5 and ipod5
#define IS_IPHONE ( [ [ [ UIDevice currentDevice ] model ] isEqualToString: @"iPhone" ] )
#define IS_IPOD   ( [ [ [ UIDevice currentDevice ] model ] isEqualToString: @"iPod touch" ] )

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define IS_NORMALSCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )480 ) < DBL_EPSILON )
#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define IS_IPHONE_5 ( IS_IPHONE && IS_WIDESCREEN )
#define IS_IPHONE_4 (IS_IPHONE && IS_NORMALSCREEN)

#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define IS_IOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)

#define IS_IOS6 ([[[UIDevice currentDevice] systemVersion] floatValue] < 7 && [[[UIDevice currentDevice] systemVersion] floatValue] >= 6)

#define IS_IOS8 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8)

#define IS_IOS10 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

#define IS_IOS11 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#pragma mark - Fonts

#define link_picture_chat_group @"http://anh.ods.vn/uploads"

#define MYRIADPRO_REGULAR       @"MYRIADPRO-REGULAR"
#define MYRIADPRO_BOLD          @"MYRIADPRO-BOLD"
#define HelveticaNeue           @"HelveticaNeue"
#define HelveticaNeueBold       @"HelveticaNeue-Bold"
#define HelveticaNeueConBold    @"HelveticaNeue-CondensedBold"
#define HelveticaNeueItalic     @"HelveticaNeue-Italic"
#define HelveticaNeueLight      @"HelveticaNeue-Light"
#define HelveticaNeueThin       @"HelveticaNeue-Thin"

#define idContactUnknown    -9999
#define idSyncPBX           @"keySyncPBX"
#define accSyncPBX          @"accSyncPBX"
#define nameContactSyncPBX  @"VFONE.VN PBX"
#define nameSyncCompany     @"Nhan Hoa Software Company"
#define keySyncPBX          @"CloudCallPBX"

#define getServerInfoFunc       @"GetServerInfo"
#define getServerContacts       @"GetServerContacts"
#define DecryptRSA              @"DecryptRSA"
#define PushSharp               @"PushSharp"
#define ChangeExtPass           @"ChangeExtPass"
#define ChangeExtPass           @"ChangeExtPass"
#define GetServerGroup          @"getservergroup"

#pragma mark - Keys for app

#define AuthUser                @"ddb7c103eb98"
#define AuthKey                 @"2b909f73069e47dba6feddb7c103eb98"

#define language_key            @"language_key"
#define key_en                  @"en"
#define key_vi                  @"vi"

#define key_login               @"key_login"
#define key_password            @"key_password"
#define key_ip                  @"key_ip"
#define key_port                @"key_port"


#define type_phone_home         @"home"
#define type_phone_work         @"work"
#define type_phone_fax          @"fax"
#define type_phone_mobile       @"mobile"
#define type_phone_other        @"other"
#define type_cloudfone_id       @"cloudfoneID"

#define key_sound_call          @"key_sound_call"





#define text_please_enter_confirm_code  @"text_please_enter_confirm_code"



#pragma mark - Key for notifications

#define closeViewForgotPassword @"closeViewForgotPassword"
#define registerWithAccount     @"registerWithAccount"
#define callnexFriendsRequest   @"callnexFriendsRequest"
#define k11UpdateNewGroupName   @"k11UpdateNewGroupName"
#define updateDeliveredChat     @"updateDeliveredChat"
#define getRowsVisibleViewChat  @"getRowsVisibleViewChat"
#define k11TouchOnMessage       @"k11TouchOnMessage"
#define k11SaveConversationChat @"k11SaveConversationChat"
#define recentEmotionDict       @"recentEmotionDict"
#define resetPasswordSucces     @"resetPasswordSucces"
#define closeViewResetPassword  @"closeViewResetPassword"

#define resetPasswordSucces     @"resetPasswordSucces"
#define networkChanged          @"networkChanged"
#define updateTokenForXmpp      @"updateTokenForXmpp"

#define finishGetPBXContacts    @"finishGetPBXContacts"
#define deleteHistoryCallsChoosed           @"deleteHistoryCallsChoosed"

#define k11ReloadAfterDeleteAllCall         @"k11ReloadAfterDeleteAllCall"
#define updateNumberHistoryCallRemove       @"updateNumberHistoryCallRemove"
#define k11SendMailAfterSaveConversation    @"k11SendMailAfterSaveConversation"

#define finishLoadContacts      @"finishLoadContacts"
#define finishRemoveHistoryCall @"finishRemoveHistoryCall"
#define reloadHistoryCall       @"reloadHistoryCall"
#define syncPBXContactsFinish   @"syncPBXContactsFinish"
#define searchContactWithValue  @"searchContactWithValue"

#define k11ClickOnViewTrunkingPBX       @"k11ClickOnViewTrunkingPBX"
#define k11EnableWhiteList              @"k11EnableWhiteList"
#define k11DeclineEnableWhiteList       @"k11DeclineEnableWhiteList"
#define k11DeclineEnableHideMsg         @"k11DeclineEnableHideMsg"
#define selectTypeForPhoneNumber        @"selectTypeForPhoneNumber"
#define saveNewContactFromChatView      @"saveNewContactFromChatView"
#define k11DismissKeyboardInViewChat    @"k11DismissKeyboardInViewChat"
#define activeOutgoingFileTransfer      @"activeOutgoingFileTransfer"
#define reloadCloudFoneContactAfterSync @"reloadCloudFoneContactAfterSync"

#define k11AcceptRequestedSuccessfully  @"k11AcceptRequestedSuccessfully"
#define updatePreviewImageForVideo      @"updatePreviewImageForVideo"

#define k11RejectFriendRequestSuccessfully  @"k11RejectFriendRequestSuccessfully"
#define k11ReloadListFriendsRequested       @"k11ReloadListFriendsRequested"
#define k11DeleteMsgWithRecallID            @"k11DeleteMsgWithRecallID"
#define k11SubjectOfRoomChanged             @"k11SubjectOfRoomChanged"

#define k11UpdateBarNotifications           @"k11UpdateBarNotifications"

#define afterLeaveFromRoomChat          @"afterLeaveFromRoomChat"
#define aUserLeaveRoomChat              @"aUserLeaveRoomChat"
#define whenRoomDestroyed               @"whenRoomDestroyed"
#define k11CreateGroupChatSuccessfully  @"k11CreateGroupChatSuccessfully"

#define updateListMemberInRoom              @"updateListMemberInRoom"
#define k11UpdateAllNotisWhenBecomActive    @"k11UpdateAllNotisWhenBecomActive"
#define k11GetListUserInRoomChat            @"k11GetListUserInRoomChat"
#define kOTRMessageReceived                 @"MessageReceivedNotification"
#define k11ShowPopupNewContact              @"k11ShowPopupNewContact"
#define k11ReceiveMsgOtherRoomChat          @"k11ReceiveMsgOtherRoomChat"
#define k11ReceivedRoomChatMessage          @"k11ReceivedRoomChatMessage"
#define updateUnreadMessageForUser          @"updateUnreadMessageForUser"
#define k11DeleteAllMessageAccept           @"k11DeleteAllMessageAccept"
#define closeRightChatGroupVC               @"closeRightChatGroupVC"
#define reloadRightGroupChatVC              @"reloadRightGroupChatVC"

#define showContactInformation      @"showContactInformation"


#define userAvatar          @"userAvatar"

#pragma mark - flags

#define DATE_FROM       @"DATE_FROM"

#define PBX_ID          @"PBX_ID"
#define PBX_SERVER      @"PBX_SERVER"
#define PBX_USERNAME    @"PBX_USERNAME"
#define PBX_PASSWORD    @"PBX_PASSWORD"
#define PBX_PORT        @"PBX_PORT"
#define PBX_IP_ADDRESSS @"PBX_IP_ADDRESSS"
#define callnexPBXFlag  @"callnexPBXFlag"
#define transport_udp   @"UDP"
#define UserActivity    @"UserActivity"

#define folder_call_records     @"calls_records"


#define missed_call             @"Missed"
#define success_call            @"Success"
#define aborted_call            @"Aborted"
#define declined_call           @"Declined"

#define incomming_call          @"Incomming"
#define outgoing_call           @"Outgoing"
#define hotline                 @"4113"


#define Close   @"Close"

#define sort_group      @"sort_group"
#define sort_pbx        @"sort_pbx"

#define switch_dnd      @"switch_dnd"









#define text_online     @"Sẵn sàng"
#define text_offline    @"Chưa kết nối"
#define text_connecting @"Đang kết nối"
#define text_disabled   @"Không làm phiền"
#define text_no_network @"Không internet"

#define text_all_call           @"Tất cả"
#define text_missed_call        @"Gọi nhỡ"
#define text_record_call        @"Ghi âm"
#define text_no_calls           @"Không có cuộc gọi"
#define text_no_missed_calls    @"Không có cuộc gọi nhỡ"
#define text_unknown            @"Không xác định"
#define text_today              @"Hôm nay"
#define text_yesterday          @"Hôm qua"
#define text_call_details       @"Chi tiết cuộc gọi"
#define text_delete             @"Xóa"
#define text_no                 @"Không"
#define text_yes                @"Có"
#define text_search             @"Tìm kiếm"
#define text_saved_list         @"Danh sách đã lưu"
#define text_no_data            @"Chưa có dữ liệu"
#define text_choose             @"Chọn"
#define text_close              @"Đóng"
#define text_start_date         @"Ngày bắt đầu"
#define text_end_date           @"Ngày kết thúc"
#define text_choose_time        @"Chọn thời gian"
#define text_all_contacts       @"Danh bạ máy"
#define text_pbx_contacts       @"Nội bộ"
#define text_pbx_groups         @"Nhóm nội bộ"
#define text_no_contacts        @"Không có liên hệ"


#define text_check_network      @"Vui lòng kiểm tra kết nối mạng của bạn!"
#define text_phone_empty        @"Số điện thoại không được rỗng!"
#define confirm_delete_history  @"Bạn có muốn xoá lịch sử cuộc gọi?"
#define search_name_or_phone    @"Tìm tên hoặc số điện thoại"
#define count_all_contacts      @"Tất cả liên hệ"

#define contact_name_not_empty  @"Tên liên hệ không được rỗng!"
#define pls_enter_phonenumber   @"Vui lòng nhập số điện thoại"
#define pls_fill_full_info      @"Vui lòng nhập đầy đủ thông tin"
#define pls_check_signin_info   @"Vui lòng kiểm tra thông tin đăng nhập"
#define text_slogent            @"Dịch vụ tổng đài số hàng đầu Việt Nam.\nCung cấp dịch vụ thoại qua Internet tiên tiến nhất."
#define text_welcome            @"Xin chào!\nĐăng nhập để trải nghiệm."
#define cannot_access_camera    @"Không thể truy cập camera. Vui lòng kiểm tra lại quyền của ứng dụng!"
#define cannot_detect_QRCode    @"Không thể kiểm tra QRCode. Vui lòng kiểm tra lại!"
#define or_sign_in_with_QRCode  @"Hoặc đăng nhập với mã QR"
#define text_confirm_sign_out   @"Do you want to sign out?"
#define text_faild_try_later    @"Thất bại. Vui lòng thử lại sau!"
#define avatar_was_removed      @"Ảnh đại diện đã được xoá"
#define avatar_was_uploaded     @"Ảnh đại diện đã được cập nhật"
#define text_newest_version     @"Bạn đang sử dụng phiên bản mới nhất.\nXin cảm ơn!"

#define text_start              @"Bắt đầu"
#define text_account            @"Tài khoản"
#define text_password           @"Mật khẩu"
#define text_sign_in            @"Đăng nhập"
#define text_cancel             @"Hủy bỏ"
#define text_scan_from_photo    @"QUÉT ẢNH CÓ SẴN"

#define text_choose_DID         @"Chọn số gọi ra"
#define text_default            @"Mặc định"
#define text_phonenumber        @"Số điện thoại"
#define text_on                 @"Bật"
#define text_off                @"Tắt"
#define text_setup              @"Cài đặt"
#define text_crop_picture       @"Cắt hình ảnh"
#define text_save               @"Lưu"
#define text_sync_contacts      @"Đồng bộ"
#define text_successful         @"Thành công"
#define text_company            @"Công ty"
#define text_email              @"Email"
#define text_mobile             @"Di động"
#define text_work               @"Công ty"
#define text_home               @"Nhà"
#define text_fax                @"Fax"
#define text_other              @"Khác"
#define text_options            @"Tùy chọn"
#define text_gallery            @"Thư viện"
#define text_camera             @"Chụp ảnh"
#define text_remove_avatar      @"Hủy ảnh đại diệnảnh"
#define text_add_contact        @"Thêm liên hệ"
#define text_fullname           @"Họ tên"
#define text_edit_contact       @"Chỉnh sửa liên hệ"
#define text_do_not_disturb     @"Không làm phiền"
#define text_choose_ringtone    @"Chọn nhạc chuông"
#define text_call_settings      @"Cài đặt cuộc gọi"
#define text_app_info           @"Thông tin ứng dụng"
#define text_send_reports       @"Gửi reports"
#define text_sign_out           @"Đăng xuất"
#define text_privacy_policy     @"Chính sách bảo mật"
#define text_introduction       @"Giới thiệu"
#define text_silent             @"Im lặng"
#define text_hide               @"Ẩn"

#define text_edit_profile       @"Cập nhật hồ sơ"
#define text_account_name       @"Tên tài khoản"
#define text_check_for_update   @"Kiểm tra cập nhật"
#define text_version            @"Phiên bản"
#define text_release_date       @"Ngày phát hành"
#define text_update             @"Cập nhật"
#define text_send_logs          @"Gửi nhật ký ứng dụng"
#define text_send               @"Gửi"

#define text_can_not_send_email             @"Không thể gửi email. Vui lòng kiểm tra lại tài khoản email của bạn!"
#define text_can_not_send_email_check_later @"Không thể gửi email. Vui lòng thử lại sau!"
#define text_email_was_sent                 @"Email của bạn đã được gửi. Xin cảm ơn!"

#define text_calling            @"Đang gọi..."
#define text_ringing            @"Đang đổ chuông..."
#define text_user_busy          @"Người dùng đang bận"
#define text_terminated         @"Cuộc gọi kết thúc"
#define text_connected          @"Đã kết nối"

#define text_mute               @"Tắt tiếng"
#define text_keypad             @"Bàn phím"
#define text_speaker            @"Loa ngoài"
#define text_add_call           @"Thêm cuộc gọi"
#define text_hold_call          @"Giữ cuộc gọi"
#define text_transfer           @"Chuyển cuộc gọi"

#define text_quality            @"Chất lượng"
#define text_good               @"Tốt"
#define text_average            @"Trung bình"
#define text_low                @"Thấp"
#define text_very_low           @"Yếu"
#define text_worse              @"Kém"

#define text_no_account         @"Không có tài khoản"
#define text_not_signed         @"Bạn chưa đăng nhập tài khoản"
#define text_acc_turn_off       @"Tài khoản của bạn đã bị tắt. Bạn có muốn mở lại và gọi?"
#define cant_make_call_yourself @"Không thể gọi cho chính bạn!"
#define get_did_list_fail       @"Không thể lấy danh sách đầu số"
#define text_hotline            @"Hotline"

#define text_or                 @"hoặc"
#define text_and                @"và"
#define text_others             @"người khác"
#define text_sec                @"giây"
#define text_hours              @"giờ"
#define text_hour               @"giờ"
#define text_minutes            @"phút"
#define text_minute             @"phút"

#define cant_make_call_check_signin     @"Không thể gọi lúc này. Có lẽ bạn chưa đăng nhập tài khoản!"


#endif /* AppStrings_h */
