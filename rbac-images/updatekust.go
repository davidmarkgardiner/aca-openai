package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v2"
)

type Data struct {
	Region        string `json:"region"`
	OpEnvironment string `json:"opEnvironment"`
	Swci          string `json:"swci"`
	Suffix        string `json:"suffix"`
}

func main() {
	dataDir := "../../data2"
	files, err := os.ReadDir(dataDir)
	if err != nil {
		log.Fatalf("Failed to read directory: %v", err)
	}

	for _, f := range files {
		if filepath.Ext(f.Name()) == ".json" {
			processFile(filepath.Join(dataDir, f.Name()))
		}
	}
}

func processFile(jsonFile string) {
	data, err := os.ReadFile(jsonFile)
	if err != nil {
		log.Printf("Error reading file: %v", err)
		return
	}

	var item Data
	err = json.Unmarshal(data, &item)
	if err != nil {
		log.Printf("Error unmarshalling JSON: %v", err)
		return
	}

	clustername := getClusterName(item.Region)
	kustomizationPath := fmt.Sprintf("../../environment2/%s/%s/kustomization.yaml", item.Region, clustername)

	if _, err := os.Stat(kustomizationPath); os.IsNotExist(err) {
		log.Fatalf("File does not exist: %v", err)
	}

	processKustomization(kustomizationPath, item)
}

func getClusterName(region string) string {
	switch region {
	case "westeurope":
		return "kd469b39473-we01"
	case "eastus2":
		return "kd469b39473-eu01"
	case "centralus":
		return "kd469b39473-cu01"
	case "northeurope":
		return "kd469b39473crd01"
	default:
		return ""
	}
}

func processKustomization(kustomizationPath string, item Data) {
	data, err := os.ReadFile(kustomizationPath)
	if err != nil {
		log.Fatalf("Failed to read kustomization.yaml: %v", err)
	}

	kustomization := make(map[string]interface{})
	err = yaml.Unmarshal(data, &kustomization)
	if err != nil {
		log.Fatalf("Failed to unmarshal YAML data: %v", err)
	}

	resource := item.Swci + "-" + item.OpEnvironment + "-" + item.Suffix
	existingResources := appendResource(kustomization, resource)

	kustomization["resources"] = existingResources

	data, err = yaml.Marshal(&kustomization)
	if err != nil {
		log.Fatalf("Failed to marshal YAML data: %v", err)
	}

	err = os.WriteFile(kustomizationPath, data, 0644)
	if err != nil {
		log.Fatalf("Failed to write to kustomization.yaml: %v", err)
	}
}

func appendResource(kustomization map[string]interface{}, resource string) []interface{} {
	existingResources, ok := kustomization["resources"].([]interface{})
	if !ok {
		log.Fatalf("Failed to convert resources to slice")
	}

	for _, r := range existingResources {
		if r == resource {
			return existingResources
		}
	}

	return append(existingResources, resource)
}
