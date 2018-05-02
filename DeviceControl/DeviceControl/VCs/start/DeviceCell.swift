//
//  DeviceCell.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 30/04/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class DeviceCell: UICollectionViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var pathLabel: UILabel!
	@IBOutlet weak var container: UIView!
	@IBOutlet weak var isOnLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		self.container.clipsToBounds = true
		self.container.layer.cornerRadius = 10

    }
	
	func setupCell(device: Device) {
		self.nameLabel.text = device.name
		self.iconView?.image = device.type.getIcon()
		self.pathLabel.text = "coap://\(device.hostname):\(device.port)/\(device.id)"
		self.isOnLabel.text = device.isOn ? "On" : "Off"
		self.stateLabel.text = device.state
	}
}
