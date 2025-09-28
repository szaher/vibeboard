# Vibe Arcade Development Guide

This guide covers local development setup, testing, and deployment for the Vibe Arcade gaming platform.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Backend Development](#backend-development)
- [iOS Development](#ios-development)
- [Android Development](#android-development)
- [Local Testing](#local-testing)
- [Environment Configuration](#environment-configuration)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

## 🛠 Prerequisites

### Required Software

- **Go 1.21+** - Backend development
- **Node.js 18+** & **npm** - Development tools
- **Docker & Docker Compose** - Local services
- **Git** - Version control

### For iOS Development
- **Xcode 15+** - iOS development
- **iOS Simulator** - Testing
- **macOS** - Required for iOS development

### For Android Development
- **Android Studio** - Android development
- **Android SDK** - API level 24+ (Android 7.0+)
- **Java 17+** - Required for Android builds

### For Deployment
- **kubectl** - Kubernetes CLI
- **Helm 3+** - Kubernetes package manager
- **Docker** - Container builds

## 🌍 Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/szaher/mobile-game.git
cd mobile-game
```

### 2. Start Local Services

```bash
# Start PostgreSQL and Redis
cd backend
make docker-up

# Wait for services to be ready
sleep 10

# Run database migrations
make migrate-up
```

### 3. Environment Variables

Copy and configure environment files:

```bash
# Backend
cp backend/.env.example backend/.env
# Edit backend/.env with your local settings

# The default configuration should work for local development
```

## 🔧 Backend Development

### Quick Start

```bash
cd backend

# Install dependencies
go mod download

# Start development server
make dev

# Alternative: run with hot reload
make run
```

### Available Commands

```bash
# Development
make run              # Run server locally
make build            # Build binary
make test             # Run tests
make test-coverage    # Run tests with coverage

# Docker
make docker-up        # Start services (PostgreSQL, Redis)
make docker-down      # Stop services
make docker-logs      # View service logs

# Database
make migrate-up       # Run migrations
make migrate-down     # Rollback migrations

# Code Quality
make fmt              # Format code
make lint             # Lint code (requires golangci-lint)
```

### Backend Configuration

The backend automatically loads configuration from:
1. Environment variables
2. `.env` file
3. Default values

Key configuration:
- **Server**: `localhost:8181`
- **Database**: `localhost:5432`
- **Redis**: `localhost:6379`
- **WebSocket**: `ws://localhost:8181/api/v1/ws`

### API Endpoints

```
# Authentication
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh

# Games
GET    /api/v1/games
POST   /api/v1/games
GET    /api/v1/games/:id
POST   /api/v1/games/:id/join
POST   /api/v1/games/:id/move

# User
GET    /api/v1/user/profile

# WebSocket
GET    /api/v1/ws
```

## 📱 iOS Development

### Setup

1. **Open Xcode Project**:
   ```bash
   cd ios
   open VibeArcade.xcodeproj
   ```

2. **Install Dependencies** (if using CocoaPods):
   ```bash
   cd ios
   pod install
   ```

3. **Configure Environment**:
   - For **Debug**: Uses `Config-Debug.plist` (localhost)
   - For **Release**: Uses `Config-Release.plist` (production)

### Environment Configuration

Edit configuration files:

**Debug Configuration** (`ios/VibeArcade/Resources/Config-Debug.plist`):
```xml
<key>BASE_URL</key>
<string>http://localhost:8181/api/v1</string>
<key>WEBSOCKET_URL</key>
<string>ws://localhost:8181/api/v1/ws</string>
```

**Production Configuration** (`ios/VibeArcade/Resources/Config-Release.plist`):
```xml
<key>BASE_URL</key>
<string>https://api.vibearcade.com/api/v1</string>
<key>WEBSOCKET_URL</key>
<string>wss://api.vibearcade.com/api/v1/ws</string>
```

### Building and Running

1. **Select Target**: Choose iOS device or simulator
2. **Build Scheme**:
   - `Debug` for development
   - `Release` for production builds
3. **Run**: ⌘+R to build and run

### Testing on Device

For physical device testing:
1. **Change localhost URLs** to your computer's IP address
2. **Example**: Replace `localhost` with `192.168.1.100`
3. **Ensure firewall** allows connections on port 8181

## 🤖 Android Development

### Setup

1. **Open Android Studio**:
   ```bash
   cd android
   # Open android folder in Android Studio
   ```

2. **Sync Project**: Let Android Studio sync dependencies

3. **Configure Environment**:
   - **Debug**: Uses `Environment.isDebug = true` (emulator)
   - **Release**: Uses production URLs

### Environment Configuration

The Android app automatically configures URLs based on build type:

**Debug/Development**:
- Base URL: `http://10.0.2.2:8181/api/v1/` (Android emulator localhost)
- WebSocket: `ws://10.0.2.2:8181/api/v1/ws`

**Release/Production**:
- Base URL: `https://api.vibearcade.com/api/v1/`
- WebSocket: `wss://api.vibearcade.com/api/v1/ws`

### Custom URL Configuration

To override URLs for testing:

1. **Modify** `android/app/src/main/java/com/acmegames/vibearcade/core/networking/Environment.kt`
2. **Update** `getCustomBaseUrl()` method:
   ```kotlin
   fun getCustomBaseUrl(): String? {
       // For testing with physical device
       return "http://192.168.1.100:8181/api/v1/"
   }
   ```

### Building and Running

1. **Debug Build**:
   ```bash
   ./gradlew assembleDebug
   ```

2. **Release Build**:
   ```bash
   ./gradlew assembleRelease
   ```

3. **Install on Device**:
   ```bash
   ./gradlew installDebug
   ```

### Testing on Physical Device

For physical Android device testing:
1. **Enable Developer Options** and **USB Debugging**
2. **Connect device** via USB
3. **Update URLs** in `Environment.kt` to use your computer's IP
4. **Ensure firewall** allows connections on port 8181

## 🧪 Local Testing

### Full Stack Testing

1. **Start Backend**:
   ```bash
   cd backend
   make docker-up
   make run
   ```

2. **Test iOS**:
   - Open Xcode project
   - Select iOS Simulator
   - Build and run (⌘+R)

3. **Test Android**:
   - Open Android Studio
   - Select Android Emulator
   - Run app

### API Testing

```bash
# Test health endpoint
curl http://localhost:8181/health

# Test registration
curl -X POST http://localhost:8181/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","username":"testuser","password":"password123"}'

# Test login
curl -X POST http://localhost:8181/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### WebSocket Testing

Use a WebSocket client tool or browser console:

```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:8181/api/v1/ws');

// Send authentication message
ws.onopen = function() {
    ws.send(JSON.stringify({
        type: 'heartbeat',
        player_id: 'test-user-id',
        timestamp: Date.now()
    }));
};

// Listen for messages
ws.onmessage = function(event) {
    console.log('Received:', JSON.parse(event.data));
};
```

## ⚙️ Environment Configuration

### Backend URLs Configuration

| Environment | Backend URL | WebSocket URL |
|-------------|-------------|---------------|
| Local Development | `http://localhost:8181` | `ws://localhost:8181/api/v1/ws` |
| iOS Simulator | `http://localhost:8181` | `ws://localhost:8181/api/v1/ws` |
| Android Emulator | `http://10.0.2.2:8181` | `ws://10.0.2.2:8181/api/v1/ws` |
| Physical Device | `http://YOUR_IP:8181` | `ws://YOUR_IP:8181/api/v1/ws` |
| Production | `https://api.vibearcade.com` | `wss://api.vibearcade.com/api/v1/ws` |

### Finding Your IP Address

**macOS/Linux**:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**Windows**:
```cmd
ipconfig | findstr "IPv4"
```

### Platform-Specific Configuration

#### iOS Configuration Changes
1. **Edit** `ios/VibeArcade/Resources/Config-Debug.plist`
2. **Replace** `localhost` with your IP address
3. **Rebuild** the app

#### Android Configuration Changes
1. **Edit** `android/app/src/main/java/.../Environment.kt`
2. **Update** `getCustomBaseUrl()` method
3. **Rebuild** the app

## 🚀 Deployment

### Production Build

#### Backend
```bash
cd backend
make prod-build
docker build -t vibe-arcade/backend:latest .
```

#### iOS
1. **Archive** in Xcode (Product → Archive)
2. **Upload** to App Store Connect
3. **Configure** production URLs in `Config-Release.plist`

#### Android
```bash
cd android
./gradlew assembleRelease
# Upload APK to Google Play Console
```

### Kubernetes Deployment

```bash
# Install with Helm
cd deployment/helm
helm install vibe-arcade ./vibe-arcade \
  --namespace vibe-arcade \
  --create-namespace \
  --values ./vibe-arcade/values.yaml

# Upgrade deployment
helm upgrade vibe-arcade ./vibe-arcade \
  --namespace vibe-arcade \
  --values ./vibe-arcade/values.yaml
```

### Environment Variables for Production

Set these secrets in your deployment:

```bash
# Required secrets
JWT_SECRET=your-super-secure-jwt-secret
DB_PASSWORD=your-database-password
REDIS_PASSWORD=your-redis-password

# Optional
CORS_ALLOWED_ORIGINS=https://your-app.com,https://api.your-app.com
```

## 🔧 Troubleshooting

### Common Issues

#### "Connection Refused" Error

**iOS/Android → Backend**:
1. ✅ Check backend is running (`curl http://localhost:8181/health`)
2. ✅ Verify IP address in mobile app configuration
3. ✅ Check firewall settings
4. ✅ Ensure ports are not blocked

#### Database Connection Error

```bash
# Check if PostgreSQL is running
make docker-logs

# Restart services
make docker-down
make docker-up

# Check database connection
psql -h localhost -p 5432 -U vibe_arcade -d vibe_arcade
```

#### WebSocket Connection Issues

1. ✅ Check WebSocket URL format (`ws://` not `wss://` for local)
2. ✅ Verify authentication token is included
3. ✅ Check network connectivity
4. ✅ Test with a WebSocket client tool

#### iOS Simulator Issues

1. ✅ Reset simulator (Device → Erase All Content and Settings)
2. ✅ Clean build folder (Product → Clean Build Folder)
3. ✅ Check for localhost vs IP address configuration

#### Android Emulator Issues

1. ✅ Use `10.0.2.2` instead of `localhost`
2. ✅ Check if emulator has internet access
3. ✅ Wipe emulator data if needed
4. ✅ Restart Android Studio and emulator

### Network Configuration

#### For Physical Device Testing

1. **Find your IP address** (see commands above)
2. **Update mobile app configuration**
3. **Ensure both devices on same network**
4. **Check firewall allows port 8181**

#### Firewall Configuration

**macOS**:
```bash
# Allow port 8181
sudo pfctl -d  # Disable firewall temporarily for testing
```

**Windows**:
```cmd
# Add firewall rule for port 8181
netsh advfirewall firewall add rule name="Vibe Arcade" dir=in action=allow protocol=TCP localport=8181
```

### Logs and Debugging

#### Backend Logs
```bash
# Docker services
make docker-logs

# Application logs
tail -f backend/logs/app.log
```

#### Mobile App Logs
- **iOS**: Use Xcode console
- **Android**: Use Android Studio Logcat

### Getting Help

1. **Check logs** first (backend, mobile apps)
2. **Verify configuration** (URLs, environment variables)
3. **Test API endpoints** with curl
4. **Check network connectivity**
5. **Review this guide** for missed steps

---

## 📚 Additional Resources

- [Go Documentation](https://golang.org/doc/)
- [iOS Development Guide](https://developer.apple.com/documentation/)
- [Android Development Guide](https://developer.android.com/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

Happy coding! 🎮