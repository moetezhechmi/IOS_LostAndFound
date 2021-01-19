import UIKit
import Alamofire

class ListCommentsViewController: UIViewController {
    
    var publication = Publication()
    let defaults = UserDefaults.standard
    var userConnected = User()
    var arrayComments: [Comment] = []
    var currentPageNumber: Int = 1
    var totalNbrPages: Int = 1
    let placeholderCommentTextView = "Ajouter votre commentaire"
    
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var newCommmentTxtView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide keyboard on click outside
        self.setupHideKeyboardOnTap()
        
        // remove extra empty cells
        self.commentsTableView.tableFooterView = UIView()
        // get user data from UserDefaults
        let objectUser = self.defaults.dictionary(forKey: "objectUser")
        self.userConnected = User(objectUser!)
        // custom placeholder to textView
        let whiteColor : UIColor = UIColor.white
        self.newCommmentTxtView.layer.borderWidth = 0.5
        self.newCommmentTxtView.layer.borderColor = whiteColor.cgColor
        self.newCommmentTxtView.layer.cornerRadius = 15
        newCommmentTxtView.text = self.placeholderCommentTextView
        newCommmentTxtView.textColor = UIColor.lightGray
        newCommmentTxtView.font = UIFont(name: "verdana", size: 13.0)
        // delegate textView
        self.newCommmentTxtView.delegate = self
        // get data from server
        getComments(pageNumber: self.currentPageNumber)
        
        
    }
    
    func getComments(pageNumber:Int){
        let postParameters = [
            "publicationId": self.publication._id!,
            "perPage": Constants.perPageForListing,
            "page": pageNumber,
            ] as [String : Any]
        //print("postParameters in getComments",postParameters)
        Alamofire.request(Constants.getComments, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
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
                
                //print("response from server of getComments : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    if  let data = json["data"] as? [String:Any]{
                        if  let listeCommentsData = data["comments"] as? [[String : Any]]{
                            for commentDic in listeCommentsData {
                                let pub = Comment(commentDic)
                                self.arrayComments.append(pub)
                            }
                            
                        }
                        if let nbrTotalOfPages = data["Totalpages"] as? Int{
                            self.totalNbrPages = nbrTotalOfPages
                        }
                        self.currentPageNumber += 1
                        self.publication.nbrComments = self.arrayComments.count
                        // refresh tableView
                        self.commentsTableView.reloadData()
                    }
                }
                break
                
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }
    }
    
    func deleteComment(comment: Comment, indexPathCell : Int){
        let postParameters = [
            "publicationId": self.publication._id!,
            "commentId": comment._id!,
            ] as [String : Any]
        //print("postParameters deleteComment : ",postParameters)
        Alamofire.request(Constants.deleteComment, method: .post, parameters: postParameters,encoding: JSONEncoding.default).responseJSON {
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
                
                print("response from server of deleteCommentsByUser : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    // remove comment from arrayComments
                    self.arrayComments.remove(at: indexPathCell)
                    // reload commentsTableView
                    self.commentsTableView.reloadData()
                    // show toast
                    self.showToast(message: json["message"] as! String)
                    // increase nbr comments of the pub
                    self.publication.nbrComments = self.arrayComments.count

                    
                }
                
                break
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }

    }
    
    
    @IBAction func btnSendNewCommentAction(_ sender: Any) {
        if (self.newCommmentTxtView.text == "" || self.newCommmentTxtView.text == self.placeholderCommentTextView){
            // show alerte
            let alert = UIAlertController(title: "Erreur",message: " Commentaire Invalide " ,preferredStyle: .alert)
            let btnOK = UIAlertAction(title: "OK", style: .destructive, handler: { (action) -> Void in })
            alert.addAction(btnOK)
            self.present(alert, animated: true, completion: nil)
        }else{
            // execute web service
            let postParameters = [
                "publicationId": self.publication._id!,
                "userId": self.userConnected._id!,
                "text": self.newCommmentTxtView.text,
                ] as [String : Any]
            //print("postParameters addComment : ",postParameters)
            Alamofire.request(Constants.addComment, method: .post, parameters: postParameters,encoding: JSONEncoding.default).responseJSON {
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
                    
                    //print("response from server of addComment : ",json)
                    let responseServer = json["status"] as? NSNumber
                    if responseServer == 1{
                        self.publication.nbrComments = self.arrayComments.count + 1
                        self.showToast(message: json["message"] as! String)
                        //let desVC = self.navigationController?.viewControllers[0] as! HomeViewController
                       // desVC.publicationUpdated = self.publication
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                    break
                case .failure(let error):
                    print("error from server : ",error)
                    break
                    
                }
                
            }
            
            
        }
    }
    
}


extension ListCommentsViewController: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayComments.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentTableViewCell
        cell.loadData(comment: arrayComments[indexPath.row], indexPathCell: indexPath, tableView: tableView)
        if (self.publication.owner._id == self.userConnected._id || arrayComments[indexPath.row].author._id == self.userConnected._id){
            cell.btnDeleteComment.isHidden = false
        }else{
            cell.btnDeleteComment.isHidden = true
        }
        cell.delegateComment = self // lisener to action btn
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // for pagination
        if indexPath.row == arrayComments.count - 1 && (self.totalNbrPages >= self.currentPageNumber) {
            getComments(pageNumber: self.currentPageNumber)
        }
    }
    
}

extension ListCommentsViewController : CommentTableViewCellDelegate {
    func didLabelNameAuthorCommentTapped(idAuthorComment: String, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        // navigate between Views from Identifier of Storyboard
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        // send data to desCV
        desVC.idUserReceived = idAuthorComment
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
    }
    
    
    func didBtnDeleteCommentClicked(comment: Comment, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        // show alerte
        let alert = UIAlertController(title: "Attention",message: "Vous-êtes sure de supprimer ce commentaire?" ,preferredStyle: .alert)
        // YES button
        let btnYes = UIAlertAction(title: "OUI", style: .default, handler: { (action) -> Void in
            self.deleteComment(comment: comment, indexPathCell : indexPathCell.row)
        })
        
        // NO button
        let btnNo = UIAlertAction(title: "NON", style: .destructive, handler: { (action) -> Void in
            
        })
        alert.addAction(btnNo)
        alert.addAction(btnYes)
        self.present(alert, animated: true, completion: nil)
        
    }
    
}

extension ListCommentsViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderCommentTextView {
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
            self.newCommmentTxtView.text = placeholderCommentTextView
            self.newCommmentTxtView.textColor = UIColor.lightGray
            self.newCommmentTxtView.font = UIFont(name: "verdana", size: 13.0)
        }
    }
    
}


// show toast
extension ListCommentsViewController {
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
