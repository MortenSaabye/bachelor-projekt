//
//  AllServicesTCV.swift
//  
//
//  Created by Morten Saabye on 4/23/18.
//

import UIKit


class AllServicesTCV: UITableViewController {
    let SERVICE_CELL_IDENTIFIER: String = "SERVICE_CELL"
	let CELL_HEIGHT: CGFloat = 80
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "All services"
        self.serviceBrowser.delegate = self
        self.startBrowsing(all: true)
        self.tableView.register(UINib(nibName: "ServiceCell", bundle: nil), forCellReuseIdentifier: SERVICE_CELL_IDENTIFIER)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    let searchForAllString = "_services._dns-sd._udp."
    
    var services = [NetService](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    private lazy var serviceBrowser = NetServiceBrowser()

    func startBrowsing(all: Bool){
        self.serviceBrowser.stop()
        self.services = []
        self.serviceBrowser.delegate = self
        if all {
            self.serviceBrowser.searchForServices(ofType: searchForAllString, inDomain: "local")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.services.count
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
        let service = self.services[indexPath.row]
        cell.infoLabel.text = "Name: \(service.name)\nDomain: \(service.domain)\nPort: \(service.port)"
        return cell
    }
}


extension AllServicesTCV: NetServiceBrowserDelegate, NetServiceDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("Error serching for service")
        print("Errors: \(errorDict.keys)\n")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        self.services.append(service)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        service.delegate = nil
        self.removeServiceFromList(serviceObj: service)
    }
	
    func removeServiceFromList(serviceObj: NetService){
        for (index, sev) in self.services.enumerated() {
            if sev == serviceObj {
                self.services.remove(at: index)
            }
        }
    }
    
}
