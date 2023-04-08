// GoogleNearbyMessagesBridge.m
// SpotMe
//
// Created by Gabriele Romoli on 13/03/23.
//

#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"

@interface RCT_EXTERN_REMAP_MODULE(GoogleNearbyMessages, NearbyMessages, RCTEventEmitter)
RCT_EXTERN_METHOD(start);
RCT_EXTERN_METHOD(stop);
@end

