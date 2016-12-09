//
//  MainViewController.swift
//  ShadowVPN
//
//  Created by clowwindy on 8/6/15.
//  Copyright © 2015 clowwindy. All rights reserved.
//

import UIKit
import NetworkExtension

let kTunnelProviderBundle = "clowwindy.ShadowVPN.tunnel"

class MainViewController: UITableViewController {
    
    var vpnManagers = [NETunnelProviderManager]()
    var currentVPNManager: NETunnelProviderManager?
    var vpnStatusSwitch = UISwitch()
    var vpnStatusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ShadowVPN"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MainViewController.addConfiguration))
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.VPNStatusDidChange(_:)), name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
        vpnStatusSwitch.addTarget(self, action: #selector(MainViewController.vpnStatusSwitchValueDidChange(_:)), for: .valueChanged)
//        vpnStatusLabel.textAlignment = .Right
//        vpnStatusLabel.textColor = UIColor.grayColor()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NEVPNStatusDidChange, object: nil)
    }
    
    func vpnStatusSwitchValueDidChange(_ sender: UISwitch) {
        do {
            if vpnManagers.count > 0 {
                if let currentVPNManager = self.currentVPNManager {
                    if sender.isOn {
                        try currentVPNManager.connection.startVPNTunnel()
                    } else {
                        currentVPNManager.connection.stopVPNTunnel()
                    }
                }
            }
        } catch {
            NSLog("%@", String(describing: error))
        }
    }

    func VPNStatusDidChange(_ notification: Notification?) {
        var on = false
        var enabled = false
        if let currentVPNManager = self.currentVPNManager {
            let status = currentVPNManager.connection.status
            switch status {
            case .connecting:
                on = true
                enabled = false
                vpnStatusLabel.text = "Connecting..."
                break
            case .connected:
                on = true
                enabled = true
                vpnStatusLabel.text = "Connected"
                break
            case .disconnecting:
                on = false
                enabled = false
                vpnStatusLabel.text = "Disconnecting..."
                break
            case .disconnected:
                on = false
                enabled = true
                vpnStatusLabel.text = "Not Connected"
                break
            default:
                on = false
                enabled = true
                break
            }
            vpnStatusSwitch.isOn = on
            vpnStatusSwitch.isEnabled = enabled
            UIApplication.shared.isNetworkActivityIndicatorVisible = !enabled
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadConfigurationFromSystem()
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "status")
            cell.selectionStyle = .none
            cell.textLabel?.text = "Status"
            vpnStatusLabel = cell.detailTextLabel!
            cell.accessoryView = vpnStatusSwitch
            return cell
        } else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "configuration")
            let vpnManager = self.vpnManagers[indexPath.row]
            cell.textLabel?.text = vpnManager.protocolConfiguration?.serverAddress
            cell.detailTextLabel?.text = (vpnManager.protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration!["description"] as? String
            if vpnManager.isEnabled {
                cell.imageView?.image = UIImage(named: "checkmark")
            } else {
                cell.imageView?.image = UIImage(named: "checkmark_empty")
            }
            cell.accessoryType = .detailButton
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            let vpnManager = self.vpnManagers[indexPath.row]
            vpnManager.isEnabled = true
            vpnManager.saveToPreferences { (error) -> Void in
                self.loadConfigurationFromSystem()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.vpnManagers.count
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let configurationController = ConfigurationViewController(style:.grouped)
        configurationController.providerManager = self.vpnManagers[indexPath.row]
        self.navigationController?.pushViewController(configurationController, animated: true)
    }
    
    func addConfiguration() {
        let manager = NETunnelProviderManager()
        manager.loadFromPreferences { (error) -> Void in
            let providerProtocol = NETunnelProviderProtocol()
            providerProtocol.providerBundleIdentifier = kTunnelProviderBundle
            providerProtocol.providerConfiguration = [String: AnyObject]()
            manager.protocolConfiguration = providerProtocol
            
            let configurationController = ConfigurationViewController(style:.grouped)
            configurationController.providerManager = manager
            self.navigationController?.pushViewController(configurationController, animated: true)
            manager.saveToPreferences(completionHandler: { (error) -> Void in
                print(error)
            })
        }
    }
    
    func loadConfigurationFromSystem() {
        NETunnelProviderManager.loadAllFromPreferences() { newManagers, error in
            print(error)
            guard let vpnManagers = newManagers else { return }
            self.vpnManagers.removeAll()
            for vpnManager in vpnManagers {
                if let providerProtocol = vpnManager.protocolConfiguration as? NETunnelProviderProtocol {
                    if providerProtocol.providerBundleIdentifier == kTunnelProviderBundle {
                        if vpnManager.isEnabled {
                            self.currentVPNManager = vpnManager
                        }
                        self.vpnManagers.append(vpnManager)
                    }
                }
            }
            self.vpnStatusSwitch.isEnabled = vpnManagers.count > 0
            self.tableView.reloadData()
            self.VPNStatusDidChange(nil)
        }
    }

}
