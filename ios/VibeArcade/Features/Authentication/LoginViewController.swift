import UIKit
import Combine

class LoginViewController: UIViewController {
    weak var coordinator: AuthCoordinator?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let registerButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Title
        titleLabel.text = "Welcome to Vibe Arcade"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        // Email field
        emailTextField.placeholder = "Email"
        emailTextField.borderStyle = .roundedRect
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no

        // Password field
        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true

        // Login button
        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        // Register button
        registerButton.setTitle("Don't have an account? Sign up", for: .normal)
        registerButton.setTitleColor(.systemBlue, for: .normal)
        registerButton.titleLabel?.font = .systemFont(ofSize: 14)

        // Loading indicator
        loadingIndicator.hidesWhenStopped = true

        // Add to scroll view
        scrollView.addSubview(contentView)
        [titleLabel, emailTextField, passwordTextField, loginButton, registerButton, loadingIndicator].forEach {
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

            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            // Email field
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),

            // Password field
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),

            // Login button
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            loginButton.heightAnchor.constraint(equalToConstant: 48),

            // Register button
            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            registerButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),

            // Content view bottom
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: registerButton.bottomAnchor, constant: 40)
        ])
    }

    private func setupBindings() {
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        // Add text field delegates for return key handling
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }

    @objc private func loginTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields")
            return
        }

        setLoading(true)

        AuthManager.shared.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    if case .failure(let error) = completion {
                        self?.showAlert(title: "Login Failed", message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.coordinator?.didCompleteAuthentication()
                }
            )
            .store(in: &cancellables)
    }

    @objc private func registerTapped() {
        coordinator?.showRegisterScreen()
    }

    private func setLoading(_ loading: Bool) {
        loginButton.isEnabled = !loading
        registerButton.isEnabled = !loading
        emailTextField.isEnabled = !loading
        passwordTextField.isEnabled = !loading

        if loading {
            loginButton.setTitle("", for: .normal)
            loadingIndicator.startAnimating()
        } else {
            loginButton.setTitle("Login", for: .normal)
            loadingIndicator.stopAnimating()
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginTapped()
        }
        return true
    }
}