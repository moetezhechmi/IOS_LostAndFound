import UIKit

protocol LikeTableViewCellDelegate : class {
    func didLabelNameUserTapped(idUser: String, cell: UITableViewCell, indexPathCell : IndexPath, tableView: UITableView)
}

class LikeTableViewCell: UITableViewCell {

    @IBOutlet weak var imageProfileUser: UIImageView!
    @IBOutlet weak var nameUserLabel: UILabel!
    @IBOutlet weak var dateLikeLabel: UILabel!
    
    var delegateLike: LikeTableViewCellDelegate?
    var like : Like?
    var tableView: UITableView?
    var indexPathCell : IndexPath?
    
    public func loadData(like : Like, indexPathCell : IndexPath, tableView: UITableView) {
        // setup Cell
        self.like = like
        self.indexPathCell = indexPathCell
        self.tableView = tableView
        // setup user data
        self.nameUserLabel.text = like.user.firstName! + " " + like.user.lastName!
        self.imageProfileUser.sd_setImage(with: URL(string: like.user.pictureProfile!))
        self.imageProfileUser.layer.cornerRadius = self.imageProfileUser.frame.size.width/2
        self.imageProfileUser.clipsToBounds = true
        // setup author data
        self.dateLikeLabel.text = like.date
        
        let tapNameUserLabel = UITapGestureRecognizer(target: self, action: #selector(LikeTableViewCell.showProfileOwnerLike))
        nameUserLabel.isUserInteractionEnabled = true
        nameUserLabel.addGestureRecognizer(tapNameUserLabel)
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func showProfileOwnerLike() {
        delegateLike?.didLabelNameUserTapped(idUser: (self.like?.user._id)!, cell: self, indexPathCell: self.indexPathCell!, tableView: self.tableView!)
    }

}
