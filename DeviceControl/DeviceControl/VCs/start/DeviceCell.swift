//
//  DeviceCell.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 30/04/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

protocol DeviceCellDelegate {
	func willUpdateCell(sender: DeviceCell)
}

class DeviceCell: UICollectionViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var container: UIView!
	@IBOutlet weak var isOnLabel: UILabel!
	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var updateSpinner: UIActivityIndicatorView!
	var delegate: DeviceCellDelegate?
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		self.container.clipsToBounds = true
		self.container.layer.cornerRadius = 10
		self.brightnessSlider.addTarget(self, action: #selector(self.brightnessChanged), for: .valueChanged)
    }
	var deviceId: Int?
	func setupCell(device: Device) {
		let gesture = UILongPressGestureRecognizer(target: self, action: #selector(self.removeDevice))
		self.container.addGestureRecognizer(gesture)
		self.nameLabel.text = device.name
		self.iconView?.image = device.getIcon()
		self.brightnessSlider.value = Float(device.brightness)
		self.deviceId = device.id
		if !device.isConnected {
			self.setNotConnected()
		} else {
			if device.on {
				self.isOnLabel.text =  "On"
				self.brightnessSlider.isEnabled = true

			} else {
				self.brightnessSlider.isEnabled = false
				self.isOnLabel.text =  "Off"
			}
			self.setConnected(colorString: device.color)
		}
		if device.isUpdating {
			updateSpinner.startAnimating()
		} else {
			updateSpinner.stopAnimating()
		}
	}
	
	
	@objc func removeDevice(device: Device) {
		if let id = self.deviceId {
			DeviceManager.shared.removeDevice(id: id)
		}
	}
	
	func setNotConnected() {
		self.isOnLabel.text = "No connection"
		self.container.backgroundColor = UIColor(named: "blueSky")?.withAlphaComponent(0.2)
		self.nameLabel.textColor = .darkGray
		self.isOnLabel.textColor = .darkGray
	}
	
	func setConnected(colorString: String) {
		let color: UIColor?
		if !colorString.isEmpty {
			color = UIColor(hexString: colorString)
		} else {
			color = UIColor(named: "blueSky")
		}
		self.container.backgroundColor = color?.withAlphaComponent(0.4)
		self.brightnessSlider.tintColor = color
		self.nameLabel.textColor = .black
		self.isOnLabel.textColor = .black
	}
	
	@objc func brightnessChanged() {
		guard let id = self.deviceId else {
			print("no device id")
			return
		}
		let brightness = self.brightnessSlider.value
		DeviceManager.shared.changeBrightness(deviceId: id, brightness: Int(brightness))
		self.delegate?.willUpdateCell(sender: self)
	}
}
