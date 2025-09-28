import UIKit
import Combine

class RegisterViewController: UIViewController {
    weak var coordinator: AuthCoordinator?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let emailTextField = UITextField()
    private let usernameTextField = UITextField()
    private let passwordTextField = UITextField()
    private let confirmPasswordTextField = UITextField()
    private let registerButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
        setupNavigation()
    }

    private func setupNavigation() {
        title = "Sign Up"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Title
        titleLabel.text = "Create Account"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center

        // Email field
        emailTextField.placeholder = "Email"
        emailTextField.borderStyle = .roundedRect
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no

        // Username field
        usernameTextField.placeholder = "Username"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no

        // Password field
        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true

        // Confirm password field
        confirmPasswordTextField.placeholder = "Confirm Password"
        confirmPasswordTextField.borderStyle = .roundedRect
        confirmPasswordTextField.isSecureTextEntry = true

        // Register button
        registerButton.setTitle("Create Account", for: .normal)
        registerButton.backgroundColor = .systemBlue
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 8
        registerButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        // Login button
        loginButton.setTitle("Already have an account? Sign in", for: .normal)
        loginButton.setTitleColor(.systemBlue, for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 14)

        // Loading indicator
        loadingIndicator.hidesWhenStopped = true

        // Add to scroll view
        scrollView.addSubview(contentView)
        [titleLabel, emailTextField, usernameTextField, passwordTextField,
         confirmPasswordTextField, registerButton, loginButton, loadingIndicator].forEach {
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),

            // Email field
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),

            // Username field
            usernameTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            usernameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            usernameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),

            // Password field
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),

            // Confirm password field
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 16),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 44),

            // Register button
            registerButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 24),
            registerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            registerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            registerButton.heightAnchor.constraint(equalToConstant: 48),

            // Login button
            loginButton.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 16),
            loginButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: registerButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: registerButton.centerYAnchor),

            // Content view bottom
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: loginButton.bottomAnchor, constant: 40)
        ])
    }

    private func setupBindings() {
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        // Add text field delegates for return key handling
        emailTextField.delegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }

    @objc private func registerTapped() {
        guard validateInput() else { return }

        let email = emailTextField.text!
        let username = usernameTextField.text!
        let password = passwordTextField.text!

        setLoading(true)

        AuthManager.shared.register(email: email, username: username, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    if case .failure(let error) = completion {
                        self?.showAlert(title: "Registration Failed", message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.coordinator?.didCompleteAuthentication()
                }
            )
            .store(in: &cancellables)
    }

    @objc private func loginTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func validateInput() -> Bool {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email")
            return false
        }

        guard email.contains("@") else {
            showAlert(title: "Error", message: "Please enter a valid email address")
            return false
        }

        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(title: "Error", message: "Please enter a username")
            return false
        }

        guard username.count >= 3 else {
            showAlert(title: "Error", message: "Username must be at least 3 characters")
            return false
        }

        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a password")
            return false
        }

        guard password.count >= 6 else {
            showAlert(title: "Error", message: "Password must be at least 6 characters")
            return false
        }

        guard let confirmPassword = confirmPasswordTextField.text,
              password == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match")
            return false
        }

        return true
    }

    private func setLoading(_ loading: Bool) {
        [registerButton, loginButton].forEach { $0.isEnabled = !loading }
        [emailTextField, usernameTextField, passwordTextField, confirmPasswordTextField].forEach {
            $0.isEnabled = !loading
        }

        if loading {
            registerButton.setTitle("", for: .normal)
            loadingIndicator.startAnimating()
        } else {
            registerButton.setTitle("Create Account", for: .normal)
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
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
            usernameTextField.becomeFirstResponder()
        case usernameTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        case confirmPasswordTextField:
            textField.resignFirstResponder()
            registerTapped()
        default:
            break
        }
        return true
    }
}