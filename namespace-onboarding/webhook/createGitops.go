package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"reflect"
	"strings"
)

// Config holds only the essential configuration options needed for git-repository.yaml processing
// Each field corresponds to a required environment variable
type Config struct {
	// Required for directory structure
	Region        string // Deployment region
	OpEnvironment string // Operational environment (dev/test/prod)
	NamespaceName string // Namespace name (combines swci, environment and suffix)

	// Required for git-repository.yaml content
	GitLabRepoURL string // URL of the GitLab repository
	BranchName    string // Branch to track
	FolderPath    string // Path within the repository
}

const (
	// Base directory for environment-specific configurations
	environmentDir = "environment"
	// Directory containing the source template
	overlayDir = "kustomize/overlay"
	// Name of the source template file
	sourceFileName = "git-repository.yaml"
)

func main() {
	// Configure logging to include file and line numbers for better debugging
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	log.Println("Starting git-repository.yaml generation...")

	// Load and validate configuration
	config, err := loadConfig()
	if err != nil {
		log.Fatalf("Configuration error: %v", err)
	}

	// Process the git-repository.yaml file
	if err := processGitRepository(config); err != nil {
		log.Fatalf("Processing error: %v", err)
	}

	log.Println("Successfully generated git-repository.yaml")
}

// loadConfig reads environment variables and returns a populated Config struct
// It also validates that all required fields are present
func loadConfig() (*Config, error) {
	log.Println("Loading configuration from environment variables...")
	config := &Config{}
	v := reflect.ValueOf(config).Elem()
	t := v.Type()

	// Load and validate each configuration field
	for i := 0; i < v.NumField(); i++ {
		field := t.Field(i)
		envVar := strings.ToUpper(field.Name)
		value := os.Getenv(envVar)

		// Check if required field is empty
		if value == "" {
			return nil, fmt.Errorf("required environment variable %s is not set", envVar)
		}

		// Store the value in the config struct
		v.Field(i).SetString(value)
		log.Printf("Loaded %s: %s", envVar, value)
	}

	// Apply case transformations for consistency
	config.Region = strings.ToLower(config.Region)
	config.OpEnvironment = strings.ToLower(config.OpEnvironment)
	config.NamespaceName = strings.ToLower(config.NamespaceName)
	config.GitLabRepoURL = strings.ToLower(config.GitLabRepoURL)
	config.BranchName = strings.ToLower(config.BranchName)
	config.FolderPath = strings.ToLower(config.FolderPath)

	return config, nil
}

// processGitRepository handles the creation and population of the git-repository.yaml file
func processGitRepository(config *Config) error {
	// Split the namespace name to check for test pattern
	nameParts := strings.Split(config.NamespaceName, "-")
	envDir := config.OpEnvironment

	// Check if namespace contains "-test-" pattern and modify accordingly
	if len(nameParts) >= 3 && nameParts[1] == "test" {
		envDir = "dev"
		// Create modified namespace name with "dev" instead of "test"
		nameParts[1] = "dev"
		modifiedNamespace := strings.Join(nameParts, "-")
		log.Printf("Modified namespace from %s to %s", config.NamespaceName, modifiedNamespace)
		config.NamespaceName = modifiedNamespace
	}

	// Construct the target directory path using modified namespacename
	targetDir := filepath.Join(
		environmentDir,
		envDir,
		config.Region,
		config.NamespaceName,
	)
	log.Printf("Target directory: %s", targetDir)

	// Create the target directory and any necessary parent directories
	if err := os.MkdirAll(targetDir, os.ModePerm); err != nil {
		return fmt.Errorf("failed to create directory %s: %v", targetDir, err)
	}

	// Read the source template file
	sourceFile := filepath.Join(overlayDir, sourceFileName)
	content, err := os.ReadFile(sourceFile)
	if err != nil {
		return fmt.Errorf("failed to read template file %s: %v", sourceFile, err)
	}

	// Replace placeholders in the content
	replacedContent := string(content)
	v := reflect.ValueOf(*config)
	t := v.Type()

	// Replace each config field's placeholder in the template
	for i := 0; i < v.NumField(); i++ {
		fieldName := t.Field(i).Name
		fieldValue := v.Field(i).String()
		placeholder := "${" + strings.ToLower(fieldName) + "}"
		replacedContent = strings.ReplaceAll(replacedContent, placeholder, fieldValue)
	}

	// Write the processed content to the destination file
	destFile := filepath.Join(targetDir, sourceFileName)
	if err := os.WriteFile(destFile, []byte(replacedContent), 0644); err != nil {
		return fmt.Errorf("failed to write file %s: %v", destFile, err)
	}

	log.Printf("Successfully created: %s", destFile)
	return nil
}
