#import "SceneDelegate.h"
#import "AppDelegate.h"
#import <EXSplashScreen/EXSplashScreenService.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
  if ([scene isKindOfClass:[UIWindowScene class]])
  {
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    BOOL hasCreatedBridge = [appDelegate initAppFromScene:connectionOptions];
        
    // Create rootViewController
    UIViewController * rootViewController = appDelegate.createRootViewController;
    [appDelegate setRootView:appDelegate.rootView toRootViewController:rootViewController];


    UIWindow* window = [[UIWindow alloc] initWithWindowScene: scene];
    window.rootViewController = rootViewController;
    
    self.window = window;
    
    appDelegate.window = window;
    
    [self.window makeKeyAndVisible];

    EXSplashScreenService *splashScreenService = (EXSplashScreenService *)[EXModuleRegistryProvider getSingletonModuleForClass:[EXSplashScreenService class]];
    
    [appDelegate finishedLaunchingWithOptions:connectionOptions];
    
    if(!hasCreatedBridge) {
      [splashScreenService hideSplashScreenFor:rootViewController options:EXSplashScreenDefault successCallback:^(BOOL hasEffect){}
                               failureCallback:^(NSString * _Nonnull message) {
        EXLogWarn(@"Hiding splash screen from root view controller did not succeed: %@", message);
      }];
    }
  }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  [appDelegate application:[UIApplication sharedApplication] continueUserActivity:userActivity restorationHandler:^(NSArray<id<UIUserActivityRestoring>> * _Nullable restorableObjects) {
    // Handle restoration here if needed
  }];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
  UIOpenURLContext *context = [URLContexts anyObject];
  if (context) {
    NSURL *url = context.URL;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate application:[UIApplication sharedApplication] openURL:url options:@{}];
  }
}

@end
