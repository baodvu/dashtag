//
//  MainScreenViewController.swift
//  dashtag
//
//  Created by Bao Vu on 10/15/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

import UIKit
import FirebaseAuth

class MainScreenViewController: UIViewController {

    @IBOutlet weak var welcomeText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
//        if let user = FIRAuth.auth()?.currentUser {
//            let name = user.displayName ?? "dasher"
//            welcomeText.text = "Hello, \(name)!\nPlease choose your workout"
//        } else {
//            // No user is signed in.
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func logout(sender: AnyObject) {
        try! FIRAuth.auth()?.signOut()
    }
}
