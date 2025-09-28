import UIKit

class UserStatsView: UIView {
    private let containerView = UIView()
    private let gamesPlayedLabel = UILabel()
    private let gamesPlayedValueLabel = UILabel()
    private let winRateLabel = UILabel()
    private let winRateValueLabel = UILabel()
    private let ratingLabel = UILabel()
    private let ratingValueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        // Container view
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 12

        // Stats labels
        setupStatLabel(gamesPlayedLabel, text: "Games Played")
        setupStatLabel(winRateLabel, text: "Win Rate")
        setupStatLabel(ratingLabel, text: "Rating")

        setupStatValueLabel(gamesPlayedValueLabel)
        setupStatValueLabel(winRateValueLabel)
        setupStatValueLabel(ratingValueLabel)

        // Add subviews
        addSubview(containerView)
        [gamesPlayedLabel, gamesPlayedValueLabel, winRateLabel, winRateValueLabel,
         ratingLabel, ratingValueLabel].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Set default values
        configure(with: UserStats(
            userId: UUID(),
            gamesPlayed: 0,
            gamesWon: 0,
            gamesLost: 0,
            rating: 1000,
            updatedAt: Date()
        ))
    }

    private func setupStatLabel(_ label: UILabel, text: String) {
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
    }

    private func setupStatValueLabel(_ label: UILabel) {
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 80),

            // Games played
            gamesPlayedValueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            gamesPlayedValueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            gamesPlayedValueLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.0/3.0, constant: -21),

            gamesPlayedLabel.topAnchor.constraint(equalTo: gamesPlayedValueLabel.bottomAnchor, constant: 4),
            gamesPlayedLabel.leadingAnchor.constraint(equalTo: gamesPlayedValueLabel.leadingAnchor),
            gamesPlayedLabel.trailingAnchor.constraint(equalTo: gamesPlayedValueLabel.trailingAnchor),

            // Win rate
            winRateValueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            winRateValueLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            winRateValueLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.0/3.0, constant: -21),

            winRateLabel.topAnchor.constraint(equalTo: winRateValueLabel.bottomAnchor, constant: 4),
            winRateLabel.leadingAnchor.constraint(equalTo: winRateValueLabel.leadingAnchor),
            winRateLabel.trailingAnchor.constraint(equalTo: winRateValueLabel.trailingAnchor),

            // Rating
            ratingValueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            ratingValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            ratingValueLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 1.0/3.0, constant: -21),

            ratingLabel.topAnchor.constraint(equalTo: ratingValueLabel.bottomAnchor, constant: 4),
            ratingLabel.leadingAnchor.constraint(equalTo: ratingValueLabel.leadingAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: ratingValueLabel.trailingAnchor)
        ])
    }

    func configure(with stats: UserStats) {
        gamesPlayedValueLabel.text = "\(stats.gamesPlayed)"
        winRateValueLabel.text = String(format: "%.1f%%", stats.winRate * 100)
        ratingValueLabel.text = "\(stats.rating)"
    }
}