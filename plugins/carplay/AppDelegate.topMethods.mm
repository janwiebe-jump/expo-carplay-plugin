@interface RCTAppDelegate () <RCTTurboModuleManagerDelegate>
@end

@interface AppDelegate()

@property (nonatomic, strong) EXReactDelegateWrapper *reactDelegate;

@end

@implementation AppDelegate {
    EXExpoAppDelegate *_expoAppDelegate;
}

// Synthesize window, so the AppDelegate can synthesize it too.
@synthesize window = _window;

- (instancetype)init
{
  if (self = [super init]) {
    _expoAppDelegate = [[EXExpoAppDelegate alloc] init];
    _reactDelegate = [[EXReactDelegateWrapper alloc] initWithExpoReactDelegate:_expoAppDelegate.reactDelegate];
  }
  return self;
}

// This needs to be implemented, otherwise forwarding won't be called.
// When the app starts, `UIApplication` uses it to check beforehand
// which `UIApplicationDelegate` selectors are implemented.
- (BOOL)respondsToSelector:(SEL)selector
{
  return [super respondsToSelector:selector]
    || [_expoAppDelegate respondsToSelector:selector];
}

// Forwards all invocations to `ExpoAppDelegate` object.
- (id)forwardingTargetForSelector:(SEL)selector
{
  return _expoAppDelegate;
}

- (UIViewController *)createRootViewController
{
  return [self.reactDelegate createRootViewController];
}

- (RCTRootViewFactory *)createRCTRootViewFactory
{
  RCTRootViewFactoryConfiguration *configuration =
      [[RCTRootViewFactoryConfiguration alloc] initWithBundleURL:self.bundleURL
                                                  newArchEnabled:self.fabricEnabled
                                              turboModuleEnabled:self.turboModuleEnabled
                                               bridgelessEnabled:self.bridgelessEnabled];

  __weak __typeof(self) weakSelf = self;
  configuration.createRootViewWithBridge = ^UIView *(RCTBridge *bridge, NSString *moduleName, NSDictionary *initProps)
  {
    return [weakSelf createRootViewWithBridge:bridge moduleName:moduleName initProps:initProps];
  };

  configuration.createBridgeWithDelegate = ^RCTBridge *(id<RCTBridgeDelegate> delegate, NSDictionary *launchOptions)
  {
    return [weakSelf createBridgeWithDelegate:delegate launchOptions:launchOptions];
  };

  return [[EXReactRootViewFactory alloc] initWithReactDelegate:self.reactDelegate configuration:configuration turboModuleManagerDelegate:self];
}

- (void)finishedLaunchingWithOptions:(UISceneConnectionOptions *)connectionOptions
{
  [_expoAppDelegate application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:[self connectionOptionsToLaunchOptions:connectionOptions]];
}