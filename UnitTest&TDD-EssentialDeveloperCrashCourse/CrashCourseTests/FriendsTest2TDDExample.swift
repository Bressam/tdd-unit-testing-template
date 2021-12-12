//
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse

// OBS.: Remember that if you disable debugger on this scheme it runs faster
// Service Test Doubles naming convention: http://xunitpatterns.com/Mocks,%20Fakes,%20Stubs%20and%20Dummies.html
//  ...ServiceDummy - Does nothing and returns nothing. Only that has no behavior
//  ...ServiceStub - Verify indirect inputs of SUT
//                  -> Injects indirect inputs into SUT: Yes
//                  -> Handles indirect outputs of SUT: No, ignore them
//                  -> Values provided by test code: inputs
//  ...ServiceSpy - Verify indirect outputs of SUT
//                  -> Watchs the methods and store information. E.x.: Number o calls from fetch function.
//                  -> Injects indirect inputs into SUT: Yes
//                  -> Handles indirect outputs of SUT: SUT Outputs: Yes, captures them for later verification
//                  -> Values provided by test code: inputs (optional)
//  ...ServiceMock - Verify indirect outputs of SUT
//                  -> Injects indirect inputs into SUT: Yes (optional)
//                  -> Handles indirect outputs of SUT: Yes, Verify correctness of data regarding expected result
//                  -> Values provided by test code: Outputs & inputs(optional)
//  ...ServiceFake - Run (unrunnable) tests (faster)
//                  -> Injects indirect inputs into SUT: No;
//                  -> Handles indirect outputs of SUT: Yes, uses them;
//                  -> Ex.: In-memory database emulator


//MARK: TDD Class developed just for example. Develop here then move to production when finished
/*
    Functionalities to be implemented by TDD:
    * Load friends from API on WillAppear;
    * If successful: Show friends
    * If failed:
        * Retry twice:
            * If all tries fail: show error
            * If a retry succeeds: show friends
    * On selection: show friend detail
 */
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


// MARK: Service Test Doubles
/// Holds count of api calls to check lifecycle
private class FriendsServiceSpy: FriendsAPI {
    private(set) var loadFriendsCount = 0
    private var results: [Result<[Friend], Error>]
    
    init(result: [Friend] = []) {
        self.results = [.success(result)]
    }
    
    init(results: [Result<[Friend], Error>]) {
        self.results = results
    }
    
    override func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        loadFriendsCount += 1
        // removeFirst pops the element and return it
        completion(results.removeFirst())
    }
}


//MARK: Test
class FriendsTDDTests: XCTestCase {
    
    //Test if service is called at right lifecycle moment
    func test_viewDidLoad_doesNotLoadFriendsFromAPI() {
        //Arrange
        let service = FriendsServiceSpy()
        let sut = FriendsViewController(friendsService: service)
        
        //Act
        sut.loadViewIfNeeded()
        
        //Assert
        XCTAssertEqual(service.loadFriendsCount, 0)
    }
    
    //Test if service is called at right lifecycle moment
    func test_viewWillAppear_doesLoadFriendsFromAPI() {
        //Arrange
        let service = FriendsServiceSpy()
        let sut = FriendsViewController(friendsService: service)
        
        //Act
        sut.simulateWillAppear()

        
        //Assert
        XCTAssertEqual(service.loadFriendsCount, 1)
    }
    
    func test_viewWillAppear_successfulAPIResponse_showsFriends() {
        //Arrange
        let friends = [makeFriend(name: "Friend1", phone: "phone1"),
                       makeFriend(name: "Friend2", phone: "phone2")]
        let service = FriendsServiceSpy(result: friends)
        let sut = FriendsViewController(friendsService: service)
        
        //Act
        sut.simulateWillAppear()

        
        //Assert
        sut.assert(isRendering: friends)
        
        
// BAD EXAMPLE:
        // Would need to set frame so iOS handles cells, need frame that fits cell
        //        sut.view.frame = CGRect(x: 0, y: 0, width: 2000, height: 2000)
        // but this cause a bunch of events that will slow down the test
        
//        // check each cell from UI

//        let cell1 = sut.tableView.cellForRow(at: IndexPath(row: 0, section: 0))
//        XCTAssertEqual(cell1?.textLabel?.text, "Friend1")
//        XCTAssertEqual(cell1?.detailTextLabel?.text, "phone1")
//
//        let cell2 = sut.tableView.cellForRow(at: IndexPath(row: 1, section: 0))
//        XCTAssertEqual(cell2?.textLabel?.text, "Friend2")
//        XCTAssertEqual(cell2?.detailTextLabel?.text, "phone2")
//
    }
    
    func test_viewWillAppear_failedAPIResponse_3times_showsError() {
        let service = FriendsServiceSpy(results:
                                            [.failure(AnyError(errorDescription: "1st error")),
                                             .failure(AnyError(errorDescription: "2nd error")),
                                             .failure(AnyError(errorDescription: "3rd error"))]
        )
        let sut = TestableFriendsViewController(friendsService: service)

        sut.simulateWillAppear()

        XCTAssertEqual(sut.errorMessage(), "3rd error")
    }
    
    func test_viewWillAppear_successAfterFailedAPIResponse_1time_showsFriends() {
        let friends = [makeFriend()]
        let service = FriendsServiceSpy(results:
                                            [.failure(AnyError(errorDescription: "1st error")),
                                             .success(friends)
                                            ])
        let sut = TestableFriendsViewController(friendsService: service)

        sut.simulateWillAppear()

        sut.assert(isRendering: friends)
    }
    
    func test_viewWillAppear_successAfterFailedAPIResponse_2times_showsFriends() {
        let friends = [makeFriend()]
        let service = FriendsServiceSpy(results:
                                            [.failure(AnyError(errorDescription: "1st error")),
                                             .failure(AnyError(errorDescription: "2nd error")),
                                             .success(friends)
                                            ])
        let sut = TestableFriendsViewController(friendsService: service)

        sut.simulateWillAppear()

        sut.assert(isRendering: friends)
    }
    
    func test_friendSelection_showsFriendDetails() {
        let friend = makeFriend()
        let service = FriendsServiceSpy(results:
                                            [.failure(AnyError(errorDescription: "1st error")),
                                             .failure(AnyError(errorDescription: "2nd error")),
                                             .success([friend])
                                            ])
        let sut = TestableFriendsViewController(friendsService: service)
        let navigation = NonAnimatedNavigationController(rootViewController: sut)

        sut.simulateWillAppear()

        sut.selectFriend(at: 0)
        let detailView = navigation.topViewController as? FriendDetailsViewController
        XCTAssertEqual(detailView?.friend, friend)
        
    }
}

private struct AnyError: LocalizedError {
    var errorDescription: String?
}

//MARK: Class to test ui presentation
private class NonAnimatedNavigationController: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: false)
    }
}

private class TestableFriendsViewController: FriendsViewController {
    
    var presentedVC: UIViewController?
    
    func errorMessage() -> String? {
        let alertMessage = presentedVC as? UIAlertController
        return alertMessage?.message
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedVC = viewControllerToPresent
    }
}

// MARK: Extensions
// Private extension, only exists here in tests scope, to trigger needed events. Handle all test specific things
private extension FriendsViewController {
    private var friendsSection : Int { 0 }
    
    func assert(isRendering friends: [Friend]) {
        XCTAssertEqual(numberOfFriends(), friends.count)
        
        for (index, friend) in friends.enumerated() {
            XCTAssertEqual(friendName(at: index), friend.name)
            XCTAssertEqual(friendPhone(at: index), friend.phone)
        }
    }
    
    func simulateWillAppear() {
        loadViewIfNeeded()
        beginAppearanceTransition(true, animated: false)
    }
    
    // So if tableview change to other type, ex. collectionView, all tests are updated from this function change only
    func numberOfFriends() -> Int {
        tableView.numberOfRows(inSection: friendsSection)
    }
    
    func friendName(at row: Int) -> String? {
        friendCell(at: row)?.textLabel?.text
    }
    
    func friendPhone(at row: Int) -> String? {
        friendCell(at: row)?.detailTextLabel?.text
    }
    
    //Access datasource of tableview, so it can be on any viewmodel/controller not on this sut
    func friendCell(at row: Int) -> UITableViewCell? {
        let indexPath = IndexPath(row: row, section: friendsSection)
        return tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }
    
    func selectFriend(at row: Int) {
        let indexPath = IndexPath(row: row, section: friendsSection)
        tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }
}


// MARK: Create objects
private func makePremiumUser() -> User {
    User(id: UUID(), name: "a name", isPremium: true)
}

private func makeFriend(name: String = "Friend1", phone: String = "phone1") -> Friend {
    Friend(id: UUID(), name: name, phone: phone)
}

