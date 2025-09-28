import UIKit

protocol MainCoordinatorDelegate: AnyObject {
    func mainCoordinatorDidLogout(_ coordinator: MainCoordinator)
}

class MainCoordinator {
    private let navigationController: UINavigationController
    weak var delegate: MainCoordinatorDelegate?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showLobbyScreen()
    }

    private func showLobbyScreen() {
        let lobbyViewController = LobbyViewController()
        lobbyViewController.coordinator = self
        navigationController.setViewControllers([lobbyViewController], animated: false)
    }

    func showProfile() {
        let profileViewController = ProfileViewController()
        profileViewController.coordinator = self
        let navController = UINavigationController(rootViewController: profileViewController)
        navigationController.present(navController, animated: true)
    }

    func showGamesList() {
        let gamesListViewController = GamesListViewController()
        gamesListViewController.coordinator = self
        navigationController.pushViewController(gamesListViewController, animated: true)
    }

    func showDominoesGame(gameId: UUID) {
        let dominoesViewController = DominoesGameViewController(gameId: gameId)
        dominoesViewController.coordinator = self
        navigationController.pushViewController(dominoesViewController, animated: true)
    }

    func showChessGame(gameId: UUID) {
        let chessViewController = ChessGameViewController(gameId: gameId)
        chessViewController.coordinator = self
        navigationController.pushViewController(chessViewController, animated: true)
    }

    func showMatchmaking(for gameType: GameType) {
        let matchmakingViewController = MatchmakingViewController(gameType: gameType)
        matchmakingViewController.coordinator = self
        navigationController.pushViewController(matchmakingViewController, animated: true)
    }

    func didLogout() {
        delegate?.mainCoordinatorDidLogout(self)
    }

    func popToLobby() {
        navigationController.popToRootViewController(animated: true)
    }
}