//  GoogleNearbyMessages.swift
//  SpotMe
//
//  Created by Gabriele Romoli on 13/03/23.
//

import Foundation
import CoreBluetooth
import UserNotifications

@objc(NearbyMessages)
class NearbyMessages: RCTEventEmitter {
  override class func requiresMainQueueSetup() -> Bool {
          return true
      }
    private var bleManager: BLEManager?
    private var advertiser: Advertiser?
  
    override init() {
      super.init()
          bleManager = BLEManager()
          advertiser = Advertiser()
    }
  
    override func supportedEvents() -> [String]! {
        return ["deviceFound", "onActivityStart", "onActivityStop"]
    }
    @objc
  func start(){
    bleManager?.start()
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
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
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
        print(peripheral.name ?? "");
        sendEvent(withName: "deviceFound", body: peripheral.name);
      }
    }
  
    private func sendEvent(withName name: String, body: Any?) {
        DispatchQueue.main.async {
            self.sendEvent(withName: name, body: body)
        }
    }
}

class Advertiser: NSObject, CBPeripheralManagerDelegate {
  private var peripheralManager: CBPeripheralManager!
  private let serviceUUID = CBUUID(string: "169454ee-d633-11ed-afa1-0242ac120002")
  private let characteristicUUID = CBUUID(string: "169454ee-d633-11ed-afa1-0242ac120002")
  private let identifier = "SPOTLIVE:Altro-codice-utente" // Aggiungi l'identifier qui
  
  override init() {
    super.init()
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }
  
  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if peripheral.state == .poweredOn {
      let characteristic = CBMutableCharacteristic(type: characteristicUUID, properties: .read, value: nil, permissions: .readable)
      let service = CBMutableService(type: serviceUUID, primary: true)
      service.characteristics = [characteristic]
      peripheral.add(service)
      peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
                                      CBAdvertisementDataLocalNameKey: identifier]) // Utilizza l'identifier qui
    } else {
      // Handle Bluetooth not available or not authorized
    }

  }
  func stop() {
      peripheralManager.stopAdvertising()
  }
}
