//
// Created by Alexandr Evsyuchenya on 3/23/15.
// Copyright (c) 2015 Hamleys. All rights reserved.
//

#import "SHKiOSVkontakte.h"
#import "SHKSharer_protected.h"
#import "VKSdk.h"
#import "SHKConfiguration.h"
#import "FormControllerCallback.h"


@interface VKDelegate : NSObject <VKSdkDelegate, VKSdkUIDelegate>
@property(nonatomic, strong) SHKiOSVkontakte *sharer;
@end

@interface VKDelegate ()
@property(nonatomic, copy) FormControllerCallback formControllerCallback;
@property(nonatomic, strong) VKActivity *activity;
@property(nonatomic) BOOL isVCWillBePresented;
@end

@implementation VKDelegate

#pragma mark - VKSdkDelegate protocol

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError
{
}

- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken
{
    [SHKiOSVkontakte logout];
}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError
{
    id <SHKSharerDelegate> o = self.sharer.shareDelegate;
    if ([o respondsToSelector:@selector(sharerAuthDidFinish:success:)])
    {
        [o sharerAuthDidFinish:self.sharer success:NO];
    }
    self.formControllerCallback = [self.sharer authorizationFormCancel];
    if (!self.isVCWillBePresented && self.formControllerCallback)
        self.formControllerCallback(nil);
    self.sharer = nil;
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
    self.isVCWillBePresented = YES;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:controller animated:YES completion:nil];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken
{
    id <SHKSharerDelegate> o = self.sharer.shareDelegate;
    if ([o respondsToSelector:@selector(sharerAuthDidFinish:success:)])
    {
        [o sharerAuthDidFinish:self.sharer success:YES];
    }
    self.formControllerCallback = [self.sharer authorizationFormSave];
    if (self.formControllerCallback)
    {
        self.formControllerCallback(nil);
        self.formControllerCallback = nil;
    }
    self.sharer = nil;
}

- (BOOL)vkSdkAuthorizationAllowFallbackToSafari
{
    return NO;
}

- (BOOL)vkSdkIsBasicAuthorization
{
    return YES;
}

- (void)vkSdkDidDismissViewController:(UIViewController *)controller
{
    if (self.formControllerCallback)
    {
        self.formControllerCallback(nil);
    }
}

- (void)setSharer:(SHKiOSVkontakte *)sharer
{
    _sharer = sharer;
    self.isVCWillBePresented = NO;
}


@end

@implementation SHKiOSVkontakte

+ (VKDelegate *)instanceVK
{
    static VKDelegate *_instance = nil;

    @synchronized (self)
    {
        if (_instance == nil)
        {
            _instance = [VKDelegate new];
            
            VKSdk *sdk = [VKSdk initializeWithAppId:SHKCONFIG(vkontakteAppId)];
            [sdk registerDelegate:_instance];
            [sdk setUiDelegate:_instance];
            [VKSdk wakeUpSession:SHKCONFIG(vkontaktePermissions) completeBlock:^(VKAuthorizationState state, NSError *error)
            {
                if (state == VKAuthorizationAuthorized)
                {
                    // Authorized and ready to go
                } else if (error)
                {
                    // Some error happend, but you may try later
                }
            }];
        }
    }

    return _instance;
}


- (id)init
{
    self = [super init];
    if (self)
    {
        [SHKiOSVkontakte instanceVK];
    }

    return self;
}

+ (BOOL)canShareOffline
{
    return NO;
}

+ (NSString *)sharerTitle
{
    return @"VK";
}

- (void)promptAuthorization
{
    if (![self isAuthorized])
        [SHKiOSVkontakte instanceVK].sharer = self;
    [VKSdk authorize:SHKCONFIG(vkontaktePermissions) withOptions:VKAuthorizationOptionsUnlimitedToken];
}

+ (void)logout
{
    [VKSdk forceLogout];
}

+ (BOOL)canShareImage
{
    return YES;
}

+ (BOOL)isServiceAuthorized
{
    return [VKSdk isLoggedIn];
}

- (BOOL)isAuthorized
{
    return [VKSdk isLoggedIn];
}

- (BOOL)send
{
    if (![self validateItem])
        return NO;

    switch (self.item.shareType)
    {
        case SHKShareTypeImage:
            [self sendImageAction];
            break;
        default:
            return NO;
    }

    return YES;
}

- (void)sendImageAction
{
    NSMutableArray *items = [@[self.item.image, self.item.title] mutableCopy];
    if (self.item.URL)
    {
	[items addObject:self.item.URL];
    }
    [SHKiOSVkontakte instanceVK].activity = [VKActivity new];
    [[SHKiOSVkontakte instanceVK].activity prepareWithActivityItems:items];
    VKShareDialogController *const present = (VKShareDialogController *const) [SHKiOSVkontakte instanceVK].activity.activityViewController;
    present.dismissAutomatically = YES;
    present.completionHandler = ^(VKShareDialogController *dialog, VKShareDialogControllerResult result)
    {
        switch (result)
        {
            case VKShareDialogControllerResultCancelled:
                [self.shareDelegate sharerCancelledSending:self];
                break;
            case VKShareDialogControllerResultDone:
                [self.shareDelegate sharerFinishedSending:self];
                break;
        }
        [SHKiOSVkontakte instanceVK].activity = nil;
    };
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:present animated:YES completion:nil];
}

- (void)setShareDelegate:(id <SHKSharerDelegate>)delegate
{
    [super setShareDelegate:delegate];
}

@end
