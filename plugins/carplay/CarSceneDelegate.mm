#import "CarSceneDelegate.h"
#import "AppDelegate.h"
#import "RNCarPlay.h"

@implementation CarSceneDelegate

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
   didConnectInterfaceController:(CPInterfaceController *)interfaceController
{
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  [appDelegate initAppFromScene: nil];
  
  [RNCarPlay connectWithInterfaceController:interfaceController window:templateApplicationScene.carWindow];
}

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene didDisconnectInterfaceController:(CPInterfaceController *)interfaceController
{
    [RNCarPlay disconnect];
}

@end