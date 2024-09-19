- (BOOL)initAppFromScene:(UISceneConnectionOptions *)connectionOptions {
    // If bridge has already been initiated by another scene, there's nothing to do here
    if (self.bridge != nil) {
        return NO;
    }

    if (self.bridge == nil) {
      // This is broken in React Native < 0.76, so we call the implementation of the method manually
      // https://github.com/facebook/react-native/issues/44329
      // RCTAppSetupPrepareApp([UIApplication sharedApplication], self.turboModuleEnabled);
      
      // # BEGIN OF RCTAppSetupPrepareApp
      RCTEnableTurboModule(self.turboModuleEnabled);

      #if DEBUG
        // Disable idle timer in dev builds to avoid putting application in background and complicating
        // Metro reconnection logic. Users only need this when running the application using our CLI tooling.
        [UIApplication sharedApplication].idleTimerDisabled = YES;
      #endif
      // # END OF RCTAppSetupPrepareApp
      
      self.rootViewFactory = [self createRCTRootViewFactory];
    }

    NSDictionary * initProps = [self prepareInitialProps];
    self.rootView = [self.rootViewFactory viewWithModuleName:self.moduleName initialProperties:initProps launchOptions:[self connectionOptionsToLaunchOptions:connectionOptions]];

    self.rootView.backgroundColor = [UIColor blackColor];

    return YES;
}

- (NSDictionary<NSString *, id> *)prepareInitialProps {
    NSMutableDictionary<NSString *, id> *initProps = [self.initialProps mutableCopy] ?: [NSMutableDictionary dictionary];
#if RCT_NEW_ARCH_ENABLED
    initProps[@"kRNConcurrentRoot"] = [self concurrentRootEnabled];
#endif
    return [initProps copy];
}

- (NSDictionary<UIApplicationLaunchOptionsKey, id> *)connectionOptionsToLaunchOptions:(UISceneConnectionOptions *)connectionOptions {
    NSMutableDictionary<UIApplicationLaunchOptionsKey, id> *launchOptions = [NSMutableDictionary dictionary];

    if (connectionOptions) {
        if (connectionOptions.notificationResponse) {
            launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] = connectionOptions.notificationResponse.notification.request.content.userInfo;
        }

        if ([connectionOptions.userActivities count] > 0) {
            NSUserActivity* userActivity = [connectionOptions.userActivities anyObject];
            NSDictionary *userActivityDictionary = @{
                @"UIApplicationLaunchOptionsUserActivityTypeKey": [userActivity activityType] ? [userActivity activityType] : [NSNull null],
                @"UIApplicationLaunchOptionsUserActivityKey": userActivity ? userActivity : [NSNull null]
            };
            launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey] = userActivityDictionary;
        }

        NSURL *url = connectionOptions.URLContexts.anyObject.URL;
        if (url != nil) {
          // Log the URL to the console
          NSLog(@"<<<FM>>> URL: %@", url.absoluteString);
          launchOptions[UIApplicationLaunchOptionsURLKey] = url;
        }
    }

    return launchOptions;
}