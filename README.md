# Spring Boot JDK 21 test project 

This is a simple Spring Boot project configured with JDK 21. The project demonstrates:

1. Basic Spring Boot web application setup
2. Using JDK 21 features
3. Dependency management with Maven
4. Dependabot security scanning and automated updates
5. GitHub Actions workflow for automatic branch synchronization

## Project Structure

```
├── src/main/java/
│   └── com/example/demo/
│       ├── DemoApplication.java (Main application class)
│       └── controller/
│           └── HelloController.java (Simple REST controller)
├── src/main/resources/
│   └── application.properties (Application configuration)
├── .github/
│   ├── dependabot.yml (Dependabot configuration)
│   └── workflows/
│       └── sync-master-to-master-jdk21.yml (Branch sync workflow)
└── pom.xml (Maven configuration)
```

## Features

### Spring Boot Setup
- Spring Boot 3.2.0
- JDK 21
- Spring Web for REST APIs
- Spring Data JPA with H2 database
- Spring Boot Actuator for monitoring

### Dependabot Configuration
The project is configured with Dependabot to:
- Scan for vulnerable dependencies weekly
- Create automated PRs for security updates
- Apply appropriate labels and assignees

### GitHub Actions Workflow
The repository includes a GitHub Actions workflow that:
- Monitors for pushes to the `master` branch
- Automatically creates a PR to sync changes from `master` to `master-jdk21`
- Uses peter-evans/create-pull-request action for reliable PR creation

## Getting Started

To run this application locally:

```bash
./mvnw spring-boot:run
```

The application will be available at http://localhost:8080

## Branches
- `master`: Main development branch
- `master-jdk21`: JDK 21 specific branch that stays in sync with master

## Note on GitHub Actions
Make sure to add the GH_TOKEN secret to your repository for the GitHub Actions workflow to function properly.
