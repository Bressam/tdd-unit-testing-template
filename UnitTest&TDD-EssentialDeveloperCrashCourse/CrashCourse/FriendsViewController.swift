//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation
import UIKit

class FriendsViewController: UITableViewController {
   private let friendsService: FriendsAPI
   private var friends: [Friend] = [] {
       didSet {
           tableView.reloadData()
       }
   }
   
   // D.I. Injection instead of legacy code on other example that we needed to change the service to a public var to inject
   init(friendsService: FriendsAPI) {
       self.friendsService = friendsService
       super.init(nibName: nil, bundle: nil)
   }
   
   // hide required init that will never be used
   @available (*, unavailable)
   required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }
   
   override func viewDidLoad() {
       super.viewDidLoad()
   }
   
   override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(true)
       self.loadFirendsWithRetry()
   }
   
   func loadFirendsWithRetry(retryCount: Int = 0) {
       friendsService.loadFriends { [weak self] friendsResult in
           switch friendsResult {
           case let .success(friends):
               self?.friends = friends
           case let .failure(error):
               if retryCount == 2 {
                   self?.show(error)
               } else {
                   self?.loadFirendsWithRetry(retryCount: retryCount+1)
               }
           }
       }
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return self.friends.count
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       let tableviewCell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
       let friend = self.friends[indexPath.row]
       tableviewCell.textLabel?.text = friend.name
       tableviewCell.detailTextLabel?.text = friend.phone
       return tableviewCell
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       show(self.friends[indexPath.row])
   }
   
}
