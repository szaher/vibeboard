# CI/CD Pipeline Documentation

This document describes the comprehensive CI/CD pipeline setup for the Vibe Arcade gaming platform.

## 🚀 Overview

The CI/CD pipeline automatically builds, tests, and deploys the backend API and mobile applications using GitHub Actions. It includes multiple workflows for different components:

- **Backend CI/CD**: Go backend testing, building, and container creation
- **iOS CI**: iOS app building and testing on macOS runners
- **Android CI**: Android app building and testing with emulator support
- **Docker Build**: Container image building and security scanning
- **Deployment**: Kubernetes deployment to staging and production environments

## 📋 Workflow Structure

### Backend CI/CD (`backend-ci.yml`)

**Triggers:**
- Push to `main`, `master`, `develop` branches
- Pull requests to `main`, `master`, `develop` branches
- Changes to `backend/**` files

**Jobs:**
1. **Test** - Unit tests with PostgreSQL and Redis services
2. **Security** - Security scanning with Gosec and Nancy
3. **Build Image** - Docker image building and pushing to GHCR
4. **Integration Test** - End-to-end API testing with containerized backend

**Features:**
- Go 1.21+ support
- Database integration testing
- Code coverage reporting
- Security vulnerability scanning
- Multi-architecture Docker builds (AMD64/ARM64)
- Container vulnerability scanning with Trivy

### iOS CI (`ios-ci.yml`)

**Triggers:**
- Push/PR to main branches
- Changes to `ios/**` files

**Jobs:**
1. **Build and Test** - iOS app building and unit testing
2. **Analyze** - Static code analysis
3. **UI Tests** - Automated UI testing on iOS Simulator
4. **Compatibility Test** - Testing across multiple iOS versions and devices

**Features:**
- Xcode 15.0+ support
- iOS Simulator testing
- SwiftLint code style checking
- Multi-device compatibility testing
- Build artifact preservation

### Android CI (`android-ci.yml`)

**Triggers:**
- Push/PR to main branches
- Changes to `android/**` files

**Jobs:**
1. **Test** - Unit tests, lint checks, code coverage
2. **Build** - Debug and release APK building
3. **Security Scan** - Security analysis with SpotBugs
4. **UI Tests** - Instrumented tests on Android emulators
5. **Performance Test** - Benchmark testing
6. **APK Analysis** - APK size and security analysis

**Features:**
- Java 17 and Android SDK 34 support
- Jetpack Compose testing
- Multi-API level testing (28, 30, 33)
- Kotlin code style checking
- APK security analysis

### Docker Build (`docker-build.yml`)

**Triggers:**
- Push to main branches and tags
- Pull requests

**Jobs:**
1. **Build Backend** - Multi-arch container building
2. **Test Container** - Container functionality testing
3. **Security Scan** - Trivy and Snyk vulnerability scanning
4. **Performance Test** - Load testing with wrk
5. **Cleanup** - Old image cleanup

**Features:**
- Multi-architecture builds (AMD64/ARM64)
- Container security scanning
- Performance load testing
- Automated image cleanup
- GHCR integration

### Deployment (`deploy.yml`)

**Triggers:**
- Git tags (v*)
- Manual workflow dispatch

**Jobs:**
1. **Deploy Staging** - Automatic staging deployment
2. **Deploy Production** - Production deployment with approvals
3. **Rollback** - Automatic rollback on failure
4. **Notify** - Deployment status notifications

**Features:**
- Kubernetes deployment with Helm
- Environment-specific configurations
- Automatic rollback capabilities
- Deployment verification
- Smoke testing

## 🛠 Setup Requirements

### Repository Secrets

Add these secrets to your GitHub repository:

```bash
# Container Registry
GITHUB_TOKEN                 # Automatically provided

# Kubernetes Clusters
STAGING_KUBECONFIG          # Staging cluster kubeconfig
PRODUCTION_KUBECONFIG       # Production cluster kubeconfig

# Optional Security Scanning
SNYK_TOKEN                  # Snyk vulnerability scanning
```

### Repository Settings

1. **Enable GitHub Packages** for container registry
2. **Configure branch protection** for main/master branches
3. **Set up environments** for staging and production with appropriate reviewers
4. **Enable vulnerability alerts** for dependency scanning

## 🔧 Configuration

### Environment Variables

Key environment variables used across workflows:

```yaml
# Backend
GO_VERSION: '1.21'
REGISTRY: ghcr.io
IMAGE_NAME: ${{ github.repository }}/backend

# iOS
XCODE_VERSION: '15.0'
IOS_DESTINATION: 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# Android
JAVA_VERSION: '17'
ANDROID_API_LEVEL: '34'
ANDROID_BUILD_TOOLS_VERSION: '34.0.0'
```

### Service Dependencies

The CI pipeline automatically provisions these services:

- **PostgreSQL 15** - Database for integration testing
- **Redis 7** - Caching and session storage
- **Android Emulators** - For instrumented testing
- **iOS Simulators** - For iOS app testing

## 📊 Quality Gates

### Backend Quality Gates

- ✅ All unit tests must pass
- ✅ Code coverage reporting
- ✅ Go linting with golangci-lint
- ✅ Security scanning with Gosec
- ✅ Dependency vulnerability scanning
- ✅ Container security scanning
- ✅ Integration tests must pass

### Mobile App Quality Gates

- ✅ App must build successfully
- ✅ Unit tests must pass
- ✅ UI tests must pass (when available)
- ✅ Code style checks must pass
- ✅ Security analysis
- ✅ Multi-device/version compatibility

### Container Quality Gates

- ✅ Multi-architecture builds
- ✅ Container functionality tests
- ✅ Security vulnerability scans
- ✅ Performance benchmarks
- ✅ Image size optimization

## 🚀 Deployment Strategy

### Staging Environment

- **Trigger**: Automatic on develop branch pushes
- **Target**: `staging-api.vibearcade.com`
- **Resources**: Limited (1-3 replicas)
- **Database**: Staging PostgreSQL instance
- **Purpose**: Integration testing and QA

### Production Environment

- **Trigger**: Git tags (v1.0.0, v1.1.0, etc.)
- **Target**: `api.vibearcade.com`
- **Resources**: Auto-scaling (3-20 replicas)
- **Database**: External managed database
- **Purpose**: Live production environment

### Rollback Strategy

- **Automatic**: Triggered on deployment failure
- **Manual**: Available through GitHub Actions UI
- **Verification**: Health checks and smoke tests
- **Recovery**: Helm rollback to previous stable version

## 📈 Monitoring and Observability

### Build Monitoring

- **Status Badges**: Real-time build status in README
- **Notifications**: Configurable failure notifications
- **Artifacts**: Build artifacts preserved for investigation
- **Logs**: Detailed logging for all CI/CD stages

### Deployment Monitoring

- **Health Checks**: Automated endpoint verification
- **Smoke Tests**: Basic functionality validation
- **Resource Monitoring**: CPU/memory usage tracking
- **Performance Tests**: Load testing on production deployments

## 🔍 Troubleshooting

### Common Issues

1. **Backend Tests Failing**
   ```bash
   # Check database connectivity
   kubectl logs <postgres-pod> -n test-namespace

   # Verify environment variables
   env | grep DB_
   ```

2. **iOS Build Failures**
   ```bash
   # Check Xcode version compatibility
   xcodebuild -version

   # Clean derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. **Android Build Issues**
   ```bash
   # Check Java version
   java -version

   # Clean Gradle cache
   ./gradlew clean
   ```

4. **Container Build Problems**
   ```bash
   # Test local Docker build
   docker build -t test ./backend

   # Check multi-arch support
   docker buildx inspect
   ```

### Debug Workflows

Enable debug logging by setting repository secret:
```
ACTIONS_STEP_DEBUG = true
ACTIONS_RUNNER_DEBUG = true
```

### Performance Optimization

- **Cache Usage**: Gradle, Go modules, and Docker layer caching
- **Parallel Jobs**: Multiple jobs run concurrently when possible
- **Resource Limits**: Appropriate resource allocation for each job
- **Artifact Management**: Automatic cleanup of old artifacts

## 📚 Best Practices

### Code Quality

1. **Write comprehensive tests** before pushing
2. **Follow code style guidelines** enforced by linters
3. **Keep dependencies updated** and scan for vulnerabilities
4. **Use semantic versioning** for releases

### Security

1. **Never commit secrets** to the repository
2. **Use environment-specific configurations**
3. **Regularly update dependencies** and base images
4. **Monitor security scanning reports**

### Performance

1. **Optimize Docker images** for size and security
2. **Use caching effectively** in CI/CD workflows
3. **Monitor resource usage** and adjust as needed
4. **Profile application performance** regularly

## 🔗 Related Documentation

- [Development Setup Guide](./DEVELOPMENT.md)
- [Deployment Configuration](./deployment/README.md)
- [API Documentation](./backend/README.md)
- [Mobile App Guides](./ios/README.md) | [Android](./android/README.md)

---

For questions or issues with the CI/CD pipeline, please create an issue in the repository or contact the development team.