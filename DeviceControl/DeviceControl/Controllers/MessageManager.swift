//
//  MessageManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 05/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation

protocol MessageManagerDelegate {
	func didReceiveMessage(message: [String : Any], sender: MessageManager)
	func clientDidConnect(sender: MessageManager)
}

class MessageManager {
	var host: Host?
	var path: String?
	var payload: [String : Any]?
	var delegate: MessageManagerDelegate?
	
	func sendMessage(with payload: [String : Any], to host: Host, path pathComponent: String, confirmable: Bool = true) {
		//OVERRIDE THIS IN SUBCLASS
	}
	
	func sendMessage(to host: Host, path pathComponent: String) {
		//OVERRIDE THIS IN SUBCLASS
	}
	
	func sendMessage(with payload: Any, to host: Host, path pathComponent: String) {
		//OVERRIDE THIS IN SUBCLASS
	}
	
	
	init() {}
	
	func getJSONDataFrom(dict: [String : Any]) -> Data? {
		do {
			let payloadData = try JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
			return payloadData
		} catch {
			print(error)
		}
		return nil
	}
	
	func parseDataAndNotifyDelegate(payload: Data) {
		do {
			if let jsonDict = try JSONSerialization.jsonObject(with: payload, options: .allowFragments) as? [String : Any] {
				self.delegate?.didReceiveMessage(message: jsonDict, sender: self)
			}
		} catch {
			print(String(data: payload, encoding: .utf8) ?? error.localizedDescription)
		}
	}
	
	static func getMessageManager(delegate: MessageManagerDelegate) -> MessageManager {
		var manager: MessageManager
		if WiFiManager.shared.isAtHome {
			manager = CoAPManager.shared
		} else {
			manager = MQTTManager.shared
		}
		manager.delegate = delegate
		return manager
	}
	
	static func reconnect() {
		MQTTManager.shared.loadServerInfo()
		CoAPManager.shared = CoAPManager()
	}
}
