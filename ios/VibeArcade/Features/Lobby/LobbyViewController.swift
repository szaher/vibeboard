import UIKit
import Combine

class LobbyViewController: UIViewController {
    weak var coordinator: MainCoordinator?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let welcomeLabel = UILabel()
    private let userStatsView = UserStatsView()
    private let gameSelectionLabel = UILabel()
    private let dominoesCard = GameSelectionCard(gameType: .dominoes)
    private let chessCard = GameSelectionCard(gameType: .chess)
    private let quickActionsLabel = UILabel()
    private let myGamesButton = UIButton(type: .system)
    private let profileButton = UIButton(type: .system)

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        loadUserProfile()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserProfile()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Vibe Arcade"

        // Navigation bar setup
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )

        // Welcome label
        welcomeLabel.font = .systemFont(ofSize: 24, weight: .bold)
        welcomeLabel.textAlignment = .center
        welcomeLabel.numberOfLines = 0

        // Game selection label
        gameSelectionLabel.text = "Choose Your Game"
        gameSelectionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        gameSelectionLabel.textAlignment = .center

        // Quick actions label
        quickActionsLabel.text = "Quick Actions"
        quickActionsLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        quickActionsLabel.textAlignment = .center

        // My games button
        myGamesButton.setTitle("My Games", for: .normal)
        myGamesButton.backgroundColor = .systemBlue
        myGamesButton.setTitleColor(.white, for: .normal)
        myGamesButton.layer.cornerRadius = 8
        myGamesButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        // Profile button
        profileButton.setTitle("Profile & Stats", for: .normal)
        profileButton.backgroundColor = .systemGray5
        profileButton.setTitleColor(.systemBlue, for: .normal)
        profileButton.layer.cornerRadius = 8
        profileButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        // Add to scroll view
        scrollView.addSubview(contentView)
        [welcomeLabel, userStatsView, gameSelectionLabel, dominoesCard, chessCard,
         quickActionsLabel, myGamesButton, profileButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Welcome label
            welcomeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            welcomeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // User stats view
            userStatsView.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
            userStatsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            userStatsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Game selection label
            gameSelectionLabel.topAnchor.constraint(equalTo: userStatsView.bottomAnchor, constant: 30),
            gameSelectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gameSelectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Game cards
            dominoesCard.topAnchor.constraint(equalTo: gameSelectionLabel.bottomAnchor, constant: 20),
            dominoesCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dominoesCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            chessCard.topAnchor.constraint(equalTo: dominoesCard.bottomAnchor, constant: 16),
            chessCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            chessCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Quick actions label
            quickActionsLabel.topAnchor.constraint(equalTo: chessCard.bottomAnchor, constant: 30),
            quickActionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickActionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Buttons
            myGamesButton.topAnchor.constraint(equalTo: quickActionsLabel.bottomAnchor, constant: 20),
            myGamesButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            myGamesButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            myGamesButton.heightAnchor.constraint(equalToConstant: 48),

            profileButton.topAnchor.constraint(equalTo: myGamesButton.bottomAnchor, constant: 12),
            profileButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            profileButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            profileButton.heightAnchor.constraint(equalToConstant: 48),

            // Content view bottom
            contentView.bottomAnchor.constraint(equalTo: profileButton.bottomAnchor, constant: 40)
        ])
    }

    private func setupBindings() {
        dominoesCard.onTap = { [weak self] in
            self?.gameSelected(.dominoes)
        }

        chessCard.onTap = { [weak self] in
            self?.gameSelected(.chess)
        }

        myGamesButton.addTarget(self, action: #selector(myGamesTapped), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
    }

    private func loadUserProfile() {
        AuthManager.shared.loadProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load profile: \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.updateUI()
                }
            )
            .store(in: &cancellables)
    }

    private func updateUI() {
        guard let user = AuthManager.shared.currentUser else { return }
        welcomeLabel.text = "Welcome back, \(user.username)!"

        // Load user stats from API and update userStatsView
        loadUserStats()
    }

    private func loadUserStats() {
        NetworkService.shared.get<ProfileResponse>(endpoint: .profile)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] response in
                    self?.userStatsView.configure(with: response.stats)
                }
            )
            .store(in: &cancellables)
    }

    private func gameSelected(_ gameType: GameType) {
        let alert = UIAlertController(title: gameType.displayName, message: "How would you like to play?", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Quick Match", style: .default) { [weak self] _ in
            self?.coordinator?.showMatchmaking(for: gameType)
        })

        alert.addAction(UIAlertAction(title: "Create Game", style: .default) { [weak self] _ in
            self?.createGame(type: gameType)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func createGame(type: GameType) {
        let request = CreateGameRequest(gameType: type.rawValue)

        NetworkService.shared.post<Game, CreateGameRequest>(endpoint: .createGame, body: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showAlert(title: "Error", message: "Failed to create game: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] game in
                    self?.showGameScreen(for: game)
                }
            )
            .store(in: &cancellables)
    }

    private func showGameScreen(for game: Game) {
        switch game.type {
        case .dominoes:
            coordinator?.showDominoesGame(gameId: game.id)
        case .chess:
            coordinator?.showChessGame(gameId: game.id)
        }
    }

    @objc private func myGamesTapped() {
        coordinator?.showGamesList()
    }

    @objc private func profileTapped() {
        coordinator?.showProfile()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}