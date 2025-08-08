# Contributing to AWS EC2 QuorumStop

Thank you for your interest in contributing to AWS EC2 QuorumStop! This project welcomes contributions from the community to help improve collaborative infrastructure management.

## 🤝 How to Contribute

### 🐛 Report Bugs

Found a bug? Help us improve by reporting it!

1. **Check existing issues** first: [GitHub Issues](https://github.com/Obad94/aws-ec2-quorumstop/issues)
2. **Create a detailed bug report** using our bug report template
3. **Include all necessary information** to help us reproduce the issue

**Good Bug Report Includes:**
- Clear, descriptive title
- Steps to reproduce the behavior
- Expected vs actual behavior
- System information (Windows version, AWS CLI version)
- Error messages (exact text)
- Configuration details (sanitized)

### ✨ Suggest Features

Have an idea for improvement? We'd love to hear it!

1. **Check [Discussions](https://github.com/Obad94/aws-ec2-quorumstop/discussions)** for similar ideas
2. **Create a feature request** using our feature request template
3. **Explain your use case** and proposed solution
4. **Consider backward compatibility** implications

### 🔧 Submit Code Changes

Ready to contribute code? Follow these steps:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** and test thoroughly
4. **Update documentation** if needed
5. **Submit a pull request** with clear description

## 🏗️ Development Guidelines

### Setting Up Development Environment

```bash
# Clone your fork
git clone https://github.com/<your-username>/aws-ec2-quorumstop.git
cd aws-ec2-quorumstop

# Create feature branch
git checkout -b feature/new-voting-algorithm

# Make changes and test
# ... develop and test your changes ...

# Commit with clear message
git commit -m "feat: add weighted voting algorithm for team leads"

# Push to your fork
git push origin feature/new-voting-algorithm
```

Replace <your-username> in the clone URL with your GitHub username when contributing from a fork.

### Testing Your Changes

**Client-Side Testing (Windows):**
```batch
REM Test all batch scripts
test_aws.bat
view_config.bat
start_server.bat
shutdown_server.bat
```

**Server-Side Testing (Linux):**
```bash
# Test server script functionality
./vote_shutdown.sh debug
./vote_shutdown.sh help
./vote_shutdown.sh status

# Test voting scenarios
./vote_shutdown.sh initiate 203.0.113.10  # Simulate vote
```

**Integration Testing:**
1. Set up test EC2 instance
2. Test full workflow from Windows client to server
3. Test various voting scenarios
4. Verify error handling

### Code Style Guidelines

**Batch Scripts (.bat files):**
```batch
@echo off
REM Use clear, descriptive comments
REM Follow existing patterns for consistency

REM Use meaningful variable names
set MEANINGFUL_NAME=value

REM Handle errors appropriately
if errorlevel 1 (
    echo ERROR: Descriptive error message
    pause
    exit /b 1
)

REM Keep lines under 100 characters when possible
echo This is a reasonably short line that fits well
```

**Bash Scripts (.sh files):**
```bash
#!/bin/bash
# Use clear, descriptive comments
# Follow existing patterns for consistency

# Use meaningful variable names
meaningful_name="value"

# Handle errors appropriately
if ! command_that_might_fail; then
    echo "ERROR: Descriptive error message" >&2
    exit 1
fi

# Use proper quoting
echo "Variables should be quoted: $meaningful_name"
```

**Documentation (.md files):**
- Use clear, concise language
- Follow existing formatting patterns
- Include code examples where helpful
- Add screenshots for complex UI interactions
- Keep lines under 120 characters

### Commit Message Guidelines

Use conventional commit format:

```
type(scope): brief description

Longer description if needed

Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process, dependencies, etc.

**Examples:**
```
feat(voting): add weighted voting for team leads

Allow team leads to have double weight in voting decisions.
This helps prevent situations where junior developers
accidentally shutdown production systems.

Fixes #45

fix(client): handle spaces in SSH key file paths

Windows paths with spaces were causing SSH connection failures.
Now properly quote the key file path in all SSH commands.

Fixes #78

docs(readme): update installation instructions

Add troubleshooting section for common Windows path issues
and improve clarity of AWS CLI setup steps.
```

## 🧪 Testing Guidelines

### Test Categories

**Unit Tests:**
- Individual function testing
- Script parameter validation
- Configuration parsing
- Error handling

**Integration Tests:**
- Full workflow testing
- AWS API integration
- SSH connectivity
- Voting system end-to-end

**User Acceptance Tests:**
- Real-world scenarios
- Different team sizes
- Various network conditions
- Error recovery

### Test Scenarios to Cover

**Happy Path:**
- [ ] Normal server start/stop cycle
- [ ] Successful democratic vote (all agree)
- [ ] Successful democratic vote (majority)
- [ ] Configuration updates work correctly

**Edge Cases:**
- [ ] Network interruptions during voting
- [ ] SSH key permission issues
- [ ] AWS API rate limiting
- [ ] Invalid configuration values
- [ ] Concurrent voting attempts

**Error Conditions:**
- [ ] AWS credentials invalid
- [ ] EC2 instance not found
- [ ] SSH connection failure
- [ ] Vote script not found
- [ ] Disk space full on server

### Manual Testing Checklist

**Before submitting PR:**
- [ ] Test on fresh Windows 10/11 installation
- [ ] Test with different AWS regions
- [ ] Test with various team sizes (2-5 people)
- [ ] Test error scenarios and recovery
- [ ] Verify documentation accuracy
- [ ] Check all links work correctly

## 📖 Documentation Guidelines

### Documentation Requirements

**For New Features:**
- Update relevant documentation files
- Add usage examples
- Include troubleshooting section
- Update configuration guide if needed

**Documentation Style:**
- Write for beginners (assume no prior knowledge)
- Use active voice when possible
- Include concrete examples
- Add screenshots for complex procedures
- Keep explanations concise but complete

### Documentation Structure

```markdown
# Feature Name

Brief description of what the feature does.

## Overview

Longer explanation of the feature and its benefits.

## Usage

### Basic Usage
```batch
REM Simple example
command --option value
```

### Advanced Usage
```batch
REM Complex example with explanation
command --advanced-option value --another-option
```

## Configuration

Required configuration changes:

```batch
set NEW_SETTING=value
```

## Troubleshooting

**Problem:** Common issue description

**Solution:** Step-by-step fix

## Examples

Real-world scenarios and solutions.
```

## 🔍 Code Review Process

### Review Criteria

**Functionality:**
- [ ] Code works as intended
- [ ] Handles edge cases appropriately
- [ ] Error messages are helpful
- [ ] No security vulnerabilities

**Code Quality:**
- [ ] Follows project conventions
- [ ] Well-commented and readable
- [ ] No code duplication
- [ ] Efficient implementation

**Documentation:**
- [ ] All changes documented
- [ ] Examples provided
- [ ] README updated if needed
- [ ] No broken links

**Testing:**
- [ ] Adequate test coverage
- [ ] Tests pass consistently
- [ ] Manual testing completed
- [ ] No regressions introduced

### Review Process

1. **Automated Checks**: GitHub Actions run basic validation
2. **Peer Review**: At least one maintainer reviews the code
3. **Testing**: Manual testing of changes
4. **Documentation Review**: Ensure docs are accurate and complete
5. **Final Approval**: Maintainer approves and merges

## 🚀 Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

**Before Release:**
- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers updated
- [ ] Security review completed

**Release Process:**
1. Create release branch
2. Final testing and validation
3. Create GitHub release with release notes
4. Update documentation links
5. Announce release in discussions

## 🎯 Contribution Ideas

### Good First Issues

Looking for ways to contribute? Try these beginner-friendly tasks:

- **Documentation improvements**: Fix typos, add examples, improve clarity
- **Error message improvements**: Make error messages more helpful
- **Configuration validation**: Add better config file validation
- **Logging enhancements**: Improve debug output and logging
- **Testing**: Add test cases for edge scenarios

### Advanced Contributions

For experienced contributors:

- **PowerShell version**: Create PowerShell equivalent of batch scripts
- **Web interface**: Build web-based voting interface
- **Slack/Teams integration**: Add chat notifications
- **Multi-instance support**: Support voting across multiple instances
- **Advanced scheduling**: Time-based shutdown policies

### Infrastructure Improvements

- **CI/CD enhancements**: Improve GitHub Actions workflows
- **Security auditing**: Enhanced security scanning
- **Performance optimization**: Reduce script execution time
- **Cross-platform support**: Support for macOS/Linux clients

## 🆘 Getting Help

### Community Support

- 💬 **[GitHub Discussions](https://github.com/Obad94/aws-ec2-quorumstop/discussions)**: Ask questions, share ideas
- 📖 **[Wiki](https://github.com/Obad94/aws-ec2-quorumstop/wiki)**: Detailed guides and troubleshooting
- 🐛 **[Issues](https://github.com/Obad94/aws-ec2-quorumstop/issues)**: Report bugs and request features

### Contact Maintainers

- **General questions**: Use GitHub Discussions
- **Security issues**: Email security@[your-domain].com
- **Urgent issues**: Create GitHub issue with "urgent" label

## 📜 Code of Conduct

### Our Commitment

We are committed to providing a welcoming and inclusive experience for everyone, regardless of:
- Experience level
- Gender, gender identity and expression
- Sexual orientation
- Disability
- Personal appearance
- Body size
- Race
- Ethnicity
- Age
- Religion
- Nationality

### Expected Behavior

- **Be respectful** in all interactions
- **Be constructive** in feedback and criticism
- **Be collaborative** in problem-solving
- **Be inclusive** of different perspectives
- **Be patient** with newcomers

### Unacceptable Behavior

- Harassment, discrimination, or exclusionary behavior
- Personal attacks or inflammatory language
- Publishing private information without permission
- Trolling, insulting, or derogatory comments
- Other conduct inappropriate in a professional setting

### Reporting Issues

If you experience or witness unacceptable behavior:
1. **Document** the incident (screenshots, links, etc.)
2. **Report** to maintainers via email or private message
3. **Follow up** if no response within 48 hours

## 🎉 Recognition

### Contributors

All contributors are recognized in:
- GitHub repository contributors list
- CHANGELOG.md for significant contributions
- Special mentions in release notes
- Annual contributor appreciation posts

### Maintainer Benefits

Active contributors may be invited to become maintainers with:
- Commit access to repository
- Participation in roadmap planning
- Priority support for their own contributions
- Recognition as project maintainer

## 📊 Project Statistics

### Current Status

- **Contributors**: [Auto-updated by GitHub]
- **Issues**: [Link to issues]
- **Pull Requests**: [Link to PRs]
- **Discussions**: [Link to discussions]

### Contributing Statistics

We welcome contributions of all sizes! Recent stats:
- Bug fixes: Essential for stability
- Feature additions: Drive innovation
- Documentation: Help new users
- Testing: Ensure reliability

---

**Thank you for contributing to AWS EC2 QuorumStop!** 

Your contributions help teams worldwide manage their infrastructure more collaboratively and cost-effectively.

For questions about contributing, check our [Discussions](https://github.com/Obad94/aws-ec2-quorumstop/discussions) or create an [Issue](https://github.com/Obad94/aws-ec2-quorumstop/issues).

**Happy coding!** 🚀