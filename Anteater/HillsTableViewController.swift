//
//  HillsTableViewController.swift
//  Anteater
//
//  Created by Justin Anderson on 8/3/16.
//  Copyright © 2016 MIT. All rights reserved.
//

import UIKit

class HillsTableViewController: UITableViewController, SensorModelDelegate {

    var hills: [Hill] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SensorModel.shared.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - SensorModel delegation
    
    func sensorModel(_ model: SensorModel, didChangeActiveHill hill: Hill?) {
        if let hill = hill {
            hills = [hill]
        }
        self.tableView.reloadData()
    }
    
    func sensorModel(_ model: SensorModel, didReceiveReadings readings: [Reading], forHill hill: Hill?) {
        if let hill = hill {
            hills = [hill]
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let hill = SensorModel.shared.activeHill {
            return 1 + hill.readings.count
        } else {
            return 1
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let hill = SensorModel.shared.activeHill else {
            return tableView.dequeueReusableCell(withIdentifier: "noConnCell", for: indexPath)
        }
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "plotCell", for: indexPath)
            cell.imageView?.image = #imageLiteral(resourceName: "anteater-logo")
            cell.textLabel?.text = "\(hill.name) - \(hill.readings.count) readings"
            return cell
        default:
            let reading = hill.readings.reversed()[indexPath.row - 1]
            let cell = tableView.dequeueReusableCell(withIdentifier: "sensorCell", for: indexPath)
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short

            cell.textLabel?.text = "\(reading)"
            cell.detailTextLabel?.text = formatter.string(from: reading.date)
            switch reading.type {
            case .Temperature:
                cell.imageView?.image = #imageLiteral(resourceName: "thermo")
            case .Humidity:
                cell.imageView?.image = #imageLiteral(resourceName: "humidity")
            default:
                break
            }
            
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            // Push Core Plot graph
            let vc = SensorDataPlotViewController(hill: SensorModel.shared.activeHill)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
