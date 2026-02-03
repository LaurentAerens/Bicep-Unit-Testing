# CI/CD Integration

Guide for integrating Bicep unit tests into your CI/CD pipelines.

## GitHub Actions

### Basic Workflow

Create `.github/workflows/bicep-tests.yml`:

```yaml
name: Bicep Unit Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install Bicep CLI
        run: |
          curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
          chmod +x bicep
          sudo mv bicep /usr/local/bin/bicep
      
      - name: Run tests
        run: ./run-tests.sh -v
```

### Windows Runner

For Windows-specific tests:

```yaml
name: Bicep Tests (Windows)

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install Bicep CLI
        shell: powershell
        run: |
          $InstallPath = "C:\bicep"
          New-Item -ItemType Directory -Force -Path $InstallPath
          Invoke-WebRequest -Uri "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe" -OutFile "$InstallPath\bicep.exe"
          Add-Content -Path $env:GITHUB_PATH -Value $InstallPath
      
      - name: Run tests
        shell: powershell
        run: .\run-tests.ps1 -Parallel -Quiet
```

### Parallel Execution

Run tests in parallel for faster CI/CD:

```yaml
name: Fast Bicep Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Bicep
        run: |
          curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
          chmod +x bicep
          sudo mv bicep /usr/local/bin/bicep
      
      - name: Run tests in parallel
        run: ./run-tests.sh -p  # Parallel flag
```

### Save Test Results

Archive test output for debugging:

```yaml
name: Bicep Tests with Artifacts

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Bicep
        run: |
          curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
          chmod +x bicep
          sudo mv bicep /usr/local/bin/bicep
      
      - name: Run tests
        run: ./run-tests.sh -v > test-results.txt 2>&1 || true
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results.txt
```

### Matrix Testing

Test against multiple Bicep versions:

```yaml
name: Test Multiple Bicep Versions

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        bicep-version: ['0.20.0', '0.25.0', 'latest']
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Bicep ${{ matrix.bicep-version }}
        run: |
          # Install specific version
          VERSION=${{ matrix.bicep-version }}
          curl -Lo bicep https://github.com/Azure/bicep/releases/download/v${VERSION}/bicep-linux-x64
          chmod +x bicep
          sudo mv bicep /usr/local/bin/bicep
      
      - name: Run tests
        run: ./run-tests.sh -v
```

## Azure DevOps Pipelines

### Basic YAML Pipeline

Create `azure-pipelines.yml`:

```yaml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.x'

  - script: |
      curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
      chmod +x bicep
      sudo mv bicep /usr/local/bin/bicep
    displayName: 'Install Bicep CLI'

  - script: ./run-tests.sh -v
    displayName: 'Run Bicep Tests'
```

### Windows Agent

For Windows-based testing:

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
  - task: PowerShell@2
    inputs:
      targetType: 'inline'
      script: |
        $InstallPath = "C:\bicep"
        New-Item -ItemType Directory -Force -Path $InstallPath
        Invoke-WebRequest -Uri "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe" -OutFile "$InstallPath\bicep.exe"
        Add-Content -Path $env:PATH -Value $InstallPath
    displayName: 'Install Bicep CLI'

  - task: PowerShell@2
    inputs:
      targetType: 'filePath'
      filePath: './run-tests.ps1'
      arguments: '-Parallel -Quiet'
      pwsh: true
    displayName: 'Run Bicep Tests'
```

### Publish Test Results

Publish results for Azure DevOps dashboard:

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - script: |
      curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
      chmod +x bicep
      sudo mv bicep /usr/local/bin/bicep
    displayName: 'Install Bicep'

  - script: ./run-tests.sh -v > test-results.txt 2>&1 || true
    displayName: 'Run Tests'

  - task: PublishBuildArtifacts@1
    condition: always()
    inputs:
      PathtoPublish: 'test-results.txt'
      ArtifactName: 'test-results'
```

### Multi-Stage Pipeline

Complex pipeline with multiple stages:

```yaml
trigger:
  - main

stages:
  - stage: Test
    displayName: 'Run Tests'
    jobs:
      - job: BicepTests
        pool:
          vmImage: 'ubuntu-latest'
        
        steps:
          - checkout: self
          
          - script: |
              curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
              chmod +x bicep
              sudo mv bicep /usr/local/bin/bicep
            displayName: 'Install Dependencies'
          
          - script: ./run-tests.sh -v
            displayName: 'Run Unit Tests'

  - stage: Deploy
    displayName: 'Deploy'
    dependsOn: Test
    condition: succeeded()
    jobs:
      - job: DeployBicep
        pool:
          vmImage: 'ubuntu-latest'
        
        steps:
          - script: echo "Deploying Bicep templates..."
            displayName: 'Deploy Bicep'
```

## GitLab CI/CD

### Basic Pipeline

Create `.gitlab-ci.yml`:

```yaml
stages:
  - test

bicep_tests:
  stage: test
  image: ubuntu:latest
  
  before_script:
    - apt-get update
    - curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
    - chmod +x bicep
    - mv bicep /usr/local/bin/bicep
  
  script:
    - ./run-tests.sh -v
  
  artifacts:
    paths:
      # Update this path if you store test results elsewhere
      - test-results.txt
    when: always
```

## Best Practices

### 1. Fail on Test Failure

Ensure the pipeline fails if tests don't pass:

```yaml
# GitHub Actions
- name: Run tests
  run: ./run-tests.sh -v
  # Automatically fails if exit code != 0
```

```yaml
# Azure DevOps
- script: ./run-tests.sh -v
  displayName: 'Run Tests'
  # Fails pipeline if script returns non-zero
```

### 2. Use Quiet Mode for CI/CD

Reduce output verbosity in CI/CD:

```powershell
# Windows - quiet mode
.\run-tests.ps1 -Quiet -Parallel
```

```bash
# Linux - quiet mode
./run-tests.sh -q
```

### 3. Enable Parallel Execution

Speed up test execution:

```powershell
# All tests in parallel
.\run-tests.ps1 -Parallel

# Limited parallelism
.\run-tests.ps1 -Parallel -MaxParallelJobs 4
```

### 4. Separate Test and Lint Stages

Keep tests separate from linting:

```yaml
stages:
  - lint
  - test
  - deploy

lint:
  stage: lint
  script: # Linting commands

test:
  stage: test
  script: # Test commands
  
deploy:
  stage: deploy
  script: # Deployment commands
```

### 5. Cache Dependencies

Cache Bicep installation:

```yaml
# GitHub Actions
- uses: actions/cache@v3
  with:
    path: ~/.cache/bicep
    key: bicep-${{ runner.os }}
```

### 6. Scheduled Tests

Run tests on schedule:

```yaml
# GitHub Actions - nightly tests
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
```

```yaml
# Azure DevOps - scheduled run
schedules:
- cron: "0 2 * * *"
  displayName: Nightly test run
  branches:
    include:
    - main
```

### 7. Conditional Test Execution

Only run tests when relevant files change. Adjust paths to match your project structure:

Include paths to:
- Your Bicep function files (wherever you store them)
- Your test files
- Your test runner scripts

Example: If your project uses `src/modules/` for functions and `tests/` for tests, configure your CI/CD to only run when those directories change.

## Troubleshooting CI/CD

### Bicep CLI Not Found

**Problem**: "bicep: command not found" error

**Solution**: Verify installation step runs before tests

```yaml
# Make sure Bicep is installed first
- name: Install Bicep
  run: |
    curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
    chmod +x bicep
    sudo mv bicep /usr/local/bin/bicep
    which bicep  # Verify installation

- name: Run Tests
  run: ./run-tests.sh -v
```

### Tests Timeout

**Problem**: Tests take too long to complete

**Solution**: 
1. Enable parallel execution
2. Increase timeout
3. Test in isolation

```yaml
# GitHub Actions - increase timeout
- name: Run Tests
  timeout-minutes: 30
  run: ./run-tests.ps1 -Parallel
```

### Flaky Tests

**Problem**: Tests pass/fail inconsistently

**Solution**:
1. Check for timing-dependent tests
2. Isolate dependencies
3. Run tests multiple times

```yaml
# Retry failed tests
- name: Run Tests
  run: |
    for i in {1..3}; do
      ./run-tests.sh -v && break  # Adjust path if in different location
      sleep 10
    done
```

## Example Complete Workflows

### Complete GitHub Actions Workflow

```yaml
name: Bicep Unit Tests

on:
  push:
    branches: [main, develop]
    paths:
      # Update these paths to match where YOUR bicep and test files are located
      - 'src/**'
      - 'tests/**'
  pull_request:
    branches: [main, develop]

jobs:
  test:
    name: Run Tests
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install Bicep (Linux)
        if: runner.os == 'Linux'
        run: |
          curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
          chmod +x bicep
          sudo mv bicep /usr/local/bin/bicep
          which bicep
      
      - name: Install Bicep (Windows)
        if: runner.os == 'Windows'
        shell: powershell
        run: |
          $InstallPath = "C:\bicep"
          New-Item -ItemType Directory -Force -Path $InstallPath
          Invoke-WebRequest -Uri "https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe" -OutFile "$InstallPath\bicep.exe"
          Add-Content -Path $env:GITHUB_PATH -Value $InstallPath
      
      - name: Run tests (Linux)
        if: runner.os == 'Linux'
        run: ./run-tests.sh -v
      
      - name: Run tests (Windows)
        if: runner.os == 'Windows'
        shell: powershell
        run: .\run-tests.ps1 -Parallel  # Adjust path if in different location
      
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.os }}
          path: test-results.txt
```

## See Also

- [Script Parameters](./script-parameters.md) - Test runner options
- [Test Files Overview](./test-files.md) - Test format reference
- [Best Practices](./best-practices.md) - Testing guidelines
