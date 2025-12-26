# Contributing to QEMU Test Lab

Thanks for your interest in contributing! This project aims to provide a simple, scriptable QEMU-based test environment for network security and infrastructure testing.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- Your OS and version
- QEMU version (`qemu-system-x86_64 --version`)
- Steps to reproduce
- Expected vs actual behavior
- Any error messages or logs

### Suggesting Features

Feature requests are welcome! Please open an issue describing:
- The use case or problem you're trying to solve
- Your proposed solution
- Any alternative approaches you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly on your system
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Scripts should be POSIX-compliant where possible
- Use bash for complex scripts
- Include comments for non-obvious operations
- Follow existing formatting style
- Add error handling (`set -e`, check return codes)
- Use colored output for better UX (GREEN for success, RED for errors, YELLOW for warnings)

### Testing

Before submitting a PR, please test:
- Network setup and teardown
- VM creation and cloning
- Snapshot operations
- The main management script
- On a fresh environment if possible

### Documentation

- Update README.md if you add features
- Add comments to scripts
- Include usage examples
- Document any new dependencies

## Areas That Need Help

- Support for additional Linux distributions
- Windows host support (WSL2)
- macOS support improvements
- Additional network topologies (VLANs, multiple bridges)
- Pre-configured VM templates
- Automated testing scripts
- Performance optimization tips
- Additional use case examples

## Questions?

Feel free to open an issue for questions or discussion.

## Code of Conduct

- Be respectful and constructive
- Focus on what's best for the project
- Welcome newcomers and help them learn

Thanks for contributing!