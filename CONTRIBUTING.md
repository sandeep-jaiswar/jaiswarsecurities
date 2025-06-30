# Contributing to Bloomberg-Style Stock Terminal

Thank you for your interest in contributing to our Bloomberg-style Stock Terminal! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ and npm 9+
- Docker and Docker Compose
- Git

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/bloomberg-stock-terminal.git
   cd bloomberg-stock-terminal
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up pre-commit hooks**
   ```bash
   npm run prepare
   ```

4. **Start the development environment**
   ```bash
   npm run setup
   ```

## 📋 Development Workflow

### Code Quality Standards

We maintain high code quality standards through automated tooling:

- **ESLint**: Enforces coding standards and catches potential issues
- **Prettier**: Ensures consistent code formatting
- **TypeScript**: Provides type safety and better developer experience
- **Husky**: Runs pre-commit and pre-push hooks

### Before You Start

1. **Check existing issues** to see if your feature/bug is already being worked on
2. **Create an issue** for new features or bugs if one doesn't exist
3. **Fork the repository** and create a feature branch from `develop`

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our coding standards:
   - Write clean, readable code
   - Add appropriate comments for complex logic
   - Follow the existing code style
   - Write tests for new functionality

3. **Run quality checks**
   ```bash
   npm run lint          # Check for linting errors
   npm run format:check  # Check formatting
   npm run test          # Run all tests
   npm run type-check    # TypeScript type checking
   ```

4. **Fix any issues**
   ```bash
   npm run lint:fix      # Auto-fix linting issues
   npm run format        # Auto-format code
   ```

### Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
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
```bash
git commit -m "feat(api): add market sentiment analysis endpoint"
git commit -m "fix(client): resolve chart rendering issue on mobile"
git commit -m "docs: update API documentation for screening endpoints"
```

### Pull Request Process

1. **Ensure your branch is up to date**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout your-feature-branch
   git rebase develop
   ```

2. **Push your changes**
   ```bash
   git push origin your-feature-branch
   ```

3. **Create a Pull Request**
   - Use a clear, descriptive title
   - Fill out the PR template completely
   - Link related issues
   - Add screenshots for UI changes
   - Request review from appropriate team members

4. **Address review feedback**
   - Make requested changes
   - Push updates to the same branch
   - Respond to comments

## 🧪 Testing

### Running Tests

```bash
# Run all tests
npm run test

# Run tests for specific service
npm run test:client
npm run test:api-gateway
npm run test:data-ingestion
npm run test:backtesting

# Run tests with coverage
npm run test -- --coverage
```

### Writing Tests

- **Unit tests**: Test individual functions and components
- **Integration tests**: Test API endpoints and service interactions
- **E2E tests**: Test complete user workflows

### Test Structure

```javascript
describe('Feature Name', () => {
  beforeEach(() => {
    // Setup
  });

  afterEach(() => {
    // Cleanup
  });

  it('should do something specific', () => {
    // Arrange
    // Act
    // Assert
  });
});
```

## 🏗️ Architecture Guidelines

### Project Structure

```
├── client/                 # Next.js frontend
├── services/
│   ├── api-gateway/       # Main API service
│   ├── data-ingestion/    # Data ingestion service
│   └── backtesting/       # Backtesting service
├── database/              # Database schemas and migrations
├── .github/               # GitHub workflows and templates
└── scripts/               # Utility scripts
```

### Coding Standards

#### TypeScript/JavaScript

- Use TypeScript for all new code
- Prefer functional programming patterns
- Use async/await over Promises
- Handle errors appropriately
- Use meaningful variable and function names

#### React/Next.js

- Use functional components with hooks
- Implement proper error boundaries
- Optimize for performance (useMemo, useCallback)
- Follow accessibility guidelines
- Use TypeScript for props and state

#### API Development

- Follow RESTful conventions
- Use proper HTTP status codes
- Implement comprehensive error handling
- Add input validation
- Document endpoints with Swagger/OpenAPI

#### Database

- Use migrations for schema changes
- Follow naming conventions
- Add appropriate indexes
- Implement proper constraints
- Use transactions for data integrity

## 🔒 Security Guidelines

- Never commit secrets or API keys
- Use environment variables for configuration
- Implement proper authentication and authorization
- Validate all user inputs
- Follow OWASP security guidelines
- Use HTTPS in production

## 📚 Documentation

- Update README.md for significant changes
- Document new API endpoints
- Add inline comments for complex logic
- Update type definitions
- Include examples in documentation

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment details** (OS, Node.js version, browser)
2. **Steps to reproduce** the issue
3. **Expected behavior**
4. **Actual behavior**
5. **Screenshots** (if applicable)
6. **Error messages** or logs

## 💡 Feature Requests

For feature requests, please provide:

1. **Clear description** of the feature
2. **Use case** and business value
3. **Proposed implementation** (if you have ideas)
4. **Mockups or wireframes** (if applicable)

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check the README and inline documentation
- **Code Review**: Ask for help in pull request comments

## 🎯 Performance Guidelines

- Optimize database queries
- Implement proper caching strategies
- Use lazy loading for large datasets
- Minimize bundle sizes
- Optimize images and assets
- Monitor performance metrics

## 🚀 Deployment

- All deployments go through CI/CD pipeline
- Staging environment mirrors production
- Database migrations run automatically
- Feature flags for gradual rollouts
- Monitoring and alerting in place

## 📊 Monitoring and Observability

- Log important events and errors
- Use structured logging
- Implement health checks
- Monitor key metrics
- Set up alerts for critical issues

Thank you for contributing to our Bloomberg-style Stock Terminal! Your contributions help make this project better for everyone.