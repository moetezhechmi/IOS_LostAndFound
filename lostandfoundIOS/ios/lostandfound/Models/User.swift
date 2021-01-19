import Foundation

class User: NSObject {
    
    var _id : String?
    var email : String?
    var firstName : String?
    var lastName: String?
    var age : String?
    var gender : String?
    var pictureProfile : String?
    var createdAt : String?
    
    override init() {}
    
    // Parse Request
    init(_ dic : [String : Any])
    {
        if let _id = dic["_id"] as! String? {
            self._id = _id
        }
        if let _email = dic["email"] as! String? {
            self.email = _email
        }
        if let _firstName = dic["firstName"] as! String? {
            self.firstName = _firstName
        }
        if let _lastName = dic["lastName"] as! String? {
            self.lastName = _lastName
        }
        if let _age = dic["age"] as! String? {
            self.age = _age
        }
        if let _gender = dic["gender"] as! String? {
            self.gender = _gender
        }
        if let _pictureProfile = dic["pictureProfile"] as! String? {
            self.pictureProfile = _pictureProfile
        }
        if let _createdAt = dic["createdAt"] as! String? {
            // parse date of date of creation
            let formatterParse = DateFormatter()
            formatterParse.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            let parsedDate = formatterParse.date(from: _createdAt)
            //get date and month
            let formatterDate = DateFormatter()
            formatterDate.dateStyle = .long
            formatterDate.timeStyle = .none
            formatterDate.dateFormat = "yyyy-MM-dd"
            let newFormatDate = formatterDate.string(from: parsedDate!)
            self.createdAt = newFormatDate
        }
        
    }

}
