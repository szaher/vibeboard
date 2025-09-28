import UIKit

protocol AuthCoordinatorDelegate: AnyObject {
    func authCoordinatorDidAuthenticate(_ coordinator: AuthCoordinator)
}

class AuthCoordinator {
    private let navigationController: UINavigationController
    weak var delegate: AuthCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showLoginScreen()
    }

    private func showLoginScreen() {
        let loginViewController = LoginViewController()
        loginViewController.coordinator = self
        navigationController.setViewControllers([loginViewController], animated: false)
    }

    func showRegisterScreen() {
        let registerViewController = RegisterViewController()
        registerViewController.coordinator = self
        navigationController.pushViewController(registerViewController, animated: true)
    }

    func didCompleteAuthentication() {
        delegate?.authCoordinatorDidAuthenticate(self)
    }
}