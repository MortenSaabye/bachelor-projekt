//
//  DataController.swift
//  DeviceControl
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation
import Alamofire

protocol WiFiDelegate {
    func didReceiveNetworkInfo(sender: WiFiManager, networks: [WiFiNetwork])
    func didConnectToNetwork(sender: WiFiManager, success: Bool, error: String?)
}

class WiFiManager {
    let baseURL: String = "http://Mortens-MacBook-Pro-Praktik.local:3000/"
    var delegate: WiFiDelegate?
    static let shared: WiFiManager = WiFiManager()
    func getAvailableWifi() {
        Alamofire.request("\(baseURL)getwifiinfo").validate().responseJSON { [weak self] (response) in
            guard let safeSelf = self else {
                print("DataController has been deallocated")
                return
            }
            guard let JSONValue = response.result.value as? [String: Any],
                let networksJSON = JSONValue["resultData"] as? [[String: Any]] else {
                print("Could not get JSON")
                return
            }
            var networks: [WiFiNetwork] = [WiFiNetwork]()
            for network in networksJSON {
                if let wifiNetwork = WiFiNetwork(dict: network) {
                    networks.append(wifiNetwork)
                }
            }
            
            safeSelf.delegate?.didReceiveNetworkInfo(sender: safeSelf, networks: networks)
        }
    }
    
    func connectToWiFi(network: WiFiNetwork) {
        let parameters: Parameters = [
            "ssid": network.ssid,
            "passcode": network.passcode ?? "NO PASSCODE"
        ]
        Alamofire.request("\(baseURL)connect", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { [weak self] (response) in
            guard let safeSelf = self else {
                print("DataController has been deallocated")
                return
            }
            guard let JSONValue = response.result.value as? [String: Any],
                let success = JSONValue["success"] as? Bool else {
                    print("Could not get JSON")
                    return
            }
            safeSelf.delegate?.didConnectToNetwork(sender: safeSelf, success: success, error: JSONValue["errormessage"] as? String ?? "")
        }
    }
    
    init(){}
    
}


struct WiFiNetwork {
    let ssid: String
    let signalStrength: String
    let isSecured: Bool
    var passcode: String?
    init?(dict: [String: Any]) {
        guard let signal = dict["signal_level"] as? String, let ssid = dict["ssid"] as? String, let security = dict["security"] as? String else {
            print("Deserialization error")
            return nil
        }
        self.signalStrength = signal
        self.ssid = ssid
        self.isSecured = security == "none" ? false : true
    }
}
