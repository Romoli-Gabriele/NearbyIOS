//
//  Copyright 2023 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#endif
import NearbyConnections

class Config {
    static let serviceId = "SPOTLIVE"
    static let defaultStategy = Strategy.cluster
    static let defaultAdvertisingState = false
    static let defaultDiscoveryState = false
    static let bytePayload = "hello world"

#if os(iOS) || os(watchOS) || os(tvOS)
    static let defaultEndpointName = UIDevice.current.name
#elseif os(macOS)
    static let defaultEndpointName = Host.current().localizedName ?? "Unknown macOS Device"
#else
    static let defaultEndpointName = "Unknown Device"
#endif
}
