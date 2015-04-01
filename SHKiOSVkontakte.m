//
// Created by Alexandr Evsyuchenya on 3/23/15.
// Copyright (c) 2015 Hamleys. All rights reserved.
//

#import "SHKiOSVkontakte.h"
#import "SHKSharer_protected.h"
#import "VKSdk.h"
#import "SHKConfiguration.h"


@interface VKDelegate : NSObject <VKSdkDelegate>
@property(nonatomic, strong) SHKiOSVkontakte *sharer;
@end

@implementation VKDelegate

#pragma mark - VKSdkDelegate protocol

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError
{
    NSLog(@"%s", sel_getName(_cmd));
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
        self.sharer = nil;
    }
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:controller animated:YES completion:nil];
}

- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken
{
    id <SHKSharerDelegate> o = self.sharer.shareDelegate;
    if ([o respondsToSelector:@selector(sharerAuthDidFinish:success:)])
    {
        [o sharerAuthDidFinish:self.sharer success:YES];
        self.sharer = nil;
    }
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
            [VKSdk initializeWithDelegate:_instance andAppId:SHKCONFIG(vkontakteAppId)];
            if ([VKSdk wakeUpSession])
            {
                //Start working
            }
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
    return @"Вконтакте";
}

- (void)promptAuthorization
{
    if (![self isAuthorized])
        [SHKiOSVkontakte instanceVK].sharer = self;
    [VKSdk authorize:@[@"wall"] revokeAccess:YES];
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
    HMLAssert(YES, @"Not implemented yet");
    return NO;
}

@end