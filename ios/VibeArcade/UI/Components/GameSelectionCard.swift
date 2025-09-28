import UIKit

class GameSelectionCard: UIView {
    private let gameType: GameType
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let playButton = UIButton(type: .system)

    var onTap: (() -> Void)?

    init(gameType: GameType) {
        self.gameType = gameType
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        // Container view
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1

        // Icon
        iconImageView.image = UIImage(systemName: gameType.icon)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit

        // Title
        titleLabel.text = gameType.displayName
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label

        // Subtitle
        switch gameType {
        case .dominoes:
            subtitleLabel.text = "Classic tile-matching game"
        case .chess:
            subtitleLabel.text = "Strategic board game"
        }
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        // Play button
        playButton.setTitle("Play", for: .normal)
        playButton.backgroundColor = .systemBlue
        playButton.setTitleColor(.white, for: .normal)
        playButton.layer.cornerRadius = 6
        playButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

        // Add subviews
        addSubview(containerView)
        [iconImageView, titleLabel, subtitleLabel, playButton].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 100),

            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: playButton.leadingAnchor, constant: -16),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: playButton.leadingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),

            // Play button
            playButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            playButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true

        playButton.addTarget(self, action: #selector(cardTapped), for: .touchUpInside)
    }

    @objc private func cardTapped() {
        // Add visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
            }
        }

        onTap?()
    }
}