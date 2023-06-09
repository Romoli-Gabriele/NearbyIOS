#import "AppDelegate.h"
#import <BackgroundTasks/BackgroundTasks.h>
#import <React/RCTBundleURLProvider.h>
#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"
#import "SpotMe-Bridging-Header.h"
#import <Foundation/Foundation.h>

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"SpotMe";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

/// This method controls whether the `concurrentRoot`feature of React18 is turned on or off.
///
/// @see: https://reactjs.org/blog/2022/03/29/react-v18.html
/// @note: This requires to be rendering on Fabric (i.e. on the New Architecture).
/// @return: `true` if the `concurrentRoot` feature is enabled. Otherwise, it returns `false`.
- (BOOL)concurrentRootEnabled
{
  return true;
}
/*- (void)applicationDidEnterBackground:(UIApplication *)application {
  __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [application beginBackgroundTaskWithName:@"MyBackgroundTask" expirationHandler:^{
      // Termina il task in background quando scade il tempo di esecuzione
      [application endBackgroundTask:backgroundTaskIdentifier];
      backgroundTaskIdentifier = UIBackgroundTaskInvalid;
  }];
  
  // Avvia il thread in background
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      // Esegui qui il tuo codice in background
    Boolean send = true;
    int count = 0;
    while (send) {
      NSLog(@"Background thread running");
      
      [NSThread sleepForTimeInterval:5.0];
        count++;
        if(count == 10){
          send = false;
        }
        
      }
    
      // Termina il task in background quando l'operazione è completata
      [application endBackgroundTask:backgroundTaskIdentifier];
      backgroundTaskIdentifier = UIBackgroundTaskInvalid;
  });
}*/

@end
