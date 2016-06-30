//
//  MBPeripheralController.swift
//  MBBLEDataExchange
//
//  Created by Amit on 15/06/16.
//  Copyright © 2016 Mindbowser. All rights reserved.
//

import UIKit
import CoreBluetooth
class MBPeripheralController: UIViewController,CBPeripheralManagerDelegate, UITextViewDelegate
{
    var peripheralManager:CBPeripheralManager?
    var transferedCharacteristic:CBMutableCharacteristic?
    var pendingData:NSData?
    var sendDataIndex:NSInteger?
    @IBOutlet var textview:UITextView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        peripheralManager = CBPeripheralManager()
        peripheralManager = CBPeripheralManager(delegate: self, queue:nil)
    }
    
    //Mark: CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if peripheral.state != .PoweredOn {
            return
        }
        if peripheral.state == .PoweredOn {
            transferedCharacteristic = CBMutableCharacteristic(type: CBUUID(string:Constants.CharacteristicsKey.kTransferCharacteristicUUID), properties: .Notify, value: nil, permissions: .Readable)
            let transferService: CBMutableService = CBMutableService(type: CBUUID(string:Constants.ServicesKey.kTransferServiceUUID), primary: true)
            transferService.characteristics = [transferedCharacteristic!]
            peripheralManager!.addService(transferService)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        pendingData = textview?.text.dataUsingEncoding(NSUTF8StringEncoding)
        sendDataIndex = 0
        sendData()
    }
    
    //Mark: Send Data to central device
    
    func sendData() {
        
        struct messageEnd {
            static var sendingEOM = false
        }
        
        if messageEnd.sendingEOM {
            
            let didsend:Bool = peripheralManager!.updateValue("MessageEnd".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: transferedCharacteristic!, onSubscribedCentrals: nil)
            if didsend {
                messageEnd.sendingEOM = false
            }
            return
        }
        // We're sending data
        // Is there any left to send?
        if sendDataIndex >= pendingData?.length {
            return
        }
        
        var dataDidsend:Bool = true
        while dataDidsend {
            var amountTosend:NSInteger = (pendingData?.length)! - sendDataIndex!
            if(amountTosend > Constants.kNotify) {
                amountTosend = Constants.kNotify
            }
            // Copy out the data we want
            let chunk:NSData = NSData(bytes: pendingData!.bytes + sendDataIndex!, length: amountTosend)
            dataDidsend = peripheralManager!.updateValue(chunk, forCharacteristic: transferedCharacteristic!, onSubscribedCentrals: nil)
            if !dataDidsend {
                return
            }
            let stringFromdata:String! = NSString(data: chunk, encoding: NSUTF8StringEncoding) as! String
            print("Sent data: \(stringFromdata)")
            
            sendDataIndex! += amountTosend;
            
            if sendDataIndex >= pendingData?.length {
                messageEnd.sendingEOM = true
                let messageEndSent:Bool = peripheralManager!.updateValue("MessageEnd".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: transferedCharacteristic!, onSubscribedCentrals: nil)
                if messageEndSent {
                    messageEnd.sendingEOM = false
                    print("MessageEnd")
                }
                return
            }
        }
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        
        sendData()
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?)
    {
        if (error != nil) {
            print("Error in adding service : \(error!.localizedDescription)")
            return
        }
        
        if (peripheralManager!.isAdvertising) {
            peripheralManager?.stopAdvertising()
        }
        peripheralManager!.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [CBUUID(string:Constants.ServicesKey.kTransferServiceUUID)]])
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if (error != nil) {
            print("error: \(error?.localizedDescription)")
            return
        }
        
        print("advertisedService for peripheral: \(peripheral)")
        
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
