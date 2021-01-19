import UIKit
import DropDown
import Alamofire

class HomeViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    var userConnected = User()
    let dropDownStatus = DropDown()
    var window: UIWindow?
    
    var refresher: UIRefreshControl!
    var arrayPublications: [Publication] = []
    var currentPageNumber: Int = 1
    var totalNbrPages: Int = 1
    @IBOutlet weak var timeLineTableView: UITableView!
    @IBOutlet weak var dropDownView: UIView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // prepare btn drop down menu
        self.prepareStatusDropDown()
        // prepare nibCell of TableView
        let nibCell = UINib(nibName: "PublicationTableViewCell", bundle: nil)
        self.timeLineTableView.register(nibCell, forCellReuseIdentifier: "PublicationTableViewCell")
        // remove extra empty cells
        self.timeLineTableView.tableFooterView = UIView()
        // get user data from UserDefaults
        let objectUser = self.defaults.dictionary(forKey: "objectUser")
        self.userConnected = User(objectUser!)
        
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Loading...")
        refresher.addTarget(self, action: #selector(HomeViewController.refreshData), for: UIControl.Event.valueChanged)
        timeLineTableView.addSubview(refresher)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (self.totalNbrPages >= self.currentPageNumber){
            self.getTimeLine(pageNumber: self.currentPageNumber)
        }
       
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.arrayPublications.removeAll()
        self.currentPageNumber = 1
        self.totalNbrPages = 1
        
    }
    
    @objc func refreshData()
    {
        self.currentPageNumber = 1
        self.totalNbrPages = 1
        self.getTimeLine(pageNumber: self.currentPageNumber)
        refresher.endRefreshing()
    }
    
    func getTimeLine(pageNumber:Int){
        let postParameters = [
            "userIdConnected":self.userConnected._id!,
            "perPage": Constants.perPageForListing,
            "page": pageNumber,
        ] as [String : Any]
        //print("postParameters in getTimeLine",postParameters)
        Alamofire.request(Constants.getTimeLine, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
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
                
                //print("response from server of getTimeLine : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    if  let data = json["data"] as? [String:Any]{
                        if  let listePublicationsData = data["publications"] as? [[String : Any]]{
                            for publicationDic in listePublicationsData {
                                let pub = Publication(publicationDic)
                                self.arrayPublications.append(pub)
                            }
                            
                        }
                        if let nbrTotalOfPages = data["Totalpages"] as? Int{
                            self.totalNbrPages = nbrTotalOfPages
                        }
                        self.currentPageNumber += 1
                        // refresh tableView
                        self.timeLineTableView.reloadData()
                    }
                }
                break
                
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }
        
    }
    
    func deletePublication(publication: Publication, indexPathCell : Int){
        let postParameters = [
            "publicationId": publication._id!,
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
                
                //print("response from server of deletePublicationById : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    // remove publication from arrayPublications
                    self.arrayPublications.remove(at: indexPathCell)
                    // reload timeLineTableView
                    self.timeLineTableView.reloadData()
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

extension HomeViewController: UITableViewDelegate,UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayPublications.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PublicationTableViewCell", for: indexPath) as! PublicationTableViewCell
        if(arrayPublications[indexPath.row].owner._id == self.userConnected._id) {
            cell.btnDeletePubOutlet.isHidden = false
        }else{
            cell.btnDeletePubOutlet.isHidden = true

        }
        cell.loadData(publication: arrayPublications[indexPath.row], indexPathCell: indexPath, tableView: tableView)
        cell.delegatePublication = self // lisener to action btn
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // navigate between Views from Identifier of Storyboard
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "PublicationDetailsViewController") as! PublicationDetailsViewController
        
        desVC.publication = arrayPublications[indexPath.row]
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // for pagination
        if indexPath.row == arrayPublications.count - 1 && (self.totalNbrPages >= self.currentPageNumber) {
            getTimeLine(pageNumber: self.currentPageNumber)
        }
    }
    
}

// delegate functions of PublicationTableViewCell
extension HomeViewController : PublicationTableViewCellDelegate {
    
    func didBtnDeletePubClicked(publication: Publication, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        // show alerte
        let alert = UIAlertController(title: "Attention",message: "Vous-êtes sur de supprimer cette publication?" ,preferredStyle: .alert)
        // YES button
        let btnYes = UIAlertAction(title: "OUI", style: .default, handler: { (action) -> Void in
            self.deletePublication(publication: publication, indexPathCell : indexPathCell.row)
        })
        
        // NO button
        let btnNo = UIAlertAction(title: "NON", style: .destructive, handler: { (action) -> Void in
            
        })
        alert.addAction(btnNo)
        alert.addAction(btnYes)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func didLabelNbrLikesTapped(idPublication: String, nbrLikes: Int,cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        if (nbrLikes > 0){
            let popOverListLikesViewController = storyboard?.instantiateViewController(withIdentifier: "ListLikesViewController") as! ListLikesViewController
            popOverListLikesViewController.idPublication = idPublication
            // show popOver with navigation Bar to enable push to profile with back to popOver
            let navc = UINavigationController(rootViewController: popOverListLikesViewController)
            self.present(navc, animated: true, completion: nil)
        }
        
    }
    
    func didLabelNameOwnerPubTapped(idOwnerPub: String, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        // navigate between Views from Identifier of Storyboard
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        // send data to desCV
        desVC.idUserReceived = idOwnerPub
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
        
    }
    
    func didLabelNameSectorTapped(sector: Sector, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        // navigate to searchView to get all publication by sector
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "SearchViewController") as! SearchViewController
        // send data to desCV
        desVC.sectorId = sector._id
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
        
    }
    
    func didBtnLikeClicked(publication: Publication, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
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
                    
                    //print("response from server of dislikePublication : ",json)
                    let responseServer = json["status"] as? NSNumber
                    if responseServer == 1{
                        let publicationCell = cell as! PublicationTableViewCell
                        publication.isLiked = false
                        publication.nbrLikes = publication.nbrLikes! - 1
                        publicationCell.updateDetailsPub(publication: publication, indexPathCell: indexPathCell, tableView: tableView)
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
                    
                    //print("response from server of likePublication : ",json)
                    let responseServer = json["status"] as? NSNumber
                    if responseServer == 1{
                        let publicationCell = cell as! PublicationTableViewCell
                        publication.isLiked = true
                        publication.nbrLikes = publication.nbrLikes! + 1
                        publicationCell.updateDetailsPub(publication: publication, indexPathCell: indexPathCell, tableView: tableView)
    
                    }
                    break
                    
                case .failure(let error):
                    print("error from server : ",error)
                    break
                    
                }
                
            }
        }
    }
    
    func didBtnGetCommentsClicked(_id: String, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        // navigate between Views from Identifier of Storyboard
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "ListCommentsViewController") as! ListCommentsViewController
        
        desVC.publication = arrayPublications[indexPathCell.row]
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
        
    }
    
}


// show toast
extension HomeViewController {
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

// show drop down menu to logout
extension HomeViewController {
    //dropDownBtnAction
    @IBAction func dropDownBtnAction(_ sender: Any) {
        dropDownStatus.show()
    }
    
    func prepareStatusDropDown(){
        DropDown.startListeningToKeyboard()
        dropDownStatus.anchorView = dropDownView
        dropDownStatus.direction = .bottom
        dropDownStatus.bottomOffset = CGPoint(x: 0, y:(dropDownStatus.anchorView?.plainView.bounds.height)!)
        dropDownStatus.dataSource = ["Se déconnecter"]
        dropDownStatus.selectionAction = { (index: Int, item: String) in
            
            if index == 0 {
                // change statut of user in NSUserDefaults
                let userConnected = false
                self.defaults.set(userConnected, forKey: "userStatut")
                // change statut of user in NSUserDefaults
                self.defaults.removeObject(forKey: "objectUser")
                // Init Root View
                var initialViewController : UIViewController?
                self.window = UIWindow(frame: UIScreen.main.bounds)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                var root : UIViewController?
                root = storyboard.instantiateViewController(withIdentifier: "SignInViewController")
                initialViewController = UINavigationController(rootViewController: root!)
                self.window?.rootViewController = initialViewController
                self.window?.makeKeyAndVisible()
                
            }
            
        }
        
    }
}
