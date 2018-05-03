//
//  FooterView.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 03/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

protocol FooterDelegate {
	func presentMQTTView(sender: FooterView)
}


class FooterView: UICollectionReusableView {
	var delegate: FooterDelegate?
	@IBOutlet weak var button: UIButton!
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		self.button.layer.cornerRadius = 10
		self.button.layer.masksToBounds = true
    }
    
	@IBAction func buttonAction(_ sender: Any) {
		self.delegate?.presentMQTTView(sender: self)
	}
	
	override func prepareForReuse() {
		self.delegate = nil
	}
}
