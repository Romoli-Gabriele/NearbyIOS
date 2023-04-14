import Foundation
import CoreBluetooth
import UserNotifications

@objc(NearbyMessages)
class NearbyMessages: RCTEventEmitter {
  private var bleManager: BLEManager?
  private var advertiser: Advertiser?
  var eventEmitter: RCTEventEmitter?
  
  override class func requiresMainQueueSetup() -> Bool {
    return true
  }

  override init() {
    super.init()
    bleManager = BLEManager(eventEmitter: self)
    eventEmitter = self
  }
  
  override func supportedEvents() -> [String]! {
    return ["deviceFound", "onActivityStart", "onActivityStop"]
  }
  
  @objc
  func start(){
    bleManager?.start()
    advertiser = Advertiser(code: "gcyguiisdfgh")
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
    /*if let advertisementData = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: Any] {
     peripheral.startAdvertising(advertisementData)
     }*/
  }

}
