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
    let baseURL: String = "http://raspberry.local:3000/"
    var delegate: WiFiDelegate?
    static let shared: WiFiManager = WiFiManager()
    func getAvailableWifi() {
        Alamofire.request("\(baseURL)getwifiinfo").validate().responseJSON { [weak self] (response) in
            guard let safeSelf = self else {
                print("DataController has been deallocated")
                return
            }
            guard let JSONValue = response.result.value as? [String: Any],
                let networksJSON = JSONValue["resultData"] as? String else {
                print("Could not get JSON")
                return
            }
			let networkStringArray = networksJSON.components(separatedBy: "Cell")
			var networks: [WiFiNetwork] = [WiFiNetwork]()
            for network in networkStringArray {
                if let wifiNetwork = WiFiNetwork(string: network) {
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
	init?(string: String) {
		var ssid: String?
		var signalStrength: String?
		var isSecured: Bool?
		let components = string.components(separatedBy: "\n")
		for component in components {
			let trimmedComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
			if trimmedComponent.hasPrefix("ESSID") {
				ssid = trimmedComponent.components(separatedBy: ":")[1].trimmingCharacters(in: .punctuationCharacters)
			}
			if trimmedComponent.hasPrefix("Quality") {
				signalStrength = trimmedComponent.components(separatedBy: "=")[2]
			}
			if trimmedComponent.hasPrefix("Encryption key") {
				if trimmedComponent.hasSuffix("on") {
					isSecured = true
				} else {
					isSecured = false
				}
			}
		}
		if let ssid_ = ssid, let isSecured_ = isSecured, let signalStrength_ = signalStrength {
			self.ssid = ssid_
			self.isSecured = isSecured_
			self.signalStrength = signalStrength_
		} else {
			return nil
		}
	}
}
