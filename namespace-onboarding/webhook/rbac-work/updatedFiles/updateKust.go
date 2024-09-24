package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v2"
)

type Item struct {
	Region        string
	Openvironment string // Changed from OpEnvironment to Openvironment
	Swci          string
	Suffix        string
	ClusterName   string
}

func getEnvVars() Item {
	vars := []string{
		"SWCI",
		"SUFFIX",
		"REGION",
		"OPENVIRONMENT", 
		"CLUSTERNAME",
	}

	item := Item{}

	for _, v := range vars {
		value := strings.ToLower(os.Getenv(v))
		fmt.Printf("%s: %s\n", v, value)

		switch v {
		case "SWCI":
			item.Swci = value
		case "SUFFIX":
			item.Suffix = value
		case "REGION":
			item.Region = value
		case "OPENVIRONMENT":
			item.Openvironment = value
		case "CLUSTERNAME":
			item.ClusterName = value
		}
	}

	return item
}

func updateKustomization(item Item) error {
	kustomizationPath := filepath.Join("environment", item.Openvironment, item.Region, item.ClusterName, "kustomization.yaml")

	log.Printf("Looking for kustomization.yaml at: %s", kustomizationPath)

	// Check if the directory exists
	dir := filepath.Dir(kustomizationPath)
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return fmt.Errorf("directory does not exist: %s", dir)
	}

	// Check if the file exists
	if _, err := os.Stat(kustomizationPath); os.IsNotExist(err) {
		return fmt.Errorf("kustomization.yaml does not exist at %s", kustomizationPath)
	}

	data, err := os.ReadFile(kustomizationPath)
	if err != nil {
		return fmt.Errorf("failed to read kustomization.yaml at %s: %v", kustomizationPath, err)
	}

	kustomization := make(map[string]interface{})
	if err := yaml.Unmarshal(data, &kustomization); err != nil {
		return fmt.Errorf("failed to unmarshal YAML data: %v", err)
	}

	newResource := fmt.Sprintf("%s-%s-%s", item.Swci, item.Openvironment, item.Suffix)

	resources, ok := kustomization["resources"].([]interface{})
	if !ok {
		return fmt.Errorf("failed to convert resources to slice")
	}

	for _, r := range resources {
		if r == newResource {
			log.Printf("Resource %s already exists in kustomization.yaml", newResource)
			return nil
		}
	}

	resources = append(resources, newResource)
	kustomization["resources"] = resources

	updatedData, err := yaml.Marshal(&kustomization)
	if err != nil {
		return fmt.Errorf("failed to marshal YAML data: %v", err)
	}

	if err := os.WriteFile(kustomizationPath, updatedData, 0644); err != nil {
		return fmt.Errorf("failed to write to kustomization.yaml: %v", err)
	}

	log.Printf("Successfully added resource %s to kustomization.yaml", newResource)
	return nil
}

func main() {
	item := getEnvVars()

	log.Printf("Updating kustomization for Openvironment: %s, Region: %s, ClusterName: %s", item.Openvironment, item.Region, item.ClusterName)

	if err := updateKustomization(item); err != nil {
		log.Fatalf("Error updating kustomization: %v", err)
	}
}
