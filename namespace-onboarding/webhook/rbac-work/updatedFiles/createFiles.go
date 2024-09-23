package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"

	"log"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	// "text/template"
)

const (
	environmentDir = "environment"
	kustomizeDir   = "kustomize/overlay"
)

// Config holds all the configuration options loaded from environment variables
type Config struct {
	Action                 string
	Swci                   string
	Suffix                 string
	Region                 string
	OpEnvironment          string
	ResourceQuotaCPU       string
	ResourceQuotaMemoryGB  string
	ResourceQuotaStorageGB string
	BillingReference       string
	Source                 string
	SwcID                  string
	DataClassification     string
	AppSubDomain           string
	AllowAccessFromNS      string
	RequestedBy            string
	Sub                    string
	Rg                     string
	ClusterName            string
	ID                     string
}

func main() {
	// Set up logging to include line numbers
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	log.Println("Starting the script...")

	// Load configuration from environment variables
	config, err := loadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Determine which action to take based on the 'Action' field
	switch strings.ToLower(config.Action) {
	case "add", "modify":
		log.Println("Performing add/modify action...")
		err = handleAddOrModify(config)
	case "remove":
		log.Println("Performing remove action...")
		err = handleRemove(config)
	default:
		log.Fatalf("Unknown action: %s", config.Action)
	}

	if err != nil {
		log.Fatalf("Operation failed: %v", err)
	}

	log.Println("Script completed successfully.")
}

// loadConfig reads environment variables and populates the Config struct
func loadConfig() (*Config, error) {
	log.Println("Loading configuration from environment variables...")
	config := &Config{}
	v := reflect.ValueOf(config).Elem()

	for i := 0; i < v.NumField(); i++ {
		field := v.Type().Field(i)
		envVar := strings.ToUpper(field.Name)
		value := os.Getenv(envVar)
		v.Field(i).SetString(value)
		log.Printf("Loaded %s: %s", envVar, value)
	}

	// Generate random ID
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return nil, fmt.Errorf("failed to generate random ID: %v", err)
	}
	config.ID = hex.EncodeToString(b)
	log.Printf("Generated random ID: %s", config.ID)

	// Set default values and perform transformations
	if config.AppSubDomain == "" {
		config.AppSubDomain = fmt.Sprintf("%s-%s-%s", config.Swci, config.OpEnvironment, config.Suffix)
		log.Printf("Set default AppSubDomain: %s", config.AppSubDomain)
	}
	if config.ResourceQuotaCPU == "" {
		config.ResourceQuotaCPU = "4"
		log.Println("Set default ResourceQuotaCPU: 4")
	}
	if config.ResourceQuotaMemoryGB == "" {
		config.ResourceQuotaMemoryGB = "8"
		log.Println("Set default ResourceQuotaMemoryGB: 8")
	}
	if config.ResourceQuotaStorageGB == "" {
		config.ResourceQuotaStorageGB = "0"
		log.Println("Set default ResourceQuotaStorageGB: 0")
	}

	// Apply case transformations
	log.Println("Applying case transformations...")
	config.Action = strings.ToLower(config.Action)
	config.Swci = strings.ToLower(config.Swci)
	config.Suffix = strings.ToLower(config.Suffix)
	config.Region = strings.ToLower(config.Region)
	config.OpEnvironment = strings.ToLower(config.OpEnvironment)
	config.Sub = strings.ToLower(config.Sub)
	config.Rg = strings.ToLower(config.Rg)
	config.ClusterName = strings.ToLower(config.ClusterName)
	config.DataClassification = strings.ToLower(config.DataClassification)
	config.AppSubDomain = strings.ToLower(config.AppSubDomain)
	config.AllowAccessFromNS = strings.ToLower(config.AllowAccessFromNS)
	config.RequestedBy = strings.ToLower(config.RequestedBy)

	config.BillingReference = strings.ToUpper(config.BillingReference)
	config.Source = strings.ToUpper(config.Source)
	config.SwcID = strings.ToUpper(config.SwcID)

	return config, nil
}

func handleAddOrModify(config *Config) error {
    // Construct the target directory path
    dir := filepath.Join(environmentDir, config.OpEnvironment, config.Region, config.ClusterName, 
                         fmt.Sprintf("%s-%s-%s", config.Swci, config.OpEnvironment, config.Suffix))
    log.Printf("Target directory: %s", dir)

    // Create the target directory
    if err := os.MkdirAll(dir, os.ModePerm); err != nil {
        return fmt.Errorf("failed to create directory %s: %v", dir, err)
    }
    log.Println("Created target directory")

    // Get all YAML files from the kustomize overlay directory
    files, err := filepath.Glob(filepath.Join(kustomizeDir, "*.yaml"))
    if err != nil {
        return fmt.Errorf("failed to glob files: %v", err)
    }
    log.Printf("Found %d YAML files in kustomize overlay directory", len(files))

    isObTest := strings.HasPrefix(config.Suffix, "ob-test")

    // Determine which kustomization file to use
    kustomizationFile := "kustomization.yaml"
    if isObTest {
        kustomizationFile = "kustomization-apptest.yaml"
    }

    // Process each YAML file
    for _, file := range files {
        baseFileName := filepath.Base(file)
        
        // Skip kustomization files that we don't want
        if (baseFileName == "kustomization.yaml" || baseFileName == "kustomization-apptest.yaml") && 
           baseFileName != kustomizationFile {
            log.Printf("Skipping file: %s", baseFileName)
            continue
        }
        
        // Skip kustomization-delete.yaml for both add and modify actions
        if baseFileName == "kustomization-delete.yaml" {
            log.Printf("Skipping file: %s", baseFileName)
            continue
        }

        // Skip app.yaml if not ob-test
        if baseFileName == "app.yaml" && !isObTest {
            log.Printf("Skipping app.yaml for non-ob-test case")
            continue
        }

        log.Printf("Processing file: %s", file)
        if err := processFile(file, dir, config); err != nil {
            return err
        }

        // Rename kustomization file for ob-test case
        if isObTest && baseFileName == "kustomization-apptest.yaml" {
            log.Println("Renaming kustomization-apptest.yaml to kustomization.yaml...")
            if err := os.Rename(filepath.Join(dir, "kustomization-apptest.yaml"), filepath.Join(dir, "kustomization.yaml")); err != nil {
                return fmt.Errorf("failed to rename kustomization-apptest.yaml: %v", err)
            }
        }
    }

    // Handle renaming for non "ob-test" suffixes in modify action
    if !isObTest && config.Action == "modify" {
        log.Println("Renaming kustomization.yaml to kustomization-prod.yaml...")
        if err := os.Rename(filepath.Join(dir, "kustomization.yaml"), filepath.Join(dir, "kustomization-prod.yaml")); err != nil {
            return fmt.Errorf("failed to rename kustomization.yaml: %v", err)
        }
    }

    return nil
}


// handleRemove processes the 'remove' action
func handleRemove(config *Config) error {
	// Construct the target directory path
	dir := filepath.Join(environmentDir, config.OpEnvironment, config.Region, config.ClusterName,
		fmt.Sprintf("%s-%s-%s", config.Swci, config.OpEnvironment, config.Suffix))
	log.Printf("Target directory for removal: %s", dir)

	// Process the kustomization-delete.yaml file
	deleteFile := filepath.Join(kustomizeDir, "kustomization-delete.yaml")
	log.Printf("Processing kustomization-delete file: %s", deleteFile)
	if err := processFile(deleteFile, dir, config); err != nil {
		return err
	}

	// Rename kustomization-delete.yaml to kustomization.yaml
	log.Println("Renaming kustomization-delete.yaml to kustomization.yaml...")
	if err := os.Rename(filepath.Join(dir, "kustomization-delete.yaml"), filepath.Join(dir, "kustomization.yaml")); err != nil {
		return fmt.Errorf("failed to rename kustomization-delete.yaml: %v", err)
	}

	// Remove all other YAML files in the directory
	files, err := filepath.Glob(filepath.Join(dir, "*.yaml"))
	if err != nil {
		return fmt.Errorf("failed to glob files: %v", err)
	}
	log.Printf("Found %d YAML files in target directory", len(files))

	for _, file := range files {
		if filepath.Base(file) != "kustomization.yaml" {
			log.Printf("Removing file: %s", file)
			if err := os.Remove(file); err != nil {
				return fmt.Errorf("failed to remove file %s: %v", file, err)
			}
		}
	}

	return nil
}
func processFile(srcFile, destDir string, config *Config) error {
	log.Printf("Processing file %s", srcFile)

	// Read the source file
	content, err := os.ReadFile(srcFile)
	if err != nil {
		return fmt.Errorf("failed to read file %s: %v", srcFile, err)
	}

	// Replace placeholders in the content
	replacedContent := string(content)
	v := reflect.ValueOf(*config)
	t := v.Type()

	for i := 0; i < v.NumField(); i++ {
		fieldName := t.Field(i).Name
		fieldValue := v.Field(i).String()
		placeholder := "${" + strings.ToLower(fieldName) + "}"
		replacedContent = strings.ReplaceAll(replacedContent, placeholder, fieldValue)
		log.Printf("Replaced %s with %s", placeholder, fieldValue)
	}

	// Create the destination file
	destFile := filepath.Join(destDir, filepath.Base(srcFile))
	if err := os.WriteFile(destFile, []byte(replacedContent), 0644); err != nil {
		return fmt.Errorf("failed to write file %s: %v", destFile, err)
	}

	log.Printf("Successfully processed and wrote file: %s", destFile)
	return nil
}
