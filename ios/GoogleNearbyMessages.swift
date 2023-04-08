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
    advertiser = Advertiser(code: "sianmviwiviiqiifnc")
    sendEvent(withName: "onActivityStart", body: nil)
  }
  
  @objc
  func stop(){
    bleManager?.stop()
    advertiser?.stop()
    sendEvent(withName: "onActivityStop", body: nil)
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
    identifier.append(code);
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }
  
  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if peripheral.state == .poweredOn {
      let characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: .read, value: nil, permissions: .readable)
      let service = CBMutableService(type: serviceUUID, primary: true)
      service.characteristics = [characteristic]
      peripheral.add(service)
      peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID], CBAdvertisementDataLocalNameKey: identifier])
      print(identifier);
    } else {
      // Handle Bluetooth not available or not authorized
    }

  }
  func stop() {
      peripheralManager.stopAdvertising()
  }
}
