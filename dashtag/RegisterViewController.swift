//
//  RegisterViewController.swift
//  dashtag
//
//  Created by Bao Vu on 10/16/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {

    @IBOutlet weak var fullNameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPasswordTF: UITextField!
    
    var fullName: String {
        get {
            return fullNameTF.text ?? ""
        }
    }
    
    var email: String {
        get {
            let s = emailTF.text ?? ""
            return isValidEmail(s) ? s : ""
        }
    }
    
    var password: String {
        get {
            return (passwordTF.text ?? "" == confirmPasswordTF.text ?? "") ? passwordTF.text! : ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    @IBAction func createAccount(sender: UIButton) {
        if email == "" {
            showAlert("Please check the email field")
            return
        }
        if fullName == "" {
            showAlert("Please check the name field")
            return
        }
        if password == "" {
            showAlert("Please check the password again")
            return
        }
        
        FIRAuth.auth()?.createUserWithEmail(email, password: password) { (user, error) in
            if (error != nil) {
                print(error)
                let alert = UIAlertController(title: "Registration failed", message: "Please make sure you entered all fields correctly", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                if let user = user {
                    let changeRequest = user.profileChangeRequest()
                    
                    changeRequest.displayName = self.fullName
                    changeRequest.commitChangesWithCompletion { error in
                        if error != nil {
                            // An error happened.
                        } else {
                            // Profile updated.
                        }
                    }
                    self.performSegueWithIdentifier("SegueRegisterToLogin", sender: self)
                }
            }
        }
    }
    
    func showAlert(message: String) -> Void {
        let alert = UIAlertController(title: "Registration failed", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
