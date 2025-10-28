# Contributing to File Transfer Over Image

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## 🤝 Code of Conduct

### Our Pledge
We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in your interactions.

### Our Standards
- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites
Before contributing, ensure you have:
- Qt 6.0+ installed
- OpenCV 4.0+ installed
- CMake 3.16+
- C++17 compatible compiler
- Git for version control

### Setting Up Development Environment

1. **Fork the repository**
```bash
git clone https://github.com/YOUR_USERNAME/file_transfer_ovimage.git
cd file_transfer_ovimage
```

2. **Add upstream remote**
```bash
git remote add upstream https://github.com/kimvnhung/file_transfer_ovimage.git
```

3. **Create a development branch**
```bash
git checkout -b feature/your-feature-name
```

4. **Build the project**
```bash
mkdir build && cd build
cmake ..
cmake --build .
```

## 📋 How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**Good bug reports include:**
- Clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Screenshots (if applicable)
- Environment details (OS, Qt version, OpenCV version)
- Error messages or logs

**Bug Report Template:**
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - OS: [e.g., Ubuntu 22.04]
 - Qt Version: [e.g., 6.5.0]
 - OpenCV Version: [e.g., 4.8.0]
 - Compiler: [e.g., GCC 11.3]

**Additional context**
Any other relevant information.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues.

**Good enhancement suggestions include:**
- Clear, descriptive title
- Detailed description of the proposed functionality
- Why this enhancement would be useful
- Possible implementation approach (if you have ideas)

### Pull Requests

1. **Follow the coding style** (see below)
2. **Update documentation** for new features
3. **Write clear commit messages**
4. **Test your changes** thoroughly
5. **Update CHANGELOG.md** if applicable

**PR Process:**

1. Ensure your code builds without warnings
2. Update documentation as needed
3. Add or update tests if applicable
4. Ensure all tests pass
5. Update README.md if needed
6. Create a pull request with a clear description

**PR Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Testing
Describe the tests you ran and how to reproduce them.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have updated the documentation accordingly
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
```

## 💻 Coding Style

### C++ Guidelines

**General Principles:**
- Follow Qt coding conventions
- Use C++17 features appropriately
- Prefer `nullptr` over `NULL`
- Use `auto` when type is obvious
- Use smart pointers when appropriate

**Naming Conventions:**
```cpp
// Classes: PascalCase
class OpenCV_VideoPlayer { };

// Functions/Methods: camelCase
void setVideoUrl(const QUrl &url);

// Private members: prefix with m_
QString m_videoUrl;

// Constants: UPPER_SNAKE_CASE
const int MAX_BUFFER_SIZE = 1024;

// Namespaces: lowercase
namespace fileTransfer { }
```

**Example Code:**
```cpp
// Good
void OpenCV_VideoPlayer::setVideoUrl(const QUrl &newVideoUrl)
{
    if (m_videoUrl == newVideoUrl)
        return;
    
    m_videoUrl = newVideoUrl;
    emit videoUrlChanged(m_videoUrl);
}

// Avoid
void OpenCV_VideoPlayer::setVideoUrl(QUrl newVideoUrl) {
  m_videoUrl = newVideoUrl;
  emit videoUrlChanged(m_videoUrl);
}
```

### QML Guidelines

**General Principles:**
- Follow Qt QML coding conventions
- Keep components focused and reusable
- Use meaningful property names
- Document complex behaviors

**Naming Conventions:**
```qml
// Components: PascalCase
Item {
    id: cameraButton
    
    // Properties: camelCase
    property string buttonText: "Capture"
    property int buttonWidth: 144
    
    // Signal names: camelCase with "on" prefix for handlers
    signal clicked()
    onClicked: { }
}
```

**Example QML:**
```qml
// Good - Clear structure with documentation
import QtQuick
import QtQuick.Controls

/**
 * CameraButton - Reusable button component for camera controls
 * 
 * Usage:
 *   CameraButton {
 *       text: "Capture"
 *       onClicked: capturePhoto()
 *   }
 */
Item {
    id: root
    
    property string text: ""
    signal clicked()
    
    width: 144
    height: 70
    
    Rectangle {
        anchors.fill: parent
        color: mouseArea.pressed ? "#cccccc" : "#ffffff"
        
        Text {
            anchors.centerIn: parent
            text: root.text
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: root.clicked()
        }
    }
}
```

### CMake Guidelines

- Keep CMakeLists.txt organized with clear sections
- Comment complex build logic
- Use modern CMake practices (targets, not variables)
- Organize file lists logically

```cmake
# Good - Clear organization
set(APP_SOURCES
    src/app/main.cpp
    src/app/application.cpp
)

target_sources(app PRIVATE ${APP_SOURCES})
target_include_directories(app PRIVATE include/)
```

## 📝 Commit Messages

Follow conventional commit format:

```
type(scope): subject

body (optional)

footer (optional)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(camera): add burst mode capture

Implement continuous capture mode allowing users to take
multiple photos in rapid succession.

Closes #123

---

fix(video): resolve memory leak in frame processing

The frame buffer wasn't being released properly after
processing completed.

---

docs(readme): update build instructions for Windows
```

## 🧪 Testing

### Running Tests
```bash
cd build
ctest
```

### Writing Tests
- Add tests for new features
- Ensure existing tests pass
- Test edge cases
- Test error handling

## 📚 Documentation

### Code Documentation
- Use Doxygen-style comments for C++ code
- Document all public APIs
- Explain complex algorithms
- Add usage examples

**Example:**
```cpp
/**
 * @brief Sets the video URL for playback
 * 
 * Opens the video file at the specified URL and prepares it for playback.
 * The video properties (frame count, resolution, FPS) are automatically
 * detected and exposed through properties.
 * 
 * @param newVideoUrl The URL of the video file to open
 * 
 * @note Supported formats: MP4, AVI, MOV
 * @see videoUrl(), videoFrameCount(), inputResolution()
 * 
 * Example usage:
 * @code
 * player->setVideoUrl(QUrl::fromLocalFile("/path/to/video.mp4"));
 * @endcode
 */
void setVideoUrl(const QUrl &newVideoUrl);
```

### README Updates
- Update README.md for new features
- Keep build instructions current
- Add usage examples
- Update screenshots if UI changes

## 🏷️ Versioning

We use [Semantic Versioning](https://semver.org/):
- MAJOR: Incompatible API changes
- MINOR: New functionality (backwards-compatible)
- PATCH: Bug fixes (backwards-compatible)

## 📜 License

By contributing, you agree that your contributions will be licensed under the BSD-3-Clause License.

## ❓ Questions?

Feel free to:
- Open an issue for discussion
- Ask questions in pull request comments
- Contact the maintainers directly

## 🙏 Thank You!

Your contributions help make this project better for everyone. We appreciate your time and effort!
