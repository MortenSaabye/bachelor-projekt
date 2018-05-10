//
//  DataController.swift
//  DeviceControl
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation
import Alamofire
import SystemConfiguration.CaptiveNetwork

protocol WiFiDelegate {
    func didReceiveNetworkInfo(sender: WiFiManager, networks: [WiFiNetwork])
    func didConnectToNetwork(sender: WiFiManager, success: Bool, error: String?)
}

class WiFiManager {
    let baseURL: String = "http://raspberry.local:3000/"
    var delegate: WiFiDelegate?
	let HOMENETWORK_KEY: String = "home-network"
    static let shared: WiFiManager = WiFiManager()
	var homeNetwork: String? {
		didSet {
			UserDefaults.standard.set(self.homeNetwork, forKey: HOMENETWORK_KEY)
		}
	}
	var isAtHome: Bool {
		get {
			return WiFiManager.getCurrentWiFi() == homeNetwork
		}
	}
    func getAvailableWifi() {
        Alamofire.request("\(baseURL)getwifiinfo").validate().responseJSON { [weak self] (response) in
            guard let safeSelf = self else {
                print("Wifimanager has been deallocated")
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
	
	static func getIPFromHostname(hostname: String) -> String? {
		let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
		CFHostStartInfoResolution(host, .addresses, nil)
		var success: DarwinBoolean = false
		if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray? {
			for address in addresses {
				guard let data = address as? NSData else {
					return nil
				}
				let inetAddress: sockaddr_in = data.castToCPointer()
				if inetAddress.sin_family == __uint8_t(AF_INET) {
					if let ip = String(cString: inet_ntoa(inetAddress.sin_addr), encoding: .ascii) {
						return(ip)
					}
				}
			}
		}
		return nil
	}
	
	static func getCurrentWiFi() -> String? {
		var ssid: String?
		if let interfaces = CNCopySupportedInterfaces() as NSArray? {
			for interface in interfaces {
				if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
					ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
					break
				}
			}
		}
		return ssid
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
			var success = true
			var errorMessage = ""
            if let JSONValue = response.result.value as? [String: Any],
			let success_ = JSONValue["success"] as? Bool,
			let errorMessage_ = JSONValue["errormessage"] as? String {
				success = success_
				errorMessage = errorMessage_
            }
			
            safeSelf.delegate?.didConnectToNetwork(sender: safeSelf, success: success, error:  errorMessage)
        }
    }
    init(){
		self.homeNetwork = UserDefaults.standard.string(forKey: HOMENETWORK_KEY)
	}
    
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

extension NSData {
	func castToCPointer<T>() -> T {
		let mem = UnsafeMutablePointer<T>.allocate(capacity: MemoryLayout<T.Type>.size)
		self.getBytes(mem, length: MemoryLayout<T.Type>.size)
		return mem.move()
	}
}
