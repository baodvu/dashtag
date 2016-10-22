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
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(animated: Bool) {
        if let _ = FIRAuth.auth()?.currentUser {
            self.performSegueWithIdentifier("SegueToMain", sender: self)
        }
        
        // For testing purposes only: Log in without user credentials
//        self.performSegueWithIdentifier("SegueToMain", sender: self)
    }
    
    //Calls this function when the tap is recognized.
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
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
