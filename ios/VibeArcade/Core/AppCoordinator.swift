import UIKit

class AppCoordinator {
    private let window: UIWindow
    private var navigationController: UINavigationController
    private var authCoordinator: AuthCoordinator?
    private var mainCoordinator: MainCoordinator?

    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }

    func start() {
        window.rootViewController = navigationController

        // Check if user is already authenticated
        if AuthManager.shared.isAuthenticated {
            startMainFlow()
        } else {
            startAuthFlow()
        }
    }

    private func startAuthFlow() {
        authCoordinator = AuthCoordinator(navigationController: navigationController)
        authCoordinator?.delegate = self
        authCoordinator?.start()
    }

    private func startMainFlow() {
        mainCoordinator = MainCoordinator(navigationController: navigationController)
        mainCoordinator?.delegate = self
        mainCoordinator?.start()
    }
}

// MARK: - AuthCoordinatorDelegate
extension AppCoordinator: AuthCoordinatorDelegate {
    func authCoordinatorDidAuthenticate(_ coordinator: AuthCoordinator) {
        authCoordinator = nil
        startMainFlow()
    }
}

// MARK: - MainCoordinatorDelegate
extension AppCoordinator: MainCoordinatorDelegate {
    func mainCoordinatorDidLogout(_ coordinator: MainCoordinator) {
        mainCoordinator = nil
        startAuthFlow()
    }
}