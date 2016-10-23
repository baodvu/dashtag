//
//  RoutePreviewViewController.swift
//  dashtag
//
//  Created by Bao Vu on 10/21/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseAuth
import FirebaseDatabase

class RoutePreviewViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var numStopsLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var difficultyLevel = "default"
    var workoutDuration = 30
    var _numStops = 0
    var numStops: Int {
        get {
            return _numStops
        }
        set {
            _numStops = newValue
            numStopsLabel.text = "Number of stops: \(_numStops)"
        }
    }
    
    var _distance = 0.0
    var distance: Double {
        get {
            return _distance
        }
        set {
            _distance = newValue
            distanceLabel.text = "Distance: " + String(format: "%.1f", _distance) + " km"
        }
    }
    
    var _time: UInt = 0
    var time: UInt {
        get {
            return _time
        }
        set {
            _time = newValue
            let sec = _time % 60
            let min = time / 60
            timeLabel.text = "Time: \(min)m \(sec) s"
        }
    }

    @IBOutlet weak var mapView: GMSMapView!
    
    var ref: FIRDatabaseReference!
    var locations: [Location] = []
    var workouts: [Workout] = []
    var locationManager: CLLocationManager!
    var currentLocation: CLLocationCoordinate2D!
    
    var originMarker: GMSMarker!
    
    var destinationMarker: GMSMarker!
    
    var routePolyline: GMSPolyline!
    
    let mapTasks = MapTasks()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        
        let camera = GMSCameraPosition.cameraWithLatitude(33.778351, longitude: -80.396695, zoom: 16.0)
        
        mapView.camera = camera
        mapView.myLocationEnabled = true
        
        print("Fetching data")
        ref.child("locations").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            print("location data count: " + "\(snapshot.childrenCount)")
            for child in snapshot.children.allObjects as! [FIRDataSnapshot] {
                let title = child.value!["title"] as? String
                let owner = child.value!["owner"] as? String
                let info = child.value!["info"] as? String
                let latitude = child.value!["latitude"] as? Double
                let longitude = child.value!["longitude"] as? Double
                let type = child.value!["type"] as? Int
                self.locations.append(Location(title: title!, owner: owner!, info: info!, latitude: latitude!, longitude: longitude!, type: type!))
            }
            
            print(self.locations.count)
            
            self.updatePath(1)
        }) { (error) in
            print(error.localizedDescription)
        }
        
        ref.child("workouts/\(difficultyLevel)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            print("workout data count: " + "\(snapshot.childrenCount)")
            for child in snapshot.children.allObjects as! [FIRDataSnapshot] {
                let name = child.value!["name"] as! String
                let instructions = child.value!["instructions"] as! String
                let reps = child.value!["reps"] as! Int
                let sets = child.value!["sets"] as! Int
                let time = child.value!["time"] as! Int
                self.workouts.append(Workout(name: name, instructions: instructions, reps: reps, sets: sets, time: time))
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        
        print("Difficulty: \(difficultyLevel)")
        print("Duration: \(workoutDuration)")
    }
    
    func updatePath(wayPointCount: Int) -> Void {
        let origin = cord2str(self.currentLocation)
        let destination = cord2str(self.currentLocation)
        
        var waypoints: [String] = []
        
        var markers = [GMSMarker(position: self.currentLocation)]
        
        var index = 0
        var workoutTime: Int = 0
        for location in self.locations[0..<wayPointCount] {
            // Pick a random workout
            let randomWorkout = self.workouts[Int(arc4random_uniform(UInt32(self.workouts.count)))]
            
            let w = GMSMarker(position: CLLocationCoordinate2DMake(location.latitude, location.longitude))
            w.title = location.title
            w.snippet = "Task: \(randomWorkout.name) (\(randomWorkout.reps) reps, \(randomWorkout.sets) sets)" + "\n\nInfo: " + location.info
            w.icon = getLabelImage("\(index+1)")
            waypoints.append(marker2str(w))
            markers.append(w)
            
            workoutTime += randomWorkout.time
            
            index = index + 1
        }
        
        var bounds = GMSCoordinateBounds();
        for m in markers {
            bounds = bounds.includingCoordinate(m.position);
        }
        
        self.mapView.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds))
        
        self.mapTasks.getDirections(origin, destination: destination, waypoints: waypoints, travelMode: nil, completionHandler: { (status, success) -> Void in
            if success {
                if (Double(self.getTotalTime(workoutTime)) < Double(self.workoutDuration)*0.9 && wayPointCount < self.locations.count) {
                    self.updatePath(wayPointCount + 1)
                } else {
                    for m in markers {
                        m.map = self.mapView
                    }
                    self.drawRoute()
                    self.displayRouteInfo(workoutTime)
                    self.numStops = wayPointCount
                }
            }
            else {
                print(status)
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        determineMyCurrentLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        manager.stopUpdatingLocation()
        
        currentLocation = userLocation.coordinate
        
        print(currentLocation.latitude)
        print(currentLocation.longitude)
        
        currentLocation.latitude = 33.777355
        currentLocation.longitude = -84.398037
        
        updateMap()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error \(error)")
    }
    
    func updateMap() {
        let camera = GMSCameraPosition.cameraWithLatitude(currentLocation.latitude, longitude: currentLocation.longitude, zoom: 16.0)
        mapView.camera = camera
        
        let marker = GMSMarker(position: currentLocation)
        marker.title = "I'm here"
        marker.map = mapView
    }
    
    func drawRoute() {
        let route = mapTasks.overviewPolyline["points"] as! String
        
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline = GMSPolyline(path: path)
        routePolyline.strokeColor = UIColor.init(red: 255/255, green: 150/255, blue: 0, alpha: 0.75)
        routePolyline.strokeWidth = 4.0
        routePolyline.map = mapView
    }
    
    func getTotalTime(workoutTime: Int) -> UInt {
        return mapTasks.totalDurationInSeconds / 2 + UInt(workoutTime)
    }
    
    func displayRouteInfo(workoutTime: Int) {
        print(mapTasks.totalDistance + "\n" + mapTasks.totalDuration)
        self.distance = Double(mapTasks.totalDistanceInMeters) / 1000
        print("Workout Time: \(workoutTime)s")
        print("Running Time: \(mapTasks.totalDurationInSeconds / 2)s")
        self.time = getTotalTime(workoutTime)
    }
}

func marker2str(loc : GMSMarker) -> String {
    return "\(loc.position.latitude),\(loc.position.longitude)"
}

func cord2str(loc : CLLocationCoordinate2D) -> String {
    return "\(loc.latitude),\(loc.longitude)"
}

func getLabelImage(str: String) -> UIImage? {
        
    //grab it
    let image = UIImage(named: "MapMarker")!
    UIGraphicsBeginImageContext(image.size)
    image.drawInRect(CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    
    //setup label
    let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: image.size.width, height: 35))
    label.text = str
    label.textAlignment = .Center
    label.font = label.font.fontWithSize(10)
    label.textColor = UIColor.blackColor()
    label.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    
    let icon = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    
    return icon;
}
