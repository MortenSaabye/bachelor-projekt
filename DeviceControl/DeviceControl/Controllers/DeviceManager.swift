//
//  DeviceManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 02/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation
import UIKit

protocol AddDevicesDelegate {
	var service: NetService? { get set }
	func didReceiveDevicesFromService(sender: DeviceManager, devices: [Device])
}

protocol DeviceManagerDelegate {
	func didUpdateDevice(device: Device, index: Int, sender: DeviceManager)
	func didRemoveDevice(at index: Int, sender: DeviceManager)
	func pollingDidTimeout(sender: DeviceManager)
}

class DeviceManager  {
	var devices = [Device]()
	let LOCALDEVICES_FILENAME: String = "local-devices"
	static let shared: DeviceManager = DeviceManager()
	var addDevicesDelegate: AddDevicesDelegate?
	var delegate: DeviceManagerDelegate?
	var pollTimer: Timer?
	var pollTimeoutTimer: Timer?
	let POLLRATE: Double = 10
	func loadDevices() {
		do {
			let fileToGet = try self.getFileUrl()
			let deviceData = try Data(contentsOf: fileToGet)
			guard let devices = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? [Device] else {
				print("Could not get devices")
				return
			}
			print("loaded \(devices.count) devices")
			self.devices = devices
		} catch {
			print(error)
		}
	}
	
	func updateStateFor(device: Device, confirmable: Bool = true) {
		var payload = [String: Any]()
		payload["on"] = device.on
		payload["id"] = device.id
		payload["color"] = device.color
		payload["brightness"] = device.brightness
		let messageManager = MessageManager.getMessageManager(delegate: self)
		messageManager.sendMessage(with: payload, to: device.host, path: "\(device.id)/state", confirmable: confirmable)
	}
	
	func changeBrightness(deviceId: Int, brightness: Int) {
		guard let device = self.getDeviceFrom(id: deviceId) else {
			print("no device")
			return
		}
		device.brightness = brightness
		self.updateStateFor(device: device, confirmable: false)
	}
	
	func toggle(device: Device) {
		let deviceCopy = Device(device: device)
		deviceCopy.on = !device.on
		self.updateStateFor(device: deviceCopy)
	}
	
	func checkStateForLocalDevices() {
		let hosts = self.getListOfHosts()
		let messageManager = MessageManager.getMessageManager(delegate: self)
		for host in hosts {
			var payload = [String]()
			for device in DeviceManager.shared.devices {
				if device.host == host {
					payload.append(String(device.id))
				}
			}
			messageManager.sendMessage(with: payload, to: host, path: "state")
		}
	}
	
	func getListOfHosts() -> [Host] {
		var hosts : [Host] = [Host]()
		for device in DeviceManager.shared.devices {
			var containsHost = false
			for host in hosts {
				if host == device.host {
					containsHost = true
					break
				}
			}
			if !containsHost {
				hosts.append(device.host)
			}
		}
		return hosts
	}
	
	func fetchDevicesFromService(service: NetService) {
		let messageManager: MessageManager =  MessageManager.getMessageManager(delegate: self)
		guard let hostname = service.hostName else {
			print("No hostname in Devicemanager")
			return
		}
		let host: Host = Host(port: service.port, hostName: hostname)
		messageManager.sendMessage(to: host, path: "devices")
	}
	
	func saveDevices() {
		do {
			let fileToSave = try self.getFileUrl()
			let deviceData = NSKeyedArchiver.archivedData(withRootObject: self.devices)
			try deviceData.write(to: fileToSave)
		} catch {
			print(error)
		}
	}
	
	func getFileUrl() throws -> URL {
		let fileManager = FileManager.default
		let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
		return documentDirectory.appendingPathComponent(self.LOCALDEVICES_FILENAME)
	}
	
	func deviceAdded(device: Device) -> Bool {
		for addedDevice in self.devices {
			if addedDevice.id == device.id && device.host == addedDevice.host {
				return true
			}
		}
		return false
	}
	
	func removeDevice(device: Device) {
		for addedDevice in self.devices {
			if addedDevice.id == device.id{
				if let index = self.devices.index(of: addedDevice) {
					self.devices.remove(at: index)
					self.delegate?.didRemoveDevice(at: index, sender: self)
				}
			}
		}
	}
	
	func removeDevice(id: Int) {
		for addedDevice in self.devices {
			if addedDevice.id == id {
				if let index = self.devices.index(of: addedDevice) {
					self.devices.remove(at: index)
					self.delegate?.didRemoveDevice(at: index, sender: self)
				}
			}
		}
	}
	
	func test(device: Device) {
		let messageManager: MessageManager = MessageManager.getMessageManager(delegate: self)
		messageManager.sendMessage(to: device.host, path: "\(device.id)/test")
	}
	
	func getDeviceFrom(id: Int) -> Device? {
		return self.devices.first(where: { (device) -> Bool in
			device.id == id
		})
	}
	
	func getIndexForDevice(device: Device) -> Int? {
		return self.devices.index(of: device)
	}
	
	func startPolling() {
		self.pollTimer = Timer.scheduledTimer(withTimeInterval: self.POLLRATE, repeats: true, block: { (timer) in
			self.pollTimeoutTimer = Timer.scheduledTimer(timeInterval: self.POLLRATE + 1, target: self, selector: #selector(self.pollingTimedout), userInfo: nil, repeats: false)
			self.checkStateForLocalDevices()
		})
	}
	
	func stopPolling() {
		self.pollTimer?.invalidate()
	}
	
	@objc func pollingTimedout() {
		for device in self.devices {
			device.isConnected = false
		}
		self.stopPolling()
		self.delegate?.pollingDidTimeout(sender: self)
		
	}
	
}

extension DeviceManager : MessageManagerDelegate {
	func clientDidConnect(sender: MessageManager) {
		self.checkStateForLocalDevices()
	}
	
	func didReceiveMessage(message: [String : Any], sender: MessageManager) {
		if let arr = message["devices"] as? [[String : Any]], let service = self.addDevicesDelegate?.service {
			var foundDevices = [Device]()
			for obj in arr {
				if let device = Device(dict: obj, service: service) {
					foundDevices.append(device)
				}
			}
			self.addDevicesDelegate?.didReceiveDevicesFromService(sender: self, devices: foundDevices)
		}
		if let dict = message["result"] as? [String : Any] {
			self.sendDeviceToDelegate(dict: dict)
		}
		if let arr = message["result"] as? [[String : Any]] {
			self.pollTimeoutTimer?.invalidate()
			for dict in arr {
				self.sendDeviceToDelegate(dict: dict)
			}
		}
	}
	
	

	func sendDeviceToDelegate(dict: [String: Any]) {
		if let id = dict["id"] as? Int,
		let device = self.getDeviceFrom(id: id),
		let on = dict["on"] as? Bool,
		let color = dict["color"] as? String,
		let brightness = dict["brightness"] as? Int,
		let index = self.getIndexForDevice(device: device) {
			var shouldUpdate = true
			if device.on == on && device.brightness == brightness && device.color == color && device.isConnected {
				shouldUpdate = false
			}
			device.isUpdating = false
			device.on = on
			device.isConnected = true
			device.brightness = brightness
			device.color = color
			if shouldUpdate {
				self.delegate?.didUpdateDevice(device: device, index: index, sender: self)
			}
		}
	}
}
