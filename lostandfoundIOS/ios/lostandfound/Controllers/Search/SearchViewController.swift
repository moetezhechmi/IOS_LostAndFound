
import UIKit
import DropDown
import Alamofire

class SearchViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    let dropDownStatus = DropDown()
    var window: UIWindow?
    var arrayAllSectorsForFilter: [Sector] = []
    var arrayResultSearchByTitleAndSector: [Publication] = []
    var arrayResultSearchByTitle = ResultSearch()
    var userConnected = User()
    var currentPageNumber: Int = 1
    var totalNbrPages: Int = 1
    var sectorId: String?
    let sectionTitles = ["","PUBLICATIONS"]
    var sectorChoosed = Sector()
    
    @IBOutlet weak var btnFilterOutlet: UIBarButtonItem!
    @IBOutlet weak var dropDownView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableViewSearchByTitleAndSector: UITableView!
    @IBOutlet weak var tableViewSearchByTitle: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let objectUser = self.defaults.dictionary(forKey: "objectUser")
        self.userConnected = User(objectUser!)
        self.prepareStatusDropDown()
        self.searchBar.becomeFirstResponder()
        self.searchBar.placeholder = "Entrer le titre de la publication ..."
        let nibCell = UINib(nibName: "PublicationTableViewCell", bundle: nil)
        self.tableViewSearchByTitleAndSector.register(nibCell, forCellReuseIdentifier: "PublicationTableViewCell")
        self.tableViewSearchByTitleAndSector.tableFooterView = UIView()
        self.tableViewSearchByTitle.tableFooterView = UIView()
        if ((sectorId) != nil){
            self.tableViewSearchByTitleAndSector.isHidden = false
            self.getListPublicationsBySector(sectorId: sectorId!, pageNumber: 1)
        }
        self.getAllSectors()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
    }
    
    func getAllSectors(){
        Alamofire.request(Constants.getAllSectorsWithNbrOccurences, method: .get,encoding: JSONEncoding.default).responseJSON {
            response in
            switch response.result {
            case .success:
                guard response.result.error == nil else {
                      
                    
                    
                    print("error calling POST")
                    print(response.result.error!)
                    return
                }
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
                                self.arrayAllSectorsForFilter.append(sectorObj)
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

    
    @IBAction func btnFilterSectors(_ sender: Any) {
        view.endEditing(true)
        let alert = UIAlertController(title: "Choisir catégorie", message: nil, preferredStyle: UIAlertController.Style.alert)
        for sectorDic in self.arrayAllSectorsForFilter{
            
            let action = UIAlertAction(title: sectorDic.nameSector! + " " + "(\(sectorDic.count ?? 0))", style: .default, handler: { (action) -> Void in
                self.searchBar.text = ""
                self.arrayResultSearchByTitleAndSector.removeAll()
                self.currentPageNumber = 1
                self.sectorId = sectorDic._id
                self.tableViewSearchByTitle.isHidden = true
                self.tableViewSearchByTitleAndSector.isHidden = false
                self.getListPublicationsBySector(sectorId: self.sectorId!, pageNumber: self.currentPageNumber)
                
            })
            alert.addAction(action)
        }
        // Cancel button
        let cancel = UIAlertAction(title: "Annuler", style: .destructive, handler: { (action) -> Void in })
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    func getResultSearchByTitle(text:String){
        Alamofire.request(Constants.searchAllPublicationsByTitle + text , method: .get, parameters: nil,encoding: JSONEncoding.default).responseJSON {
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
                //print("response from server of searchAllPublicationsByTitle : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    if  let data = json["data"] as? [String:Any]{
                        self.arrayResultSearchByTitle = ResultSearch(data)
                        // refresh tableView
                        self.tableViewSearchByTitle.reloadData()
                    }
                }
                
                break
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }

    }
    
    func getListPublicationsBySector(sectorId: String, pageNumber: Int){
        let postParameters = [
            "q": self.searchBar.text!,
            "sectorId": sectorId,
            "userIdConnected":self.userConnected._id!,
            "page": pageNumber,
            "perPage": Constants.perPageForListing,
            ] as [String : Any]
        //print("postParameters: getListPublicationsBySector", postParameters)
        Alamofire.request(Constants.searchAllPublicationsByTitleAndSector , method: .post, parameters: postParameters,encoding: JSONEncoding.default).responseJSON {
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
                //print("response from server of getListPublicationsBySector : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    if  let data = json["data"] as? [String:Any]{
                        if  let arrayPublications = data["publications"] as? [[String : Any]]{
                            for pubDic in arrayPublications {
                                let publication = Publication(pubDic)
                                self.arrayResultSearchByTitleAndSector.append(publication)
                            }
                        }
                        if let nbrTotalOfPages = data["pages"] as? Int{
                            self.totalNbrPages = nbrTotalOfPages
                        }
                        self.currentPageNumber += 1
                        // refresh tableView
                        self.tableViewSearchByTitleAndSector.reloadData()
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
                    // remove publication from arrayResultSearchByTitleAndSector
                    self.arrayResultSearchByTitleAndSector.remove(at: indexPathCell)
                    // reload tableViewSearchByTitleAndSector
                    self.tableViewSearchByTitleAndSector.reloadData()
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

// delegate searchBar
extension SearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.count > 1){
            self.tableViewSearchByTitle.isHidden = false
            self.tableViewSearchByTitleAndSector.isHidden = true
            self.getResultSearchByTitle(text:searchText)
        }else{
            self.tableViewSearchByTitle.isHidden = true
            self.tableViewSearchByTitleAndSector.isHidden = true
        }
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.endEditing(true)
        
    }
    
}

// delegate tableView
extension SearchViewController: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(tableView == self.tableViewSearchByTitle) {
            return 50
        }else{
            var height:CGFloat = CGFloat()
            if ((arrayResultSearchByTitleAndSector[indexPath.row].type_file ) != nil){
                height = 455
                
            }else{
                height = 260
            }
            return height
        }

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.tableViewSearchByTitle){
            if (section == 0){
                return self.arrayResultSearchByTitle.sectors.count
            }else{
                return self.arrayResultSearchByTitle.publications.count
            }
        }else{
            return self.arrayResultSearchByTitleAndSector.count
        }

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if(tableView == self.tableViewSearchByTitle) {
            return self.sectionTitles.count
        }else{
            return 1
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(tableView == self.tableViewSearchByTitle) {
            return 55
        }else{
            return 0
        }
     
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")
        if (tableView == self.tableViewSearchByTitle) {
            cell!.textLabel?.text = sectionTitles[section]
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (tableView == self.tableViewSearchByTitle) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContentCell", for: indexPath)
            if (indexPath.section == 0){
                cell.textLabel?.text = self.arrayResultSearchByTitle.sectors[indexPath.row].nameSector
            }else{
                cell.textLabel?.text = self.arrayResultSearchByTitle.publications[indexPath.row].title
            }
            return cell
            
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PublicationTableViewCell", for: indexPath) as! PublicationTableViewCell
            if(arrayResultSearchByTitleAndSector[indexPath.row].owner._id == self.userConnected._id) {
                cell.btnDeletePubOutlet.isHidden = false
            }else{
                cell.btnDeletePubOutlet.isHidden = true
                
            }
            cell.loadData(publication: arrayResultSearchByTitleAndSector[indexPath.row], indexPathCell: indexPath, tableView: tableView)
            cell.delegatePublication = self // lisener to action btn
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView == self.tableViewSearchByTitle){
            if (indexPath.section == 0){
                // clik in sector
                // hide Keyboard
                view.endEditing(true)
                // get all pubications by sector cliked
                self.arrayResultSearchByTitleAndSector.removeAll()
                self.currentPageNumber = 1
                self.sectorId = self.arrayResultSearchByTitle.sectors[indexPath.row].nameSector!
                // hide tableViewSearchByTitle
                self.tableViewSearchByTitle.isHidden = true
                // show tableViewSearchByTitleAndSector
                self.tableViewSearchByTitleAndSector.isHidden = false
                // show publications by sector
                self.getListPublicationsBySector(sectorId: self.arrayResultSearchByTitle.sectors[indexPath.row]._id!, pageNumber: self.currentPageNumber)
            }else{
                // navigate to publication details
                // navigate between Views from Identifier of Storyboard
                let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let desVC = MainStory.instantiateViewController(withIdentifier: "PublicationDetailsViewController") as! PublicationDetailsViewController
                
                desVC.idPublicationReceived = self.arrayResultSearchByTitle.publications[indexPath.row]._id!
                // push navigationController
                self.navigationController?.pushViewController(desVC, animated: true)
            }
            
        }else{
            // navigate to publication details
            // navigate between Views from Identifier of Storyboard
            let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let desVC = MainStory.instantiateViewController(withIdentifier: "PublicationDetailsViewController") as! PublicationDetailsViewController
            
            desVC.publication = self.arrayResultSearchByTitleAndSector[indexPath.row]
            // push navigationController
            self.navigationController?.pushViewController(desVC, animated: true)

        }


    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // for pagination tableViewSearchByTitleAndSector
        if (tableView == self.tableViewSearchByTitleAndSector){
            if indexPath.row == arrayResultSearchByTitleAndSector.count - 1 && (self.totalNbrPages >= self.currentPageNumber) {
                self.getListPublicationsBySector(sectorId: sectorId!,pageNumber: self.currentPageNumber)
            }
        }

    }
    
    
}

// delegate functions of PublicationTableViewCell
extension SearchViewController : PublicationTableViewCellDelegate {
    
    func didBtnDeletePubClicked(publication: Publication, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        // show alerte
        let alert = UIAlertController(title: "Attention",message: "Vous-ête sure de supprimer cette  publication?" ,preferredStyle: .alert)
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
        // we will not execute this function because the user is already in the current sector
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
        
        desVC.publication = arrayResultSearchByTitleAndSector[indexPathCell.row]
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
        
    }
    
}


// show toast
extension SearchViewController {
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
extension SearchViewController {
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

