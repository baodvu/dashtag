//
//  LoginViewController.swift
//  dashtag
//
//  Created by Bao Vu on 10/15/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var email: String {
        get {
            return emailTextField.text ?? ""
        }
    }
    
    var password: String {
        get {
            return passwordTextField.text ?? ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let _ = FIRAuth.auth()?.currentUser {
            self.performSegueWithIdentifier("SegueToMain", sender: self)
        }
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
    
    @IBAction func login(sender: UIButton) {
        FIRAuth.auth()?.signInWithEmail(email, password: password) { (user, error) in
            if user != nil {
                self.performSegueWithIdentifier("SegueToMain", sender: self)
            } else {
                let alert = UIAlertController(title: "Wrong credentials", message: "Please make sure you type your email and password correctly", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                self.passwordTextField.text = ""
            }
        }
    }
    
}
