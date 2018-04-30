//
//  StartVC.swift
//  Device Control
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class StartVC: UIViewController  {
	let devices = [Device]()
	@IBOutlet weak var deviceCollectionView: UICollectionView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Device Control"
        // Do any additional setup after loading the view.
        let setupBtn: UIBarButtonItem = UIBarButtonItem(title: "Setup", style: .plain, target: self, action: #selector(self.launchSetup))
        self.navigationItem.rightBarButtonItem = setupBtn
        let allServiceBtn: UIBarButtonItem = UIBarButtonItem(title: "All services", style: .plain, target: self, action: #selector(self.browseAllServices))
        self.navigationItem.leftBarButtonItem = allServiceBtn
		self.deviceCollectionView.register(UINib(nibName: "DeviceCell", bundle: nil), forCellWithReuseIdentifier: "DEVICE_CELL")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    @objc func launchSetup() {
        let setupVC = DeviceSetupVC()
        self.present(setupVC, animated: true)
    }
    
    @objc func browseAllServices() {
        let browseVC = AllServicesTCV()
        self.navigationController?.pushViewController(browseVC, animated: true)
    }
    
}

extension StartVC: UICollectionViewDataSource, UICollectionViewDelegate {
	
}


class Device {
	init(type: String, resourcePath: String, name: String) {
		self.name = name
		self.resourcePath = resourcePath
		self.type = DeviceType.typeFromString(string: type)
	}
	let type: DeviceType
	let resourcePath: String
	let name: String
}

enum DeviceType {
	case Light
	case Screen
	case Other
	
	static func typeFromString(string: String) -> DeviceType {
		switch string {
		case "light":
			return self.Light
		case "screen":
			return self.Screen
		default:
			return self.Other
		}
	}
	
}

