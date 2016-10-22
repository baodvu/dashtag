//
//  RoutePreviewViewController.swift
//  dashtag
//
//  Created by Bao Vu on 10/21/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

class RoutePreviewViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        
        let camera = GMSCameraPosition.cameraWithLatitude(33.778351, longitude: -84.396695, zoom: 16.0)

        mapView.camera = camera
        mapView.myLocationEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
