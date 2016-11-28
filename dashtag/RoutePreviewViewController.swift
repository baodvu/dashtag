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
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    
    var timer = NSTimer()
    var countdownTimer = NSTimer()
    
    var timerRunning = false
    
    var difficultyLevel = "default"
    var workoutDuration = 30
    var _numStops = 0
    var numStops: Int {
        get {
            return _numStops
        }
        set {
            _numStops = newValue
            numStopsLabel.text = "\(_numStops) stops"
        }
    }
    
    var _distance = 0.0
    var distance: Double {
        get {
            return _distance
        }
        set {
            _distance = newValue
            distanceLabel.text = String(format: "%.1f", _distance) + " km"
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
            timeLabel.text = "\(min):\(String(format: "%02d", sec))"
        }
    }

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var workoutView: UIView!
    @IBOutlet weak var locationDescScrollView: UIScrollView!
    
    var ref: FIRDatabaseReference!
    var locations: [Location] = []
    var workouts: [Workout] = []
    var markers: [GMSMarker] = []
    var sortedMarkers: [GMSMarker] = []
    var generatedLocations: [Location] = []
    var generatedWorkouts: [Workout] = []
    var locationManager: CLLocationManager!
    var currentLocation: CLLocationCoordinate2D!
    
    var originMarker: GMSMarker!
    
    var destinationMarker: GMSMarker!
    
    var routePolyline: GMSPolyline!
    
    let mapTasks = MapTasks()
    
    var loaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = workoutView.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            workoutView.insertSubview(blurEffectView, atIndex: 0) //if you have more UIViews, use an insertSubview API to place it where needed
        }
        
        workoutView.hidden = true
    }
    
    func setUp() {
        if loaded {
            return
        }
        loaded = true
        
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        
        testIndex = 0
        
        let camera = GMSCameraPosition.cameraWithLatitude(33.778351, longitude: -80.396695, zoom: 16.0)
        mapView.camera = camera
        mapView.myLocationEnabled = true
        
        if (workouts.count == 0) {
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
        } else {
            self.updatePath(1)
        }
        
        if (locations.count == 0) {
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
                
                self.locations = self.locations.sort(self.sortLocations)
                self.updatePath(1)
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
        print("Difficulty: \(difficultyLevel)")
        print("Duration: \(workoutDuration)")
    }
    
    func updatePath(wayPointCount: Int) -> Void {
        let origin = cord2str(self.currentLocation)
        var waypoints = [String]()
        
        markers = [GMSMarker(position: self.currentLocation)]
        sortedMarkers = []
        
        generatedWorkouts.removeAll()
        
        var index = 0
        var workoutTime: Int = 0
        for location in self.locations[0..<wayPointCount] {
            // Pick a random workout
            let randomWorkout = self.workouts[Int(arc4random_uniform(UInt32(self.workouts.count)))]
            
            let w = GMSMarker(position: CLLocationCoordinate2DMake(location.latitude, location.longitude))
            w.title = location.title
            let task = (randomWorkout.reps == 0) ? " (\(randomWorkout.time) sec)" : " (\(randomWorkout.reps) reps, \(randomWorkout.sets) sets)"
            w.snippet = "Task: \(randomWorkout.name)\(task)" + "\n\nInfo: " + location.info
            waypoints.append(marker2str(w))
            markers.append(w)
            
            workoutTime += randomWorkout.time
            generatedWorkouts.append(randomWorkout)
            
            index = index + 1
        }
        
        let destination = waypoints.removeLast()
        
        self.mapTasks.getDirections(origin, destination: destination, waypoints: (waypoints.count == 0) ? nil : waypoints, travelMode: nil, completionHandler: { (status, success) -> Void in
            if success {
                if (Double(self.getTotalTime(workoutTime)) < Double(self.workoutDuration)*0.9 && wayPointCount < self.locations.count) {
                    self.updatePath(wayPointCount + 1)
                } else {
                    var i = 0
                    print("legs : \(self.mapTasks.legEnds)")
                    for l in self.mapTasks.legEnds {
                        for m in self.markers {
                            if (abs(l.latitude - m.position.latitude) < 0.001 && abs(l.longitude - m.position.longitude) < 0.001) {
                                m.map = self.mapView
                                m.icon = getLabelImage("\(i+1)")
                                self.sortedMarkers.append(m)
                                break
                            }
                        }
                        i = i + 1
                    }
                    
                    self.drawRoute()
                    self.displayRouteInfo(workoutTime)
                    self.numStops = wayPointCount
                    
                    
                    // Move Google Map window to fit the markers
                    var bounds = GMSCoordinateBounds();
                    for m in self.markers {
                        bounds = bounds.includingCoordinate(m.position);
                    }
                    
                    self.mapView.animateWithCameraUpdate(GMSCameraUpdate.fitBounds(bounds, withPadding: 30))
                }
            }
            else {
                print(status)
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loaded = false
        
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
        
        updateMap()
        setUp()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error \(error)")
    }
    
    func updateMap() {
        let camera = GMSCameraPosition.cameraWithLatitude(currentLocation.latitude, longitude: currentLocation.longitude, zoom: mapView.camera.zoom)
        mapView.camera = camera
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
    
    
    func sortLocations(l1 : Location, l2 : Location) -> Bool {
//        print(self.currentLocation)
        return (pow(l1.latitude - self.currentLocation.latitude, 2.0) + pow(l1.longitude - self.currentLocation.longitude, 2.0)) < (pow(l2.latitude - self.currentLocation.latitude, 2.0) + pow(l2.longitude - self.currentLocation.longitude, 2.0))
    }
    
    @IBAction func start(sender: UIButton) {
        if timerRunning {
            firstButton.setTitle("Resume", forState: .Normal)
            timer.invalidate()
            countdownTimer.invalidate()
        } else {
            startRunningCountdown = 3
            countdownTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(RoutePreviewViewController.startRunning), userInfo: nil, repeats: true)
        }
        timerRunning = !timerRunning
    }
    
    var startRunningCountdown = 0
    
    func startRunning() {
        if (startRunningCountdown == 0) {
            countdownTimer.invalidate()
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(RoutePreviewViewController.updateTime), userInfo: nil, repeats: true)
            firstButton.setTitle("Pause", forState: .Normal)
            secondButton.setTitle("Stop", forState: .Normal)
        } else {
            firstButton.setTitle("Starting in \(startRunningCountdown) seconds...", forState: .Normal)
            startRunningCountdown = startRunningCountdown - 1
        }
    }
    
    var workoutTimeCount = 0
    
    func updateTime() {
        if (self.time > 0) {
            self.time = self.time - 1
        }
        if (self.workoutTimeCount > 0) {
            self.workoutTimeCount = self.workoutTimeCount - 1
            workoutTimer.text = intToTimeString(self.workoutTimeCount)
            if (self.workoutTimeCount == 0) {
                self.workoutView.hidden = true
            }
        }
    }
    
    @IBOutlet weak var workoutTitle: UILabel!
    @IBOutlet weak var workoutReps: UILabel!
    @IBOutlet weak var workoutSets: UILabel!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var locationDescription: UILabel!
    @IBOutlet weak var workoutTimer: UILabel!
    
    func intToTimeString(timeInSecs: Int) -> String {
        return "\(timeInSecs / 60):\(String(format: "%02d", timeInSecs % 60))"
    }
    
    func displayWorkout(title: String, reps: Int, sets: Int, locName: String, locDesc: String, timeLimit: Int) -> Void {
        workoutTitle.text = title
        workoutReps.text = "\(reps) reps"
        workoutSets.text = "\(sets) sets"
        locationName.text = locName
        locationDescription.text = locDesc
        self.workoutTimeCount = timeLimit
        workoutTimer.text = intToTimeString(self.workoutTimeCount)
        locationDescScrollView.contentOffset = CGPoint(x: 0, y: 0)
        
    }
    
    @IBAction func nextStop(sender: AnyObject) {
        self.fakeMove()
    }
    
    var testIndex = 0
    
    func fakeMove() {
        if (testIndex >= self.sortedMarkers.count) {
            self.performSegueWithIdentifier("ToResults", sender: self)
            return
        }
        currentLocation = CLLocationCoordinate2D(latitude: self.sortedMarkers[testIndex].position.latitude, longitude: self.sortedMarkers[testIndex].position.longitude)
        var nearestLoc = locations[0]
        for l in locations {
            if (pow(l.latitude - currentLocation.latitude, 2.0) + pow(l.longitude - currentLocation.longitude, 2.0) < pow(nearestLoc.latitude - currentLocation.latitude, 2.0) + pow(nearestLoc.longitude - currentLocation.longitude, 2.0)) {
                nearestLoc = l
            }
        }
        let wo = generatedWorkouts[testIndex]
        displayWorkout(wo.name, reps: wo.reps, sets: wo.sets, locName: nearestLoc.title, locDesc: nearestLoc.info, timeLimit: wo.time)
        workoutView.hidden = false
        
        testIndex = testIndex + 1
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
