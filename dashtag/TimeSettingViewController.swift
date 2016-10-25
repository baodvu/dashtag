//
//  TimeSettingViewController.swift
//  dashtag
//
//  Created by Bao Vu on 10/24/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

import UIKit

class TimeSettingViewController: UIViewController {
    
    var difficultyLevel = ""
    @IBOutlet weak var timer: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        timer.countDownDuration = 60*30
        timer.setValue(UIColor.whiteColor(), forKeyPath: "textColor")
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "toRoutePreview") {
            //get a reference to the destination view controller
            let destinationVC = segue.destinationViewController as! RoutePreviewViewController
            
            //set properties on the destination view controller
            destinationVC.difficultyLevel = difficultyLevel
            destinationVC.workoutDuration = Int(timer.countDownDuration)
        }
    }

}
