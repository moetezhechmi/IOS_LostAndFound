
import Foundation

class Sector: NSObject {
    
    var _id : String?
    var nameSector : String?
    var count : Int?
    
    override init() {}
    
    init(_id: String, nameSector: String) {
        self._id = _id
        self.nameSector = nameSector
    
    }
    
    // Parse Request
    init(_ dic : [String : Any])
    {
        if let _id = dic["_id"] as! String? {
            self._id = _id
        }
        if let _nameSector = dic["nameSector"] as! String? {
            self.nameSector = _nameSector
        }
        if let _count = dic["count"] as! Int? {
            self.count = _count
        }

        
    }
    
}
