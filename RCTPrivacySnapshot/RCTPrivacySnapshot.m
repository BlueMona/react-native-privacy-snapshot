//
//  RCTPrivacySnapshot.m
//  RCTPrivacySnapshot
//
//  Created by Roger Chapman on 7/10/2015.
//  Copyright © 2015 Kayla Technologies. All rights reserved.
//

#import "RCTPrivacySnapshot.h"
#import "UIImage+ImageEffects.h"

@implementation RCTPrivacySnapshot {
    BOOL enabled;
    UIImageView *obfuscatingView;
}

RCT_EXPORT_MODULE();

#pragma mark - Lifecycle

- (instancetype)init {
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppStateResignActive)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppStateActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - App Notification Methods

- (void)handleAppStateResignActive {
    if (self->enabled) {
        UIWindow    *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIImageView *blurredScreenImageView = nil;
        NSArray *allPngImageNames = [[NSBundle mainBundle] pathsForResourcesOfType:@"png"
                                                                       inDirectory:nil];
        for (NSString *imgName in allPngImageNames){
            // Find launch images
            if ([imgName containsString:@"LaunchImage"]){
                UIImage *img = [UIImage imageNamed:imgName]; //-- this is a launch image
                // Has image same scale and dimensions as our current device's screen?
                if (img.scale == [UIScreen mainScreen].scale && CGSizeEqualToSize(img.size, [UIScreen mainScreen].bounds.size)) {
                    NSLog(@"Found launch image for current device %@", img.description);
                    blurredScreenImageView = [[UIImageView alloc] initWithImage: img];
                }
            }
        }
        
        if (blurredScreenImageView == nil) {
            blurredScreenImageView = [[UIImageView alloc] initWithFrame:keyWindow.bounds];
            UIGraphicsBeginImageContext(keyWindow.bounds.size);
            [keyWindow drawViewHierarchyInRect:keyWindow.frame afterScreenUpdates:NO];
            UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            blurredScreenImageView.image = [viewImage applyDarkEffect];
        }
        
        self->obfuscatingView = blurredScreenImageView;
        [[UIApplication sharedApplication].keyWindow addSubview:self->obfuscatingView];

    }
}

- (void)handleAppStateActive {
    if  (self->obfuscatingView) {
        [UIView animateWithDuration: 0
                         animations: ^ {
                             self->obfuscatingView.alpha = 0;
                         }
                         completion: ^(BOOL finished) {
                             [self->obfuscatingView removeFromSuperview];
                             self->obfuscatingView = nil;
                         }
         ];
    }
}

#pragma mark - Public API

RCT_EXPORT_METHOD(enabled:(BOOL) _enable) {
    self->enabled = _enable;
}

@end
