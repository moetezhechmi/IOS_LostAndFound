

import Foundation

class Publication: NSObject {
    
    var _id : String?
    var title : String?
    var text : String?
    var type_file : String?
    var url_file : String?
    var nom : String?
    var nbrComments: Int?
    var nbrLikes : Int?
    var isLiked : Bool?
    var owner = User()
    var sector = Sector()
    var createdAt : String?
    
    override init() {}
    
    // Parse Request
    init(_ dic : [String : Any])
    {
        if let _id = dic["_id"] as! String? {
            self._id = _id
        }
        if let _title = dic["title"] as! String? {
            self.title = _title
        }
        if let _text = dic["text"] as! String? {
            self.text = _text
        }
        if let _type_file = dic["type_file"] as! String? {
            self.type_file = _type_file
        }
        if let _url_file = dic["url_file"] as! String? {
            self.url_file = _url_file
        }
        if let _nom = dic["nom"] as! String? {
            self.nom = _nom
        }
        if let _text = dic["text"] as! String? {
            self.text = _text
        }
        if let _nbrComments = dic["nbrComments"] as! Int? {
            self.nbrComments = _nbrComments
        }
        if let _nbrLikes = dic["nbrLikes"] as! Int? {
            self.nbrLikes = _nbrLikes
        }
        if let _isLiked = dic["isLiked"] as! Bool? {
            self.isLiked = _isLiked
        }
        if let _owner = dic["owner"] {
            self.owner = User(_owner as! [String : Any])
        }
        if let _sector = dic["sector"] {
            self.sector = Sector(_sector as! [String : Any])
        }
        if let _createdAt = dic["createdAt"] as! String? {
            // parse date
            let formatterParse = DateFormatter()
            formatterParse.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let parsedDate = formatterParse.date(from: _createdAt)
            //get date and month
            let formatterDate = DateFormatter()
            formatterDate.dateStyle = .long
            formatterDate.timeStyle = .short
            let newFormatDate = formatterDate.string(from: parsedDate!)
            self.createdAt = newFormatDate
        }
        
    }
    
}
