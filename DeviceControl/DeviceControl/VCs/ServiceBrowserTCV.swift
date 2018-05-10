//
//  AllServicesTCV.swift
//  
//
//  Created by Morten Saabye on 4/23/18.
//

import UIKit


class ServiceBrowserTCV: UITableViewController {
    let SERVICE_CELL_IDENTIFIER: String = "SERVICE_CELL"
	let CELL_HEIGHT: CGFloat = 80
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Gateways"
		let closeBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closeServiceBrowser))
		self.navigationItem.rightBarButtonItem = closeBtn
        self.serviceBrowser.delegate = self
        self.startBrowsing()
        self.tableView.register(UINib(nibName: "ServiceCell", bundle: nil), forCellReuseIdentifier: SERVICE_CELL_IDENTIFIER)
    }

	var serviceType: ServiceType = .deviceControl
    var services = [NetService]()
	
	var resolvedServices = [NetService]() {
		didSet {
			self.tableView.reloadData()
		}
	}
	
	@objc func closeServiceBrowser() {
		self.dismiss(animated: true, completion: nil)
	}
    
	let serviceBrowser = NetServiceBrowser()

    func startBrowsing(){
        self.serviceBrowser.stop()
        self.services = []
        self.serviceBrowser.delegate = self
		self.serviceBrowser.searchForServices(ofType: serviceType.rawValue, inDomain: "local")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resolvedServices.count
    }
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return CELL_HEIGHT
	}
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SERVICE_CELL_IDENTIFIER) as? ServiceCell else {
            return UITableViewCell()
        }
        
        guard self.services.count > 0 || self.services.count >= indexPath.row else {
            return cell
        }
		
        let service = self.resolvedServices[indexPath.row]
        cell.infoLabel.text = "Name: \(service.name)\nDomain: \(service.domain)\nPort: \(service.port)"
        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let deviceBrowser = AddDevicesTVC()
		deviceBrowser.service = self.resolvedServices[indexPath.row]
		self.navigationController?.pushViewController(deviceBrowser, animated: true)
	}
}


extension ServiceBrowserTCV: NetServiceBrowserDelegate, NetServiceDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("Error serching for service")
        print("Errors: \(errorDict.keys)\n")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
		self.services.append(service)
		service.resolve(withTimeout: 5000)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        service.delegate = nil
        self.removeServiceFromList(serviceObj: service)
    }
	
	func netServiceDidResolveAddress(_ sender: NetService) {
		self.resolvedServices.append(sender)
	}
	
	func netServiceDidStop(_ sender: NetService) {
		print("found")
	}
	
	func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
		print("wrong")
	}
	
    func removeServiceFromList(serviceObj: NetService){
        for (index, sev) in self.services.enumerated() {
            if sev == serviceObj {
                self.services.remove(at: index)
            }
        }
    }
}

enum ServiceType : String {
	case deviceControl = "_devicecontrol._udp"
	case IKEA = "_coap._udp"
}
