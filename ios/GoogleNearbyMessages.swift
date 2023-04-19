//
//  GoogleNearbyMessages.swift
//  SpotMe
//
//  Created by Gabriele Romoli on 13/03/23.
//

import Foundation
import CoreBluetooth
import BackgroundTasks
import UserNotifications
import CoreLocation

let defaultDiscoveryModes: GNSDiscoveryMode = [.broadcast, .scan]
let defaultDiscoveryMediums: GNSDiscoveryMediums = .BLE

@objc(NearbyMessages)
class NearbyMessages: RCTEventEmitter, CLLocationManagerDelegate{
  enum EventType: String, CaseIterable {
    case MESSAGE_FOUND
    case MESSAGE_LOST
    case onActivityStart
    case onActivityStop
    case BLUETOOTH_ERROR
    case PERMISSION_ERROR
    case MESSAGE_NO_DATA_ERROR
  }
  enum GoogleNearbyMessagesError: Error, LocalizedError {
    case permissionError(permissionName: String)
    case runtimeError(message: String)
    
    public var errorDescription: String? {
      switch self {
      case .permissionError(permissionName: let permissionName):
        return "Permission has been denied! Denied Permission: \(permissionName). Make sure to include NSBluetoothPeripheralUsageDescription in your Info.plist!"
      case .runtimeError(message: let message):
        return message
      }
    }
  }
  
  private var active = true
  private var messageManager: GNSMessageManager? = nil
  private var currentPublication: GNSPublication? = nil
  private var currentSubscription: GNSSubscription? = nil
  private var discoveryModes: GNSDiscoveryMode? = nil
  private var discoveryMediums: GNSDiscoveryMediums? = nil
  // workaround objects for checkBluetoothAvailability
  private var tempBluetoothManager: CBCentralManager? = nil
  private var tempBluetoothManagerDelegate: CBCentralManagerDelegate? = nil
  private var didCallback = false
  private var _locationManager: CLLocationManager?
  private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
  private var threadStarted = false
  private var threadShouldExit = false
  public var locationManager: CLLocationManager {
    get {
      if let l = _locationManager {
        return l
      }
      else {
        let l = CLLocationManager()
        l.delegate = self
        _locationManager = l
        return l
      }
    }
  }
  
  @objc(connect:discoveryModes:discoveryMediums:resolver:rejecter:)
  func connect(_ apiKey: String, discoveryModes: Array<NSString>, discoveryMediums: Array<NSString>, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    let notificationCenter = UNUserNotificationCenter.current();
    notificationCenter.requestAuthorization(options: [.badge, .alert, .sound]) {
      (granted, error) in
      if(error == nil)
      {
        print("Accettate notifiche: \(granted)")
      }
    }
    locationManager.requestAlwaysAuthorization()
    print("GNM_BLE: Connecting...")
    GNSMessageManager.setDebugLoggingEnabled(true)
    GNSMessageManager.setDebugLoggingEnabled(true)
    self.discoveryMediums = parseDiscoveryMediums(discoveryMediums)
    self.discoveryModes = parseDiscoveryModes(discoveryModes)
    self.messageManager = GNSMessageManager(apiKey: apiKey,
                                            paramsBlock: { (params: GNSMessageManagerParams?) in
      guard let params = params else { return }
      params.microphonePermissionErrorHandler = { (hasError: Bool) in
        if (hasError) {
          self.sendEvent(withName: EventType.PERMISSION_ERROR.rawValue, body: [ "message": "Microphone Permission denied!" ])
        }
      }
      params.bluetoothPowerErrorHandler = { (hasError: Bool) in
        if (hasError) {
          self.sendEvent(withName: EventType.BLUETOOTH_ERROR.rawValue, body: [ "message": "Bluetooth is powered off/unavailable!" ])
        }
      }
      params.bluetoothPermissionErrorHandler = { (hasError: Bool) in
        if (hasError) {
          self.sendEvent(withName: EventType.PERMISSION_ERROR.rawValue, body: [ "message": "Bluetooth Permission denied!" ])
        }
      }
    })
    resolve(nil)
  }
  
  @objc
  func disconnect() -> Void {
    print("GNM_BLE: Disconnecting...");
    // TODO: is setting nil enough garbage collection? no need for CFRetain, CFRelease, or CFAutorelease?
    self.currentSubscription = nil
    self.currentPublication = nil
    self.messageManager = nil
    self.sendEvent(withName: EventType.onActivityStop.rawValue, body: [ "message":"Stop" ]);
  }
  
  
  @objc(publish:resolver:rejecter:)
  func publish(_ message: String, resolver resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
      print("GNM_BLE: Publishing...")
    //Rimuovo messaggi precedenti
    if(self.currentPublication != nil){
      self.currentPublication = nil;
    }
      do {
        if (self.messageManager == nil) {
          throw GoogleNearbyMessagesError.runtimeError(message: "Google Nearby Messages is not connected! Call connect() before any other calls.")
        }
          self.currentPublication = self.messageManager!.publication(with: GNSMessage(content: message.data(using: .utf8)), paramsBlock: { (params: GNSPublicationParams?) in
            guard let params = params else { return }
            params.strategy = GNSStrategy(paramsBlock: { (params: GNSStrategyParams?) in
              guard let params = params else { return }
              params.allowInBackground = true;
              params.discoveryMediums = .BLE
              params.discoveryMode = self.discoveryModes ?? defaultDiscoveryModes
            })
          })
          resolve(nil)
        } catch {
          reject("GOOGLE_NEARBY_MESSAGES_ERROR_PUBLISH", error.localizedDescription, error)
        }
  }

   func unpublish(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
     print("GNM_BLE: Unpublishing...");
     self.currentPublication = nil;
     resolve(nil);
   }
  
  @objc(subscribe:rejecter:)
  func subscribe(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    print("GNM_BLE: Subscribing...")
    do {
      if (self.messageManager == nil) {
        throw GoogleNearbyMessagesError.runtimeError(message: "Google Nearby Messages is not connected! Call connect() before any other calls.")
      }
      self.currentSubscription = self.messageManager!.subscription(
        messageFoundHandler: { (message: GNSMessage?) in
          guard let data = message?.content else {
            self.sendEvent(withName: EventType.MESSAGE_NO_DATA_ERROR.rawValue, body: [ "message": "Message does not have any Data!" ] )
            return
          }
          print("GNM_BLE: Found message!")
          self.sendEvent(withName: EventType.MESSAGE_FOUND.rawValue, body: [ "message": String(data: data, encoding: .utf8) ]);
        },
        messageLostHandler: { (message: GNSMessage?) in
          guard let data = message?.content else {
            self.sendEvent(withName: EventType.MESSAGE_NO_DATA_ERROR.rawValue, body: [ "message": "Message does not have any Data!" ] )
            return
          }
          print("GNM_BLE: Lost message!")
          self.sendEvent(withName: EventType.MESSAGE_LOST.rawValue, body: [ "message": String(data: data, encoding: .utf8) ]);
        },
        paramsBlock: { (params: GNSSubscriptionParams?) in
          guard let params = params else { return }
          params.strategy = GNSStrategy(paramsBlock: { (params: GNSStrategyParams?) in
            guard let params = params else { return }
            params.allowInBackground = false;
            params.discoveryMediums = self.discoveryMediums ?? defaultDiscoveryMediums
            params.discoveryMode = self.discoveryModes ?? defaultDiscoveryModes
          })
        })
      self.sendEvent(withName: EventType.onActivityStart.rawValue, body: [ "Start" ]);
      resolve(nil)
    } catch {
      reject("GOOGLE_NEARBY_MESSAGES_ERROR_SUBSCRIBE", error.localizedDescription, error)
    }
  }
  
  @objc
  func unsubscribe() -> Void {
    print("GNM_BLE: Unsubscribing...")
    self.currentSubscription = nil
  }
  
  @objc(checkBluetoothPermission:rejecter:)
  func checkBluetoothPermission(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    print("GNM_BLE: Checking Bluetooth Permissions...")
    let hasBluetoothPermission = self.hasBluetoothPermission()
    resolve(hasBluetoothPermission)
  }
  
  @objc(checkBluetoothAvailability:rejecter:)
  func checkBluetoothAvailability(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    if (self.tempBluetoothManager != nil || self.tempBluetoothManagerDelegate != nil) {
      let error = GoogleNearbyMessagesError.runtimeError(message: "Another Bluetooth availability check is already in progress!")
      reject("GOOGLE_NEARBY_MESSAGES_CHECKBLUETOOTH_ERROR", error.localizedDescription, error)
      return
    }
    self.didCallback = false
    class BluetoothManagerDelegate : NSObject, CBCentralManagerDelegate {
      private var promiseResolver: RCTPromiseResolveBlock
      private weak var parentReference: NearbyMessages?
      init(resolver: @escaping RCTPromiseResolveBlock, parentReference: NearbyMessages) {
        self.promiseResolver = resolver
        self.parentReference = parentReference
      }
      
      func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let parent = parentReference else {
          return
        }
        if (!parent.didCallback) {
          parent.didCallback = true
          print("GNM_BLE: CBCentralManager did update state with \(central.state.rawValue)")
          self.promiseResolver(central.state == .poweredOn)
          parent.tempBluetoothManager = nil
          parent.tempBluetoothManagerDelegate = nil
        }
      }
    }
    tempBluetoothManagerDelegate = BluetoothManagerDelegate(resolver: resolve, parentReference: self)
    tempBluetoothManager = CBCentralManager(delegate: tempBluetoothManagerDelegate, queue: nil)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
      if (!self.didCallback) {
        self.didCallback = true
        let error = GoogleNearbyMessagesError.runtimeError(message: "The CBCentralManager (Bluetooth) did not power on after 10 seconds. Cancelled execution.")
        reject("GOOGLE_NEARBY_MESSAGES_CHECKBLUETOOTH_TIMEOUT", error.localizedDescription, error)
        self.tempBluetoothManager = nil
        self.tempBluetoothManagerDelegate = nil
      }
    }
  }
  
  func hasBluetoothPermission() -> Bool {
    if #available(iOS 13.1, *) {
      return CBCentralManager.authorization == .allowedAlways
    } else if #available(iOS 13.0, *) {
      return CBCentralManager().authorization == .allowedAlways
    }
    // Before iOS 13, Bluetooth permissions are not required
    return true
  }
  
  override func supportedEvents() -> [String]! {
    return EventType.allCases.map { (event: EventType) -> String in
      return event.rawValue
    }
  }
  
  @objc
  override static func requiresMainQueueSetup() -> Bool {
    // init on main thread, audio doesn't work on background thread.
    return true
  }
  
  // Called when the UIView gets destroyed (e.g. App reload)
  @objc
  override func invalidate() {
    print("GNM_BLE: invalidate")
    disconnect()
  }
  
  func parseDiscoveryMediums(_ discoveryMediums: Array<NSString>) -> GNSDiscoveryMediums {
    var mediums = GNSDiscoveryMediums()
    for medium in discoveryMediums {
      let mediumLower = medium.lowercased
      switch (mediumLower) {
      case "ble":
        mediums.insert(.BLE)
        break
      case "audio":
        mediums.insert(.audio)
        break
      default:
        break
      }
    }
    return mediums.isEmpty ? defaultDiscoveryMediums : mediums
  }
  
  
  func parseDiscoveryModes(_ discoveryModes: Array<NSString>) -> GNSDiscoveryMode {
    var modes = GNSDiscoveryMode()
    for mode in discoveryModes {
      let modeLower = mode.lowercased
      switch (modeLower) {
      case "broadcast":
        modes.insert(.broadcast)
        break
      case "scan":
        modes.insert(.scan)
        break
      default:
        break
      }
    }
    return modes.isEmpty ? defaultDiscoveryModes : modes
  }
  @objc
  func SendNotification(message:String){
    let notificationCenter = UNUserNotificationCenter.current();
    let uuidString = UUID().uuidString
    let content = UNMutableNotificationContent();
    content.title = "Attenzione";
    content.body = message;
    if(message == "Non sei più visibile agli altri utenti"){
      content.sound = UNNotificationSound.default;
    }
    if #available(iOS 15.0, *) {
      content.interruptionLevel = UNNotificationInterruptionLevel.critical
    }
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (10), repeats: false);
    let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger);
    notificationCenter.add(request){ error in
      if let error = error {
          print("Errore nell'aggiunta della notifica: \(error)")
      }
    }
  }
  
  @objc
  func stop(){
    print("STOP");
    self.locationManager.stopUpdatingLocation();
    self.threadShouldExit = true
    self.active = false
    UIApplication.shared.endBackgroundTask(self.backgroundTask)
    self.unsubscribe()
    self.disconnect()
    self.sendEvent(withName: "onActivityStop", body: "fermato")
  }
  
  @objc
  func start(_ message: String){
    print("START");
    
    DispatchQueue.main.async {
      NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
        self.active = true
      }
      NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
        self.active = false
      }
    }
    
    self.subscribe(){ (result: Any?) in
      DispatchQueue.main.async {
        self.publish(message){(result: Any?) in
          print("Primo messaggio inviato")
        }rejecter: { (errorCode: String?, errorMessage: String?, error: Error?) in
          print(errorMessage ?? "Errore");
        };
      }
      
      locationManager.pausesLocationUpdatesAutomatically = false
      locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
      locationManager.distanceFilter = 3000.0
      locationManager.showsBackgroundLocationIndicator = true;
      if #available(iOS 9.0, *) {
        locationManager.allowsBackgroundLocationUpdates = true
      } else {
        // not needed on earlier versions
      }
      // start updating location at beginning just to give us unlimited background running time
      self.locationManager.startUpdatingLocation()
      
      periodicallySendScreenOnNotifications(message:message)
      extendBackgroundRunningTime()
    } rejecter: { (errorCode: String?, errorMessage: String?, error: Error?) in
      print(errorMessage ?? "Errore");
    };
    
    self.sendEvent(withName: "onActivityStart", body: "partito");
  }
  
  private func extendBackgroundRunningTime() {
    if (threadStarted) {
      // if we are in here, that means the background task is already running.
      // don't restart it.
      return
    }
    threadStarted = true
    NSLog("Attempting to extend background running time")
    
    self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Task1", expirationHandler: {
      NSLog("Background task expired by iOS.")
      UIApplication.shared.endBackgroundTask(self.backgroundTask)
    })

  
    var lastLogTime = 0.0
    DispatchQueue.global().async {
      let startedTime = Int(Date().timeIntervalSince1970) % 10000000
      NSLog("*** STARTED BACKGROUND THREAD")
      while(!self.threadShouldExit) {
          DispatchQueue.main.async {
              let now = Date().timeIntervalSince1970
              let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
              if abs(now - lastLogTime) >= 2.0 {
                  lastLogTime = now
                  if backgroundTimeRemaining < 10.0 {
                    NSLog("About to suspend based on background thread running out.")
                  }
                  if (backgroundTimeRemaining < 200000.0) {
                   NSLog("Thread \(startedTime) background time remaining: \(backgroundTimeRemaining)")
                  }
                  else {
                    //NSLog("Thread \(startedTime) background time remaining: INFINITE")
                  }
              }
          }
          sleep(1)
      }
      self.threadStarted = false
      NSLog("*** EXITING BACKGROUND THREAD")
    }

  }
  
  private func periodicallySendScreenOnNotifications(message: String) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+30.0) {
          self.publish(message) { (result: Any?) in
            self.SendNotification(message: "Inviato correttamente");
          } rejecter: { (errorCode: String?, errorMessage: String?, error: Error?) in
            print(errorMessage ?? "Errore");
            self.SendNotification(message: "Errore invio");
          }
          self.periodicallySendScreenOnNotifications(message: message)
        }
    }
  
  private func sendNotification(message: String) {
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications()
            let content = UNMutableNotificationContent()
            content.title = "SpotLive"
            content.body = message
            content.categoryIdentifier = "low-priority"
            //let soundName = UNNotificationSoundName("silence.mp3")
            //content.sound = UNNotificationSound(named: soundName)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
  
  
}
