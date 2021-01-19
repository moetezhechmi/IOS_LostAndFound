
import UIKit
import Alamofire

class UpdateProfileViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var firstNameTxtField: UITextField!
    @IBOutlet weak var lastNameTxtField: UITextField!
    @IBOutlet weak var ageTxtField: UITextField!
    @IBOutlet weak var updatePasswordLabel: UILabel!
    @IBOutlet weak var updatePasswordView: UIStackView!
    @IBOutlet weak var oldPasswordTxtField: UITextField!
    @IBOutlet weak var newPasswordTxtField: UITextField!
    @IBOutlet weak var validationFormLabel: UILabel!
   
    
    let defaults = UserDefaults.standard
    var userConnected = User()
    var is_image_profile_changed = false
    var lastTagGender = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        oldPasswordTxtField.isSecureTextEntry = true
        newPasswordTxtField.isSecureTextEntry = true
        imageProfile.layer.cornerRadius = self.imageProfile.frame.size.width/2
        imageProfile.clipsToBounds = true
        
        // get user data from UserDefaults
        let objectUser = self.defaults.dictionary(forKey: "objectUser")
        self.userConnected = User(objectUser!)
        
        self.setupView()
        
        let tapUpdatePasswordLabel = UITapGestureRecognizer(target: self, action: #selector(UpdateProfileViewController.showUpdatePasswordView))
        updatePasswordLabel.isUserInteractionEnabled = true
        updatePasswordLabel.addGestureRecognizer(tapUpdatePasswordLabel)
    }
    
    func setupView() {
        self.imageProfile.sd_setImage(with: URL(string: self.userConnected.pictureProfile!))
        self.emailTxtField.text = self.userConnected.email
        self.firstNameTxtField.text = self.userConnected.firstName
        self.lastNameTxtField.text = self.userConnected.lastName
        self.ageTxtField.text = self.userConnected.age
        
        // setUp RadioButton of gender
        if (self.userConnected.gender == "Male" || self.userConnected.gender == nil){
            self.lastTagGender = "Male"
        }else if (self.userConnected.gender == "Female"){
            self.lastTagGender = "Female"
        }
        self.updatePasswordLabel.text = "Modifier Mot de passe ?"
    }
    
    @objc func showUpdatePasswordView(){
        self.updatePasswordView.isHidden = !self.updatePasswordView.isHidden
    }
    
    @IBAction func btnGenderAction(_ sender: DLRadioButton) {
        if (sender.tag == 1) {
            self.lastTagGender = "Male"
        }else {
            self.lastTagGender = "Female"
        }
    }
    
    @IBAction func btnUpdateImageProfile(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary;
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        }
        //print(info)
        self.is_image_profile_changed = true
        self.imageProfile.image = image
        self.dismiss(animated: true, completion: nil);
    }
    
    
    
    @IBAction func btnSubmitUpdateAction(_ sender: Any) {
        if (self.emailTxtField.text!.isValidEmail()){
            
            
            
            if (self.oldPasswordTxtField.text != "" || self.newPasswordTxtField.text != "") {
                guard let _ = oldPasswordTxtField.text , (oldPasswordTxtField.text?.count)! >= 4 else {
                    validationFormLabel.text = "Old Password must have 4 caracters"
                    return
                }
                
                guard let _ = self.newPasswordTxtField.text , (self.newPasswordTxtField.text?.count)! >= 4 else {
                    validationFormLabel.text = "New Password must have 4 caracters"
                    return
                }
            }
            self.confirmUpdateProfile()

        }else{
            validationFormLabel.text = "Email invalid"
        }
    }
    
    
    func confirmUpdateProfile(){
        // execute web service
        self.validationFormLabel.text = ""
        let postParameters = [
            "email": self.emailTxtField.text!,
            "firstName": self.firstNameTxtField.text!,
            "lastName": self.lastNameTxtField.text!,
            "age": self.ageTxtField.text!,
            "userId": self.userConnected._id!,
            "oldPassword": self.oldPasswordTxtField.text ?? "",
            "newPassword": self.newPasswordTxtField.text ?? "",
            ] as [String : Any]
        //print("postParameters in updateProfile",postParameters)
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in postParameters {
                if value is String {
                    multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                }
                
            }
            if (self.is_image_profile_changed == true) {
                multipartFormData.append(self.imageProfile.image!.jpegData(compressionQuality: 0.75)!, withName: "file", fileName: "swift_file.jpeg", mimeType: "image/jpeg")
            }
            
            
        }, to:Constants.updateProfile , headers: nil)
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    // print (progress)
                })
                
                upload.responseJSON { response in
                    
                    if response.result.isFailure == true {
                        print("errror upload")
                    }
                    
                    if let result = response.result.value as? [String:Any] {
                        let responseServer = result["status"] as? NSNumber
                        if responseServer == 1 {
                            if  let data = result["data"] as? [String:Any]{
                                if  let userData = data["user"] as? [String:Any] {
                                    self.userConnected = User(userData)
                                    // save object user in NSUserDefaults
                                    self.defaults.value(forKey: "objectUser")
                                    self.defaults.set(userData, forKey: "objectUser")
                                    self.defaults.synchronize()
                                    self.showToast(message: (result["message"] as? String)!)
                                    //self.navigationController?.popViewController(animated: true)
                                }
                            }
                            
                        }
                    }
                    
                }
                
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }
    }



}


// show toast
extension UpdateProfileViewController {
    func showToast(message: String) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let toastLbl = UILabel()
        toastLbl.text = message
        toastLbl.textAlignment = .center
        toastLbl.font = UIFont.systemFont(ofSize: 18)
        toastLbl.textColor = UIColor.white
        toastLbl.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLbl.numberOfLines = 0
        
        
        let textSize = toastLbl.intrinsicContentSize
        let labelHeight = ( textSize.width / window.frame.width ) * 30
        let labelWidth = min(textSize.width, window.frame.width - 40)
        let adjustedHeight = max(labelHeight, textSize.height + 20)
        
        toastLbl.frame = CGRect(x: 20, y: (window.frame.height - 90 ) - adjustedHeight, width: labelWidth + 20, height: adjustedHeight)
        toastLbl.center.x = window.center.x
        toastLbl.layer.cornerRadius = 10
        toastLbl.layer.masksToBounds = true
        
        window.addSubview(toastLbl)
        
        UIView.animate(withDuration: 10.0, animations: {
            toastLbl.alpha = 0
        }) { (_) in
            toastLbl.removeFromSuperview()
        }
        
    }
    
}
