//
//  SignalStrength.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 11/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit
import SnapKit

class SignalStrength: UIView {
	@IBOutlet var view: UIView!
	@IBOutlet weak var stackView: UIStackView!
	var signalLevel: CGFloat = 0.0 {
		didSet {
			self.internalInit()
		}
	}
	
	var maximum: CGFloat = -55
	var minimum: CGFloat = -100
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	
	func internalInit() {
		self.layoutSubviews()
		Bundle.main.loadNibNamed("SignalStrength", owner: self, options: nil)
		addSubview(view)
		view.frame = self.bounds
		view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		let bars = self.stackView.subviews
		let barValue = (maximum - minimum) / CGFloat(bars.count)
		let signalPoints: CGFloat = signalLevel - minimum
		let numberOfBars = Int(signalPoints / barValue) + 1
		let fullHeight = view.frame.height
		let multiplier = 1 / CGFloat(bars.count)
		var barNr = 1
		for bar in bars {
			let barMultiplier = CGFloat(barNr) * multiplier
			bar.snp.makeConstraints { (make) in
				make.height.equalTo(fullHeight * barMultiplier)
			}
			if barNr >= numberOfBars {
				bar.layer.borderWidth = 1
				bar.layer.borderColor = UIColor(named: "bulbasaur")?.cgColor
			} else {
				bar.backgroundColor = UIColor(named: "bulbasaur")
			}
			bar.layer.cornerRadius = 2
			barNr += 1
		}
		
	
		
	}
}
