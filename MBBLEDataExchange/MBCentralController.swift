//
//  MBCentralController.swift
//  MBBLEDataExchange
//
//  Created by Amit on 15/06/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

import UIKit
import CoreBluetooth

class MBCentralController: UIViewController,CBCentralManagerDelegate,CBPeripheralDelegate
{
    var centralManager:CBCentralManager!
    @IBOutlet var textview:UITextView?
    var discoveredPeripheral:CBPeripheral?
    var receivedData:NSMutableData = NSMutableData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        centralManager = CBCentralManager()
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue(), options:nil)
    }
    
    //Mark: CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager)
    {
        if central.state != .PoweredOn {
            return
        }
        else if central.state == .PoweredOn {
            centralManager.scanForPeripheralsWithServices([CBUUID(string:Constants.ServicesKey.kTransferServiceUUID)], options:[CBCentralManagerScanOptionAllowDuplicatesKey : false])
            print("Scanning Started")
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    {
        print("Discovered \(peripheral.name) at \(RSSI)")
        if discoveredPeripheral != peripheral {
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
            discoveredPeripheral = peripheral
            print("connecting to peripheral \(peripheral)")
            central.connectPeripheral(peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        print("Connected")
        centralManager.stopScan()
        receivedData.length = 0
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string:Constants.ServicesKey.kTransferServiceUUID)])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("failed to connect with error : \(error?.localizedDescription)")
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        discoveredPeripheral = nil
        centralManager.scanForPeripheralsWithServices([CBUUID(string:Constants.ServicesKey.kTransferServiceUUID)], options:[CBCentralManagerScanOptionAllowDuplicatesKey : false])
    }
    
    //Mark: CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if (error != nil) {
            print("error: \(error?.localizedDescription)")
            return
        }

        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string:Constants.CharacteristicsKey.kTransferCharacteristicUUID)], forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (error != nil) {
            print("error: \(error?.localizedDescription)")
            return
        }
        for characteristic in service.characteristics! {
            if characteristic.UUID.isEqual(CBUUID(string:Constants.CharacteristicsKey.kTransferCharacteristicUUID)) {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if (error != nil) {
            print("Error:\(error?.localizedDescription)")
            return
        }
        let stringFromdata = NSString(data:characteristic.value!, encoding:NSUTF8StringEncoding) as! String
        if stringFromdata == "MessageEnd" {
            
            textview?.text = NSString(data: receivedData, encoding: NSUTF8StringEncoding) as! String
            peripheral.setNotifyValue(false, forCharacteristic: characteristic)
            receivedData.length = 0
            centralManager.cancelPeripheralConnection(peripheral)
        }
        receivedData.appendData(characteristic.value!)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if !(characteristic.UUID.isEqual(CBUUID(string:Constants.CharacteristicsKey.kTransferCharacteristicUUID))){
            return
        }
        if characteristic.isNotifying {
            print("Notiication began on \(characteristic)")
        } else {
            //Notification has Stopped
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
