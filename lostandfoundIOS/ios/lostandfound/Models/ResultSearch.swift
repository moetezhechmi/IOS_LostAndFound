
import Foundation

class ResultSearch:NSObject {
    
    var sectors : [Sector] = []
    var publications : [Publication] = []
    
    // Init Object
    override init() {}
    
    // Parse Request
    init(_ dic : [String : Any])
    {
        if let _sectors = dic["sectors"] as? [[String: AnyObject]] {
            self.sectors = [Sector]()
            for pst in _sectors {
                self.sectors.append(Sector(pst))
                
            }
            
        }
        if let _publications = dic["publication"] as? [[String: AnyObject]] {
            self.publications = [Publication]()
            for pst in _publications {
                self.publications.append(Publication(pst))
                
            }
            
        }
        
    }
}
