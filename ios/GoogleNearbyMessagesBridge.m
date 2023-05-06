//
//  GoogleNearbyMessagesBridge.m
//  SpotMe
//
//  Created by Gabriele Romoli on 13/03/23.
//
#import <Foundation/Foundation.h>
#import "SpotMe-Bridging-Header.h"
#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"

@interface RCT_EXTERN_REMAP_MODULE(GoogleNearbyMessages, NearbyMessages, NSObject)
RCT_EXTERN_METHOD(start:(NSString)message);
RCT_EXTERN_METHOD(stop);
/*RCT_EXTERN_METHOD(connect:(NSString)apiKey discoveryModes:(NSArray)discoveryModes discoveryMediums:(NSArray)discoveryMediums resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject);
//RCT_EXTERN_METHOD(disconnect);
RCT_EXTERN_METHOD(publish:(NSString)message resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(unpublish:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(subscribe:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(unsubscribe);
RCT_EXTERN_METHOD(checkBluetoothPermission:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject);
RCT_EXTERN_METHOD(checkBluetoothAvailability:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject);*/
@end
