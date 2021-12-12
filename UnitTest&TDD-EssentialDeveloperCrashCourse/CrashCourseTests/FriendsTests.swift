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
class FriendsTests: XCTestCase {    
    // Test is usually structured in the 3 following steps.
    // Funciton always starting with "test" and super detailed name
    func test_reloadFriends_asPremiumUser_withoutConnection_showsError() {
        // Arrange/Given
        let service = FriendsServiceStub(result: .success([
            makeFriend(),
            makeFriend()
        ]))
        let sut = TestableListViewController() // sut = system under test
        sut.user = makePremiumUser()
        sut.fromFriendsScreen = true
        sut.friendsService = service
        
        // Act/When
            // test view appearing
        sut.simulateFirstRequest()
            // test error showing correct modal
        service.result = .failure(AnyError())
        sut.simulateReloadRequest()
        
        // Assert / Then
            // test if tableview shows same number of data from service result
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 2)
            // testing alert shown type
        XCTAssertTrue(sut.presentedVC is UIAlertController)
            // testing alert title, message, etc
        let errorAlert = sut.presentedVC as? UIAlertController
        XCTAssertEqual(errorAlert?.title, "Error")
    }

}

// Just a random test error to be used on tests
private struct AnyError : Error {}

// Testable subclass used just to capture values needed. Now overriding present method to capture presented alert
private class TestableListViewController: ListViewController {
    var presentedVC: UIViewController?
    
    // do not call super to avoid weird behavior. We just want to capture the presented modal to know which error appeared
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedVC = viewControllerToPresent
    }
}

// MARK: Extensions
// Private extension, only exists here in tests scope, to trigger needed events
private extension ListViewController {
    // Just loads the view and simulate its displaying, calling will appear and other lifecycle events
    func simulateFirstRequest() {
        loadViewIfNeeded()
        beginAppearanceTransition(true, animated: false)
    }
    
    //triggers refresh control event to check if it is configured correct
    func simulateReloadRequest() {
        refreshControl?.sendActions(for: .valueChanged)
    }
}

private func makePremiumUser() -> User {
    User(id: UUID(), name: "a name", isPremium: true)
}

private func makeFriend(name: String = "Friend1", phone: String = "phone1") -> Friend {
    Friend(id: UUID(), name: name, phone: phone)
}


// MARK: Service Test Doubles
// Mockable version of FriendsAPI
// Will always return the result provided
private class FriendsServiceStub: FriendsAPI {
    var result: Result<[Friend], Error>
    
    init(result: Result<[Friend], Error>) {
        self.result = result
    }
    
    override func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        completion(result)
    }
}
