
import UIKit
import Alamofire

class SignUpViewController: UIViewController {

    @IBOutlet weak var firstNameTxtField: UITextField!
    @IBOutlet weak var lastNameTxtField: UITextField!
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    @IBOutlet weak var ageTxtField: UITextField!
    @IBOutlet weak var validationFormLabel: UILabel!
    
    var arrayGender = ["Male","Female"]
    let genderPickerView = UIPickerView()
    let defaults = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        //hide keyboard on click outside
        self.setupHideKeyboardOnTap()
        
        // Move keybord between textFields
        firstNameTxtField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
        lastNameTxtField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
        emailTxtField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
        passwordTxtField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
        ageTxtField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
        
        // delegate max length
        self.firstNameTxtField.delegate = self
        self.lastNameTxtField.delegate = self
        
        // create pickerView for to choose gender

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.validationFormLabel.text = ""
        
    }
    
    
    
    @IBAction func btnSignupAction(_ sender: Any) {
        if (self.emailTxtField.text!.isValidEmail()){
           
            guard let _ = passwordTxtField.text , (passwordTxtField.text?.count)! >= 4 else {
                validationFormLabel.text = "Mot de passe est composé de 4 caractères"
                return
            }
        
            
           /* guard let _ = ageTxtField.text , (ageTxtField.text?.count)! > 8 else {
                validationFormLabel.text = "Numéro de téléphone invalide"
                return
            }*/
            guard let _ = ageTxtField.text , (ageTxtField.text?.count)! >= 8 else {
                validationFormLabel.text = "Numéro de téléphone invalide"
                return
            }
            
            // execute web service
            self.validationFormLabel.text = ""
            let postParameters = [
                "email": emailTxtField.text!,
                "password": passwordTxtField.text!,
                "firstName": firstNameTxtField.text!,
                "lastName": lastNameTxtField.text!,
                "age": ageTxtField.text!,
                ] as [String : Any]
            //print("postParameters in signUpViaEmail",postParameters)
            Alamofire.request(Constants.signUpViaEmail, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
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

                    //print("response from server of signUpViaEmail : ",json)
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
                                self.performSegue(withIdentifier: "ShowHomeViaSignUp", sender: self)

                            }

                        }

                    }
                    break
                    
                case .failure(let error):
                    print("error from server : ",error)
                    break
                    
                }
                
            }

        }else{
            validationFormLabel.text = "Email invalid"
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

extension SignUpViewController: UIPickerViewDataSource,UIPickerViewDelegate {
    //UIPickerViewDataSource
    // number of colums
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // number of rows
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.arrayGender.count
    }
    
    //UIPickerViewDelegate
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.arrayGender[row]
    }
    
    
}

extension SignUpViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        return textField.text!.count < 30 || string == ""
        
    }
    
    // move keyboard
    @objc func textFieldDidChange(textField: UITextField){
        if (self.firstNameTxtField.isFirstResponder){
            self.firstNameTxtField.resignFirstResponder()
            self.lastNameTxtField.becomeFirstResponder()
            
        }else if (self.lastNameTxtField.isFirstResponder){
            self.lastNameTxtField.resignFirstResponder()
            self.emailTxtField.becomeFirstResponder()
            
        }else if (self.emailTxtField.isFirstResponder){
            self.emailTxtField.resignFirstResponder()
            self.ageTxtField.becomeFirstResponder()
            
        }else if (self.ageTxtField.isFirstResponder){
            self.ageTxtField.resignFirstResponder()
            
        }
        
    }
    
}

