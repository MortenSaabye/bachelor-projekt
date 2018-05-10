//
//  CoAPManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 01/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation

class CoAPManager: MessageManager {
	var client: SCClient!
	static var shared: CoAPManager = CoAPManager()
	override init() {
		super.init()
		self.client = SCClient(delegate: self)
	}
	
	override func sendMessage(with payload: [String : Any], to host: Host, path pathComponent: String, confirmable: Bool = true) {
		guard let data = self.getJSONDataFrom(dict: payload) else {
			print("Could not get data")
			return
		}
		let type: SCType = confirmable ? .confirmable : .nonConfirmable
		let message = SCMessage(code: SCCodeValue(classValue: 0, detailValue: 03)!, type: type, payload: data)
		if let pathData = pathComponent.data(using: .utf8),
			let ipAddress = WiFiManager.getIPFromHostname(hostname: host.hostName) {
			message.addOption(SCOption.uriPath.rawValue, data: pathData)
			client.sendCoAPMessage(message, hostName: ipAddress, port: UInt16(host.port))
		}
	}
	
	override func sendMessage(to host: Host, path pathComponent: String) {
		let message = SCMessage(code: SCCodeValue(classValue: 0, detailValue: 01)!, type: .confirmable, payload: nil)
		if let pathData = pathComponent.data(using: .utf8),
			let ipAddress = WiFiManager.getIPFromHostname(hostname: host.hostName) {
			message.addOption(SCOption.uriPath.rawValue, data: pathData)
			client.sendCoAPMessage(message, hostName: ipAddress, port: UInt16(host.port))
		}
	}
	
	override func sendMessage(with payload: Any, to host: Host, path pathComponent: String) {
		let message = SCMessage(code: SCCodeValue(classValue: 0, detailValue: 03)!, type: .confirmable, payload: "\(payload)".data(using: .utf8))
		if let pathData = pathComponent.data(using: .utf8),
			let ipAddress = WiFiManager.getIPFromHostname(hostname: host.hostName) {
			message.addOption(SCOption.uriPath.rawValue, data: pathData)
			client.sendCoAPMessage(message, hostName: ipAddress, port: UInt16(host.port))
		}
	}
}

extension CoAPManager : SCClientDelegate {
	func swiftCoapClient(_ client: SCClient, didReceiveMessage message: SCMessage) {
		print("received message in manager")
		if message.type == .nonConfirmable {
			return
		}
		if let data = message.payload {
			self.parseDataAndNotifyDelegate(payload: data)
		}
	}
	
	func swiftCoapClient(_ client: SCClient, didFailWithError error: NSError) {
		print(error.localizedDescription)
	}
	
	func swiftCoapClient(_ client: SCClient, didSendMessage message: SCMessage, number: Int) {
		print("Message sent to: \(message.hostName ?? "no one")")
	}
}
