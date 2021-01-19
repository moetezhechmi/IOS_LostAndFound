
import Foundation

class Comment: NSObject {
    
    var _id : String?
    var text : String?
    var author = User()
    var date : String?
    
    override init() {}
    
    // Parse Request
    init(_ dic : [String : Any])
    {
        if let _id = dic["_id"] as! String? {
            self._id = _id
        }
        if let _text = dic["text"] as! String? {
            self.text = _text
        }
        if let _author = dic["author"] {
            self.author = User(_author as! [String : Any])
        }
        if let _date = dic["date"] as? String {
            // parse date
            let formatterParse = DateFormatter()
            formatterParse.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let parsedDate = formatterParse.date(from: _date)
            //get date and month
            let formatterDate = DateFormatter()
            formatterDate.dateStyle = .long
            formatterDate.timeStyle = .short
            let newFormatDate = formatterDate.string(from: parsedDate!)
            self.date = newFormatDate
        }
        
    }
    
}
