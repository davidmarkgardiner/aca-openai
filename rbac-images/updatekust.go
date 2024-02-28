package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v2"
)

// Data struct represents the structure of the JSON data
type Data struct {
	Region        string `json:"region"`
	OpEnvironment string `json:"opEnvironment"`
	Swci          string `json:"swci"`
	Suffix        string `json:"suffix"`
}

func main() {
	// Directory where the JSON files are located
	dataDir := "../../data2"
	// Read all files in the directory
	files, _ := os.ReadDir(dataDir)

	// Loop over each file
	for _, f := range files {
		// Process only JSON files
		if filepath.Ext(f.Name()) == ".json" {
			// Construct the full path of the JSON file
			jsonFile := filepath.Join(dataDir, f.Name())
			// Read the JSON file
			data, err := os.ReadFile(jsonFile)
			if err != nil {
				fmt.Println("Error reading file:", err)
				continue
			}

			// Unmarshal the JSON data into a Data struct
			var item Data
			err = json.Unmarshal(data, &item)
			if err != nil {
				fmt.Println("Error unmarshalling JSON:", err)
				continue
			}

			// Determine the cluster name based on the region
			clustername := ""
			switch item.Region {
			case "westeurope":
				clustername = "kd469b39473-we01"
			case "eastus2":
				clustername = "kd469b39473-eu01"
			case "centralus":
				clustername = "kd469b39473-cu01"
			case "northeurope":
				clustername = "kd469b39473crd01"
			}
			//     {
			//     // err := os.MkdirAll("../../environment2/westeurope/kd469b39473-we01", 0755)
			//     // if err != nil {
			//     //     log.Fatalf("Failed to create directory: %v", err)
			//     // }
			// }
			// Check if the file exists
			if _, err := os.Stat("../../environment2/" + item.Region + "/" + clustername + "/kustomization.yaml"); os.IsNotExist(err) {
				log.Fatalf("File does not exist: %v", err)
			}
			// Read the kustomization.yaml file
			data, err = os.ReadFile("../../environment2/" + item.Region + "/" + clustername + "/kustomization.yaml")
			// data, err = os.ReadFile("environment/" + item.Region + "/" + clustername + "/kustomization.yaml")
			if err != nil {
				log.Fatalf("Failed to read kustomization.yaml: %v", err)
			}

			// Unmarshal the YAML data into a map
			kustomization := make(map[string]interface{})
			err = yaml.Unmarshal(data, &kustomization)
			if err != nil {
				log.Fatalf("Failed to unmarshal YAML data: %v", err)
			}

			// Construct the new resource name
			resource := []string{item.Swci + "-" + item.OpEnvironment + "-" + item.Suffix}

			// Get the existing resources from the kustomization map
			existingResources, ok := kustomization["resources"].([]interface{})
			if !ok {
				log.Fatalf("Failed to convert resources to slice")
			}

			// Check if the new resource already exists in the resources
			resourceExists := false
			for _, r := range existingResources {
				if r == resource[0] {
					resourceExists = true
					break
				}
			}

			// If the resource doesn't exist, append it to the resources
			if !resourceExists {
				existingResources = append(existingResources, resource[0])
			}

			// Update the resources in the kustomization map
			kustomization["resources"] = existingResources

			// Marshal the kustomization map back into YAML
			data, err = yaml.Marshal(&kustomization)
			if err != nil {
				log.Fatalf("Failed to marshal YAML data: %v", err)
			}

			// Write the updated YAML back to the kustomization.yaml file
			err = os.WriteFile("../../environment2/"+item.Region+"/"+clustername+"/kustomization.yaml", data, 0644)
			if err != nil {
				log.Fatalf("Failed to write to kustomization.yaml: %v", err)
			}
		}
	}
}
