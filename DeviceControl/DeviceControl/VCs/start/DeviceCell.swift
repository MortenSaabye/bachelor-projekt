//
//  DeviceCell.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 30/04/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class DeviceCell: UICollectionViewCell, UITextFieldDelegate {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var pathLabel: UILabel!
	@IBOutlet weak var container: UIView!
	@IBOutlet weak var isOnLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var stateTextfield: UITextField!
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		self.container.clipsToBounds = true
		self.container.layer.cornerRadius = 10
    }
	var deviceId: Int?
	
	func setupCell(device: Device) {
		self.nameLabel.text = device.name
		self.iconView?.image = device.type.getIcon()
		self.pathLabel.text = "coap://\(device.host.hostName):\(device.host.port)/\(device.id)"
		self.stateLabel.text = device.state
		self.deviceId = device.id
		if !device.isConnected {
			self.setNotConnected()
		} else {
			self.isOnLabel.text = device.isOn ? "On" : "Off"
			self.setConnected()
		}
		if device.type != .Screen {
			self.stateTextfield.isHidden = true
		} else {
			self.stateTextfield.isHidden = false
			self.stateTextfield.delegate = self
			self.stateTextfield.text = ""
		}
		
	}
	
	func setNotConnected() {
		self.isOnLabel.text = "No connection"
		self.container.backgroundColor = UIColor(named: "blueSky")?.withAlphaComponent(0.2)
		self.nameLabel.textColor = .darkGray
		self.stateLabel.textColor = .darkGray
		self.isOnLabel.textColor = .darkGray
	}
	
	func setConnected() {
		self.container.backgroundColor = UIColor(named: "blueSky")?.withAlphaComponent(0.4)
		self.nameLabel.textColor = .black
		self.stateLabel.textColor = .black
		self.isOnLabel.textColor = .black
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let device = DeviceManager.shared.devices.first { (device) -> Bool in
			device.id == self.deviceId
		}
		if let newState = textField.text {
			device?.state = newState
		}
		textField.resignFirstResponder()
		return true
	}
}
