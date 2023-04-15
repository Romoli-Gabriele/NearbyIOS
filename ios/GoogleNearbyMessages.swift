import Foundation
import CoreLocation
import CoreBluetooth
import UserNotifications

@objc(NearbyMessages)
class NearbyMessages: RCTEventEmitter, CLLocationManagerDelegate {
  private var bleManager: BLEManager?
  private var advertiser: Advertiser?
  public var eventEmitter: RCTEventEmitter?
  private var initialized = false
  private var active = true
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
  
  
  override class func requiresMainQueueSetup() -> Bool {
    return true
  }

  override init() {
    super.init()
    bleManager = BLEManager(eventEmitter: self)
    eventEmitter = self
    locationManager.requestAlwaysAuthorization()
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        self.updateAuthWarnings()
        if let error = error {
            NSLog("error: \(error)")
        }
        
    }
    self.updateAuthWarnings()
  }
  
  override func supportedEvents() -> [String]! {
    return ["deviceFound", "onActivityStart", "onActivityStop"]
  }
  func updateAuthWarnings() {
      DispatchQueue.global().async{
          if CLLocationManager.locationServicesEnabled() {
              print("Location autorizzata")
              if CLLocationManager.authorizationStatus() == .authorizedAlways {
                  print("Location permission set to always")
              }
              else {
                  print("Location permission not set to always")
              }
          }
          else {
            print("Location disabled in settings")
          }
        if #available(iOS 13.1, *){
          if CBManager.authorization == .allowedAlways {
            print("Bluetooth allowed")
          }
          else {
            print("Bluetooth permission denied")
          }
          
        }
          UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
              if settings.authorizationStatus == UNAuthorizationStatus.authorized {
                print("Notification permission approved")
              }
              else {
                print("Notification permission denied")
              }
          })
      }
  }
  
  @objc
  func start(){
    if (initialized) {
        return
    }
    DispatchQueue.main.async {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            self.active = true
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            self.active = false
        }
    }
    
    initialized = true
    bleManager?.start()
    advertiser = Advertiser(code: "gcyguiisdfgh")
            
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

    periodicallySendScreenOnNotifications()
    extendBackgroundRunningTime()
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
  private func periodicallySendScreenOnNotifications() {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+30.0) {
          self.sendNotification()
          self.periodicallySendScreenOnNotifications()
      }
  }
  private func sendNotification() {
      DispatchQueue.main.async {
          let center = UNUserNotificationCenter.current()
          center.removeAllDeliveredNotifications()
          let content = UNMutableNotificationContent()
          content.title = "Scanning OverflowArea beacons"
          content.body = ""
          content.categoryIdentifier = "low-priority"
          //let soundName = UNNotificationSoundName("silence.mp3")
          //content.sound = UNNotificationSound(named: soundName)
          let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
          center.add(request)
      }
  }
  @objc
  func stop(){
    advertiser = Advertiser(code: "")
    bleManager?.stop()
    //advertiser?.stop()
  }
}


class BLEManager: NSObject, CBCentralManagerDelegate {
  private var centralManager: CBCentralManager!
  var eventEmitter: RCTEventEmitter?
  
  init(eventEmitter: RCTEventEmitter) {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
    self.eventEmitter = eventEmitter
  }
  
  func start() {
    if centralManager.state == .poweredOn {
      centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
  }
  
  func stop() {
    centralManager.stopScan()
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
      //start()
    } else {
      // Handle Bluetooth not available or not authorized
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    if(peripheral.name != nil){
      eventEmitter?.sendEvent(withName: "deviceFound", body: peripheral.name ?? "");
    }
  }
}


class Advertiser: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager!
    private let serviceUUID = CBUUID(string: "169454ee-d633-11ed-afa1-0242ac120002")
    private let characteristicUUID = CBUUID(string: "169454ee-d633-11ed-afa1-0242ac120002")
    private var identifier: String = "SPOTLIVE:" // Aggiungi l'identifier qui
    
    init(code: String) {
        super.init()
        identifier.append(code)
        // Crea una coda di operazioni per eseguire le operazioni Bluetooth in background
        let options = [CBCentralManagerOptionShowPowerAlertKey: false,
                    CBCentralManagerOptionRestoreIdentifierKey: "com.spotlive.app.bluetooth"] as [String : Any]
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: options)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
      print(peripheralManager.isAdvertising)
      peripheral.removeAllServices()
        switch peripheral.state {
        case .poweredOn:
          print(peripheralManager.isAdvertising)
          if(!peripheralManager.isAdvertising){
            let characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: .read, value: nil, permissions: .readable)
            let service = CBMutableService(type: serviceUUID, primary: true)
            service.characteristics = [characteristic]
            peripheral.add(service)
            
              peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [self.serviceUUID], CBAdvertisementDataLocalNameKey: self.identifier])
            
            print(identifier)
          }
        case .poweredOff:
            print("Bluetooth spento")
        case .unsupported:
            print("Bluetooth non supportato")
        case .unauthorized:
            print("Autorizza il Bluetooth")
        default:
            break
        }
    }
    
    func stop() {
       // peripheralManager.stopAdvertising()
    }
  
  func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
    // Ripristina lo stato del servizio e delle caratteristiche
    /*if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
     for service in services {
     peripheral.add(service)
     }
     }*/
    
    // Ripristina l'annuncio
    if let advertisementData = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: Any] {
     peripheral.startAdvertising(advertisementData)
     }
  }

}
