

import UIKit
import Alamofire
import FBSDKCoreKit
import FBSDKLoginKit

class SignInViewController: UIViewController {

    @IBOutlet weak var facebookLoginBtn: UIButton!
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    @IBOutlet weak var validationFormLabel: UILabel!
    

    
    var facebookId = ""
    var facebookFirstName = ""
    var facebookMiddleName = ""
    var facebookLastName = ""
    var facebookName = ""
    var facebookProfilePicURL = ""
    var facebookEmail = ""
    var facebookAccessToken = ""
    let defaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide keyboard on click outside
//        self.setupHideKeyboardOnTap()
        if isLoggedIn() {
            let alert = UIAlertController(title: facebookId, message: "Authentification succeess", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.destructive, handler: nil))
            self.present(alert, animated: true, completion: nil)
            // Show the ViewController with the logged in user
        }else{
            // Show the Home ViewController
        }
        
        // Move keybord between textFields
        emailTxtField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
        passwordTxtField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.validationFormLabel.text = ""
        // Hide the navigation bar for current view controller
        self.navigationController?.isNavigationBarHidden = true;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.isNavigationBarHidden = false;
    }
    
    
    func isLoggedIn() -> Bool {
        let accessToken = AccessToken.current
        let isLoggedIn = accessToken != nil && !(accessToken?.isExpired ?? false)
        return isLoggedIn
    }
    
    @IBAction func facebookLoginBtn(_ sender: UIButton) {
    
    self.loginButtonClicked()
    }
    
    func loginButtonClicked() {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self, handler: { result, error in
            if error != nil {
                print("ERROR: Trying to get login results")
            } else if result?.isCancelled != nil {
                print("The token is \(result?.token?.tokenString ?? "")")
                if result?.token?.tokenString != nil {
                    print("Logged in")
                    self.getUserProfile(token: result?.token, userId: result?.token?.userID)
                } else {
                    print("Cancelled")
                }
            }
        })
    }
    
    func getUserProfile(token: AccessToken?, userId: String?) {
        let graphRequest: GraphRequest = GraphRequest(graphPath: "me", parameters: ["fields": "id, first_name, middle_name, last_name, name, picture, email"])
        graphRequest.start { _, result, error in
            if error == nil {
                let data: [String: AnyObject] = result as! [String: AnyObject]
                
                // Facebook Id
                if let facebookId = data["id"] as? String {
                    print("Facebook Id: \(facebookId)")
                    self.facebookId = facebookId
                } else {
                    print("Facebook Id: Not exists")
                    self.facebookId = "Not exists"
                }
                
                // Facebook First Name
                if let facebookFirstName = data["first_name"] as? String {
                    print("Facebook First Name: \(facebookFirstName)")
                    self.facebookFirstName = facebookFirstName
                } else {
                    print("Facebook First Name: Not exists")
                    self.facebookFirstName = "Not exists"
                }
                
                // Facebook Middle Name
                if let facebookMiddleName = data["middle_name"] as? String {
                    print("Facebook Middle Name: \(facebookMiddleName)")
                    self.facebookMiddleName = facebookMiddleName
                } else {
                    print("Facebook Middle Name: Not exists")
                    self.facebookMiddleName = "Not exists"
                }
                
                // Facebook Last Name
                if let facebookLastName = data["last_name"] as? String {
                    print("Facebook Last Name: \(facebookLastName)")
                    self.facebookLastName = facebookLastName
                } else {
                    print("Facebook Last Name: Not exists")
                    self.facebookLastName = "Not exists"
                }
                
                // Facebook Name
                if let facebookName = data["name"] as? String {
                    print("Facebook Name: \(facebookName)")
                    self.facebookName = facebookName
                } else {
                    print("Facebook Name: Not exists")
                    self.facebookName = "Not exists"
                }
                
                // Facebook Profile Pic URL
                let facebookProfilePicURL = "https://graph.facebook.com/\(userId ?? "")/picture?type=large"
                print("Facebook Profile Pic URL: \(facebookProfilePicURL)")
                self.facebookProfilePicURL = facebookProfilePicURL
                
                // Facebook Email
                if let facebookEmail = data["email"] as? String {
                    print("Facebook Email: \(facebookEmail)")
                    self.facebookEmail = facebookEmail
                } else {
                    print("Facebook Email: Not exists")
                    self.facebookEmail = "Not exists"
                }
                
                print("Facebook Access Token: \(token?.tokenString ?? "")")
                self.facebookAccessToken = token?.tokenString ?? ""
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "detailseg", sender: self)
                }
                
            } else {
                print("Error: Trying to get user's info")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailseg" {
            let DestView = segue.destination as! DetailsViewController
            DestView.facebookId = self.facebookId
            DestView.facebookFirstName = self.facebookFirstName
            DestView.facebookMiddleName = self.facebookMiddleName
            DestView.facebookLastName = self.facebookLastName
            DestView.facebookName = self.facebookName
            DestView.facebookProfilePicURL = self.facebookProfilePicURL
            DestView.facebookEmail = self.facebookEmail
            DestView.facebookAccessToken = self.facebookAccessToken
        }
    }

    
    @IBAction func btnLoginAction(_ sender: Any) {
        let email_tapped = emailTxtField.text
        // test if email is valid
        if email_tapped!.isValidEmail() {
            if(self.passwordTxtField.text == ""){
                self.validationFormLabel.text = "password required"
            }else{
                // execute web service
                self.validationFormLabel.text = ""
                let postParameters = [
                    "email": emailTxtField.text!,
                    "password": passwordTxtField.text!,
                    ] as [String : Any]
                //print("postParameters in signInViaEmail",postParameters)
                Alamofire.request(Constants.signInViaEmail, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
                    response in
                    switch response.result {
                    case .success:
                        guard response.result.error == nil else {
                            // got an error in getting the data, need to handle it
                            print("error calling POST")
                            print(response.result.error!)
                            return
                        }
                        
                        // make sure we got some JSON since that's what we expect
                        guard let json = response.result.value as? [String: Any] else {
                            print("didn't get object as JSON from URL")
                            if let error = response.result.error {
                                print("Error: \(error)")
                            }
                            return
                        }
                        
                        //print("response from server of signInViaEmail : ",json)
                        let responseServer = json["status"] as? NSNumber
                        if responseServer == 1{
                            // user successfuly looged in
                            if  let data = json["data"] as? [String:Any]{
                                if  let token = data["token"] as? String {
                                    // decode the JWT
                                    let userData = self.decode(token)
                                    // save statut of login user in NSUserDefaults
                                    let userConnected = true
                                    self.defaults.set(userConnected, forKey: "userStatut")
                                    // save object user in NSUserDefaults
                                    self.defaults.value(forKey: "objectUser")
                                    self.defaults.set(userData, forKey: "objectUser")
                                    self.defaults.synchronize()
                                    // navigate to HomePage
                                    self.performSegue(withIdentifier: "ShowHomeViaSignIn", sender: self)
                                    
                                }
                            
                            }
                            
                        }else if (responseServer == 0) {
                            // Authentification failed
                            let alert = UIAlertController(title: "Erreur", message: "Authentification Erroné", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.destructive, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            
                        }
                        break
                        
                    case .failure(let error):
                        print("error from server : ",error)
                        break
                        
                    }
                    
                }

            }

        }else{
            self.validationFormLabel.text = "email invalid"
        
        }
        
        
        
    }
    
    
    
    
    // decode jwt received from ws
    func decode(_ token: String) -> [String: AnyObject]? {
        let string = token.components(separatedBy: ".")
        let toDecode = string[1] as String
        
        
        var stringtoDecode: String = toDecode.replacingOccurrences(of: "-", with: "+") // 62nd char of encoding
        stringtoDecode = stringtoDecode.replacingOccurrences(of: "_", with: "/") // 63rd char of encoding
        switch (stringtoDecode.utf16.count % 4) {
        case 2: stringtoDecode = "\(stringtoDecode)=="
        case 3: stringtoDecode = "\(stringtoDecode)="
        default: // nothing to do stringtoDecode can stay the same
            print("")
        }
        let dataToDecode = Data(base64Encoded: stringtoDecode, options: [])
        let base64DecodedString = NSString(data: dataToDecode!, encoding: String.Encoding.utf8.rawValue)
        
        var values: [String: AnyObject]?
        if let string = base64DecodedString {
            if let data = string.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: true) {
                values = try! JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : AnyObject]
            }
        }
        return values
    }
    

}

extension SignInViewController: UITextFieldDelegate {
    
    // move keyboard
    @objc func textFieldDidChange(textField: UITextField){
        if (self.emailTxtField.isFirstResponder){
            self.emailTxtField.resignFirstResponder()
            self.passwordTxtField.becomeFirstResponder()
            
        }
        else if (self.passwordTxtField.isFirstResponder){
            self.passwordTxtField.resignFirstResponder()
            
        }
        
    }

}
