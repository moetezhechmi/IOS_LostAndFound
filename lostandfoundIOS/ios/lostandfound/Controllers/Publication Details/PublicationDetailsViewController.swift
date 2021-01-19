

import UIKit
import Alamofire
import SDWebImage

class PublicationDetailsViewController: UIViewController {

    var publication = Publication()
    var idPublicationReceived = String()
    let defaults = UserDefaults.standard
    var userConnected = User()
    
    @IBOutlet weak var btnDeletePubOutlet: UIButton!
    @IBOutlet weak var imageProfileOwnerPub: UIImageView!
    @IBOutlet weak var nameOwnerPubLabel: UILabel!
    @IBOutlet weak var dateAddPubLabel: UILabel!
    @IBOutlet weak var titlePubLabel: UILabel!
    @IBOutlet weak var nameSectorLabel: UILabel!
    @IBOutlet weak var textPubLabel: UILabel!
    @IBOutlet weak var imagePub: UIImageView!
    @IBOutlet weak var videoPub: UIWebView!
    @IBOutlet weak var nbrLikesLabel: UILabel!
    @IBOutlet weak var nbrCommentsLabel: UILabel!
    @IBOutlet weak var btnLike: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // get user data from UserDefaults
        let objectUser = self.defaults.dictionary(forKey: "objectUser")
        self.userConnected = User(objectUser!)
        if (self.idPublicationReceived == "") {
            // obj publication is received
            setupView()
        }else{
            // id publication received
            self.getPublicationById()
        }
        
        // delegate tap imagePub
        self.imagePub.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(PublicationDetailsViewController.didTapImagePub))
        imagePub.addGestureRecognizer(tap)
        
        let tapNameOwnerLabel = UITapGestureRecognizer(target: self, action: #selector(PublicationDetailsViewController.showProfileOwnerPub))
        nameOwnerPubLabel.isUserInteractionEnabled = true
        nameOwnerPubLabel.addGestureRecognizer(tapNameOwnerLabel)
        
        let tapNameSectorLabel = UITapGestureRecognizer(target: self, action: #selector(PublicationDetailsViewController.showAllPubBySector))
        nameSectorLabel.isUserInteractionEnabled = true
        nameSectorLabel.addGestureRecognizer(tapNameSectorLabel)
        
        let tapNbrLikesLabel = UITapGestureRecognizer(target: self, action: #selector(PublicationDetailsViewController.showAllLikes))
        nbrLikesLabel.isUserInteractionEnabled = true
        nbrLikesLabel.addGestureRecognizer(tapNbrLikesLabel)

    }
    
    func getPublicationById(){
        let postParameters = [
            "publicationId":self.idPublicationReceived,
            "userIdConnected":self.userConnected._id!,
            ] as [String : Any]
        //print("postParameters in getPublicationById",postParameters)
        Alamofire.request(Constants.getPublicationById, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
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
                
                //print("response from server of getPublicationById : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    if  let data = json["data"] as? [String:Any]{
                        if  let pubDict = data["publication"] as? [String : Any]{
                            self.publication = Publication(pubDict)
                            self.setupView()
                            
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
    
    func setupView() {
        // setup data
        self.nameOwnerPubLabel.text = self.publication.owner.firstName! + " " + self.publication.owner.lastName!
        self.imageProfileOwnerPub.sd_setImage(with: URL(string: self.publication.owner.pictureProfile!))
        self.imageProfileOwnerPub.layer.cornerRadius = self.imageProfileOwnerPub.frame.size.width/2
        self.imageProfileOwnerPub.clipsToBounds = true
        // setup pub details
        self.dateAddPubLabel.text = self.publication.createdAt
        self.titlePubLabel.text = self.publication.title
        self.nameSectorLabel.text = self.publication.sector.nameSector
        self.textPubLabel.text = self.publication.text
        if ((publication.type_file ) != nil){
            if(publication.type_file == "image"){
                self.videoPub.isHidden = true
                self.imagePub.isHidden = false
                self.imagePub.sd_setImage(with: URL(string: publication.url_file!))
            }else if (publication.type_file == "video"){
                self.imagePub.isHidden = true
                self.videoPub.isHidden = false
                
                DispatchQueue.main.async {
                    self.videoPub.loadHTMLString("<iframe width= \" \(self.videoPub.frame.width) \"height=\"\(self.videoPub.frame.height)\"src = \"\(self.publication.url_file!)\"> </iframe>", baseURL: nil)
                }
                videoPub.scrollView.isScrollEnabled = false
                videoPub.scrollView.bounces = false
                
            }
            
        }else{
            self.imagePub.isHidden = true
            self.videoPub.isHidden = true
            
        }
        if(publication.isLiked == true) {
            self.btnLike.setImage(UIImage(named: "ic_favorite_red"), for: .normal)
        }else{
            self.btnLike.setImage(UIImage(named: "ic_favorite_border_black"), for: .normal)
        }
        self.nbrLikesLabel.text =  "\(publication.nbrLikes!) " + "J'aime"
        self.nbrCommentsLabel.text =  "\(publication.nbrComments!) " + "Commentaires"
        if(publication.owner._id == self.userConnected._id) {
            self.btnDeletePubOutlet.isHidden = false
        }else{
            self.btnDeletePubOutlet.isHidden = true
            
        }
    }
    
    @objc func showProfileOwnerPub() {
        // navigate between Views from Identifier of Storyboard
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        // send data to desCV
        desVC.idUserReceived = self.publication.owner._id!
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
    }
    
    @objc func showAllPubBySector() {
        // navigate to searchView to get all publication by sector
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        // send data to desCV
        desVC.sectorId = self.publication.sector._id
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
    }
    
    @objc private func didTapImagePub() {
        let fullScreenImageView = storyboard?.instantiateViewController(withIdentifier: "FullScreenImageViewController") as! FullScreenImageViewController
        fullScreenImageView.urlImage = publication.url_file!
        let navc = UINavigationController(rootViewController: fullScreenImageView)
        self.present(navc, animated: true, completion: nil)
        
    }
    
    @objc func showAllLikes() {
        if (self.publication.nbrLikes! > 0){
            let popOverListLikesViewController = storyboard?.instantiateViewController(withIdentifier: "ListLikesViewController") as! ListLikesViewController
            popOverListLikesViewController.idPublication = self.publication._id!
            // show popOver with navigation Bar to enable push to profile with back to popOver
            let navc = UINavigationController(rootViewController: popOverListLikesViewController)
            self.present(navc, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnDeletePubAction(_ sender: Any) {
        // show alerte
        let alert = UIAlertController(title: "Attention",message: "Vous êtes sure de supprimer cette Publication?" ,preferredStyle: .alert)
        // YES button
        let btnYes = UIAlertAction(title: "Oui", style: .default, handler: { (action) -> Void in
            self.deletePublication()
        })
        
        // NO button
        let btnNo = UIAlertAction(title: "Non", style: .destructive, handler: { (action) -> Void in
            
        })
        alert.addAction(btnNo)
        alert.addAction(btnYes)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnLikeAction(_ sender: Any) {
        if (publication.isLiked!){
            // dislike pub
            let postParameters = [
                "userId":self.userConnected._id!,
                "publicationId": publication._id!,
                ] as [String : Any]
            //print("postParameters in dislikePublication",postParameters)
            Alamofire.request(Constants.dislikePublication, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
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
                    
                    print("response from server of dislikePublication : ",json)
                    let responseServer = json["status"] as? NSNumber
                    if responseServer == 1{
                        self.publication.isLiked = false
                        self.publication.nbrLikes = self.publication.nbrLikes! - 1
                        self.btnLike.setImage(UIImage(named: "ic_favorite_border_black"), for: .normal)
                        self.nbrLikesLabel.text =  "\(self.publication.nbrLikes!) " + "Likes"
                    }

                    break
                    
                case .failure(let error):
                    print("error from server : ",error)
                    break
                    
                }
                
            }
        }else{
            // like pub
            let postParameters = [
                "userId":self.userConnected._id!,
                "publicationId": publication._id!,
                ] as [String : Any]
            //print("postParameters in likePublication",postParameters)
            Alamofire.request(Constants.likePublication, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
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
                    print("response from server of likePublication : ",json)
                    let responseServer = json["status"] as? NSNumber
                    if responseServer == 1{
                        self.publication.isLiked = true
                        self.publication.nbrLikes = self.publication.nbrLikes! + 1
                        self.btnLike.setImage(UIImage(named: "ic_favorite_red"), for: .normal)
                        self.nbrLikesLabel.text =  "\(self.publication.nbrLikes!) " + "Likes"
                        
                    }
                    break
                    
                case .failure(let error):
                    print("error from server : ",error)
                    break
                    
                }
                
            }
        }
    }
    
    @IBAction func btnShowComments(_ sender: Any) {
        // navigate between Views from Identifier of Storyboard
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "ListCommentsViewController") as! ListCommentsViewController
        
        desVC.publication = self.publication
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
    }
    
    func deletePublication(){
        let postParameters = [
            "publicationId": self.publication._id!,
            ] as [String : Any]
        //print("postParameters deletePublicationById : ",postParameters)
        Alamofire.request(Constants.deletePublicationById, method: .post, parameters: postParameters,encoding: JSONEncoding.default).responseJSON {
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
                
                print("response from server of deletePublicationById : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    self.navigationController?.popViewController(animated: true)
                    // show toast
                    self.showToast(message: json["message"] as! String)
                    
                }
                
                break
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }
        
    }

}

// show toast
extension PublicationDetailsViewController {
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
