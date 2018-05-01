//
//  AddDeviceCell.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 01/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class AddDeviceCell: UITableViewCell {
	var device: Device? {
		didSet {
			self.namelabel.text = device?.name
			self.imageView?.image = device?.type.getIcon()
		}
	}

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var namelabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
	override func prepareForReuse() {
		self.iconView = nil
		self.device = nil
	}

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
	@IBAction func testButton(_ sender: Any) {
		guard let device = self.device else {
			print("No device")
			return
		}
		CoAPManager.shared.testDevice(device: device)
	}
}
