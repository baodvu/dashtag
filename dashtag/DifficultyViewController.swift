//
//  DifficultyViewController.swift
//  dashtag
//
//  Created by Bao Vu on 10/21/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

import UIKit

class DifficultyViewController: UIViewController {

    @IBOutlet weak var difficultySlider: UISlider!
    
    var difficultyArray = ["easy", "medium", "hard"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        difficultySlider.setThumbImage(UIImage(named: "RunningMan"), forState: .Normal)
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

    @IBAction func sliderTouchUp(sender: UISlider) {
        // [sender setValue:floorf([sender value] + 0.5) animated:YES];
        sender.setValue(roundf(sender.value), animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "toTimeSettings") {
            //get a reference to the destination view controller
            let destinationVC = segue.destinationViewController as! TimeSettingViewController
            
            //set properties on the destination view controller
            destinationVC.difficultyLevel = difficultyArray[Int(difficultySlider.value)]
        }
    }
}
