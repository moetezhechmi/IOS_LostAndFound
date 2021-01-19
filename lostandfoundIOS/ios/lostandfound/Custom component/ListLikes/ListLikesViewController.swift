import UIKit
import Alamofire

class ListLikesViewController: UIViewController {
    
    var idPublication = String()
    var arrayLikes: [Like] = []
    var currentPageNumber: Int = 1
    var totalNbrPages: Int = 1
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var tableListLikes: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Apply radius to popupView
        popupView.layer.cornerRadius = 10
        popupView.layer.masksToBounds = true
        // remove extra empty cells
        self.tableListLikes.tableFooterView = UIView()
        self.getLikes(pageNumber: self.currentPageNumber)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar for current view controller
        self.navigationController?.isNavigationBarHidden = true;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.isNavigationBarHidden = false;
    }
    
    func getLikes(pageNumber:Int){
        let postParameters = [
            "publicationId": self.idPublication,
            "perPage": Constants.perPageForListing,
            "page": pageNumber,
            ] as [String : Any]
        //print("postParameters in getLikesByPublication",postParameters)
        Alamofire.request(Constants.getLikesByPublication, method: .post, parameters: postParameters as Parameters,encoding: JSONEncoding.default).responseJSON {
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
                
                //print("response from server of getLikesByPublication : ",json)
                let responseServer = json["status"] as? NSNumber
                if responseServer == 1{
                    if  let data = json["data"] as? [String:Any]{
                        if  let listeLikesData = data["likes"] as? [[String : Any]]{
                            for likeDic in listeLikesData {
                                let likeObj = Like(likeDic)
                                self.arrayLikes.append(likeObj)
                            }
                            
                        }
                        if let nbrTotalOfPages = data["Totalpages"] as? Int{
                            self.totalNbrPages = nbrTotalOfPages
                        }
                        self.currentPageNumber += 1
                        // refresh tableView
                        self.tableListLikes.reloadData()
                    }
                }
                break
                
            case .failure(let error):
                print("error from server : ",error)
                break
                
            }
            
        }
    }
    
    @IBAction func dismissBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }

}

extension ListLikesViewController: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrayLikes.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LikeCell", for: indexPath) as! LikeTableViewCell
        cell.loadData(like: arrayLikes[indexPath.row], indexPathCell: indexPath, tableView: tableView)
        cell.delegateLike = self // lisener to action to name user
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // for pagination
        if indexPath.row == arrayLikes.count - 1 && (self.totalNbrPages >= self.currentPageNumber) {
            getLikes(pageNumber: self.currentPageNumber)
        }
    }
    
}

extension ListLikesViewController : LikeTableViewCellDelegate {
    func didLabelNameUserTapped(idUser: String, cell: UITableViewCell, indexPathCell: IndexPath, tableView: UITableView) {
        print("idUser tapped:", idUser )
        // navigate between Views from Identifier of Storyboard
        let MainStory:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = MainStory.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        // send data to desCV
        desVC.idUserReceived = idUser
        // push navigationController
        self.navigationController?.pushViewController(desVC, animated: true)
        
    }
    
    
    
}
