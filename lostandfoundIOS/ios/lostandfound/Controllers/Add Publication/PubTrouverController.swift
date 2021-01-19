

import UIKit
import DropDown
import Alamofire

import AVKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary

import CoreLocation
class PubTrouverController: UIViewController, CLLocationManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
   
    
    let defaults = UserDefaults.standard
    var userConnected = User()
    let dropDownStatus = DropDown()


    var window: UIWindow?
    var controller = UIImagePickerController()
    var player : AVPlayer?
    
    var videoUrlFromLibrary : URL?
    let placeholderPublicationTextView = "Description..."
    var arrayAllSectors: [Sector] = []
    var sectorId: String?
    var typeFileToAdded = ""

   
    @IBOutlet weak var dropDownView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var sectorTextField: UITextField!
    @IBOutlet weak var textPublication: UITextView!
    @IBOutlet weak var videoSelected: UIView!
    @IBOutlet weak var imageSelected: UIImageView!
    @IBOutlet weak var messageValidationFormLabel: UILabel!
    @IBOutlet weak var btnRemoveFile: UIButton!
    
   
  
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //hide keyboard on click outside
        self.setupHideKeyboardOnTap()
        
        // Move keybord between textFields
        titleTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: UIControl.Event.editingDidEndOnExit)
        
        
        // get user data from UserDefaults
        let objectUser = self.defaults.dictionary(forKey: "objectUser")
        self.userConnected = User(objectUser!)
        // prepare btn drop down menu
        
        // delegate sector text field
       
        // set up  text view
        let lightGrayColor : UIColor = UIColor.lightGray
        self.textPublication.layer.borderColor = lightGrayColor.cgColor
        self.textPublication.layer.borderWidth = 0.5
        self.textPublication.layer.cornerRadius = 5
        self.textPublication.text = self.placeholderPublicationTextView
        self.textPublication.textColor = UIColor.lightGray
        self.textPublication.font = UIFont(name: "verdana", size: 13.0)
        self.textPublication.returnKeyType = .done
        self.textPublication.delegate = self
        // get allSectors
        self.getAllSectors()
        
    }
    
   
   
    
    func getAllSectors(){
        Alamofire.request(Constants.getAllSectors, method: .get,encoding: JSONEncoding.default).responseJSON {
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
                
                //print("response from server of getAllSectors : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    if  let data = json["data"] as? [String:Any]{
                        if  let listeSectorsData = data["sectors"] as? [[String : Any]]{
                            for sectorDic in listeSectorsData {
                                let sectorObj = Sector(sectorDic)
                                self.arrayAllSectors.append(sectorObj)
                            }
                            
                        }
                    }
                }
                break
                
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }
        
    }
    
    @IBAction func btnSelectFileAction(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Select File", message: nil, preferredStyle: .actionSheet)
        
        let getImageAction = UIAlertAction(title: "Image", style: .default) { action in
            // Display Photo Library to get image
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary;
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        
    
        
        
        
        
        
        
        
        let cancelAction = UIAlertAction(title: "Annuler", style: .destructive, handler: nil)
        
        actionSheet.addAction(getImageAction)
//        actionSheet.addAction(getVideoAction)
        actionSheet.addAction(cancelAction)
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(actionSheet, animated: true, completion: nil)

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            self.typeFileToAdded = "image"
            //self.videoSelected = nil
            self.videoSelected?.isHidden = true
            self.imageSelected?.isHidden = false
            self.imageSelected.image = pickedImage
            picker.dismiss(animated: true, completion: nil)
        }else{
            videoUrlFromLibrary = info[UIImagePickerController.InfoKey.mediaURL] as? URL
            
            // Setup view player
            if let urlVideo = videoUrlFromLibrary {
                //self.imageSelected = nil
                self.imageSelected?.isHidden = true
                self.videoSelected?.isHidden = false
                self.typeFileToAdded = "video"
                player = AVPlayer(url: urlVideo)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.videoSelected.bounds
                self.videoSelected.layer.addSublayer(playerLayer)
                picker.dismiss(animated: true, completion: nil)

            }
        }
        self.btnRemoveFile.isHidden = false
        //self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnRemoveFile(_ sender: Any) {
        
        // show alerte
        let alert = UIAlertController(title: "Attention",message: "Vous-êtes sure de supprimer l'image?" ,preferredStyle: .alert)
        // YES button
        let btnYes = UIAlertAction(title: "OUI", style: .default, handler: { (action) -> Void in
            if (self.typeFileToAdded == "image") {
                //self.imageSelected.image = nil
                self.imageSelected?.isHidden = true
            }else if (self.typeFileToAdded == "video"){
                //self.videoSelected = nil
                self.videoSelected?.isHidden = true
            }else{
                self.imageSelected?.isHidden = true
                self.videoSelected?.isHidden = true
            }
            self.typeFileToAdded = ""
            self.btnRemoveFile.isHidden = true
        })
        
        // NO button
        let btnNo = UIAlertAction(title: "NON", style: .destructive, handler: { (action) -> Void in
            
        })
        alert.addAction(btnNo)
        alert.addAction(btnYes)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    @IBAction func btnSubmit(_ sender: Any) {
    
    guard let _ = titleTextField.text , (titleTextField.text?.count)! >= 3 else {
            messageValidationFormLabel.text = "Title must contain at least 3 caracters"
            return
        }
       
        
        var txtPubToSend = textPublication.text
        if (txtPubToSend == self.placeholderPublicationTextView) {
            txtPubToSend = ""
        }
        else {
            
            // show alerte
            let alert = UIAlertController(title: "Attention",message: "Vous_êtes sure dE publier cette publication ?" ,preferredStyle: .alert)
            // YES button
            let btnYes = UIAlertAction(title: "OUI", style: .default, handler: { (action) -> Void in
                // execute web service
                
                let postParameters = [
                    "title": self.titleTextField.text!,
                    "text": txtPubToSend!,
                  //  "sectorId": self.sectorId!,
                    "ownerId": self.userConnected._id!,
                    "type_file": self.typeFileToAdded,
                    "nom": "J'ai trouvé",

                    ] as [String : Any]
                
                
                Alamofire.upload(multipartFormData: { (multipartFormData) in
                    for (key, value) in postParameters {
                        if value is String {
                            multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                        }
                        
                    }
                    if (self.typeFileToAdded == "image") {
                        multipartFormData.append(self.imageSelected.image!.jpegData(compressionQuality: 0.75)!, withName: "file", fileName: "swift_file.jpeg", mimeType: "image/jpeg")
                    }
                
                    
                }, to:Constants.addPublication , headers: nil)
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
                                    
                                    self.titleTextField.text = ""
                                    
                                   
                                    self.sectorId = ""
                                    self.typeFileToAdded = ""
                                    self.textPublication.text = self.placeholderPublicationTextView
                                    self.imageSelected.image = nil
                                    self.videoSelected = nil
                                    self.btnRemoveFile.isHidden = true
                                    // publication added successfully
                                    self.showToast(message: (result["message"] as? String)!)
                                    
                                    // navigate to HomePage
                                    self.performSegue(withIdentifier: "trouver", sender: self)
                                   // self.performSegue(withIdentifier: "trouver", sender: self)
                                    
                                }
                            }
                            
                        }
                        
                    case .failure(let error):
                        print("error from server : ",error)
                        break
                        
                    }
                    
                }
            })
            
            // NO button
            let btnNo = UIAlertAction(title: "NO", style: .destructive, handler: { (action) -> Void in
                
            })
            alert.addAction(btnNo)
            alert.addAction(btnYes)
            self.present(alert, animated: true, completion: nil)
            

        
        
        }
        


    }
    
    

}

extension PubTrouverController: UITextFieldDelegate {
    
    // move keyboard
    @objc func textFieldDidChange(textField: UITextField){
        if (self.titleTextField.isFirstResponder){
            self.titleTextField.resignFirstResponder()
            self.sectorTextField.becomeFirstResponder()
            
        }
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        view.endEditing(true)
        let alert = UIAlertController(title: "Choisir la catégorie", message: nil, preferredStyle: UIAlertController.Style.alert)
        for sectorDic in self.arrayAllSectors{
            
            let action = UIAlertAction(title: sectorDic.nameSector, style: .default, handler: { (action) -> Void in
                self.sectorId = sectorDic._id
                self.sectorTextField.text = sectorDic.nameSector
                
            })
            alert.addAction(action)
        }
        // Cancel button
        let cancel = UIAlertAction(title: "Annuler", style: .destructive, handler: { (action) -> Void in })
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
}

extension PubTrouverController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == self.placeholderPublicationTextView {
            textView.text = ""
            textView.textColor = UIColor.black
            textView.font = UIFont(name: "verdana", size: 13.0)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            self.textPublication.text = self.placeholderPublicationTextView
            self.textPublication.textColor = UIColor.lightGray
            self.textPublication.font = UIFont(name: "verdana", size: 13.0)
        }
    }
    
}


// show drop down menu to logout
extension PubTrouverController {
    //dropDownBtnAction

}
// show toast
extension PubTrouverController {
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
        
        UIView.animate(withDuration: 5.0, animations: {
            toastLbl.alpha = 0
        }) { (_) in
            toastLbl.removeFromSuperview()
        }
        
    }
    
}
