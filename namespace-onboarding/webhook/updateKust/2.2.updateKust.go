package main

import (
    // "encoding/json"
    "fmt"
    "log"
    "os"
    "strings"
    // "path/filepath"

    "gopkg.in/yaml.v2"
)

// Data struct represents the structure of the JSON data
type Item struct {
    Region        string 
    OpEnvironment string 
    Swci          string 
    Suffix        string 
}

func main() {
            vars := []string{
                "ACTION",
                "SWCI",
                "SUFFIX",
                "REGION",
                "OP_ENVIRONMENT",
                "RESOURCE_QUOTA_CPU",
                "RESOURCE_QUOTA_MEMORY_GB",
                "RESOURCE_QUOTA_STORAGE_GB",
                "BILLING_REFERENCE",
                "SOURCE",
                "SWC_ID",
                "DATA_CLASSIFICATION",
                "APP_SUBDOMAIN",
                "ALLOW_ACCESS_FROM_NS",
                "REQUESTED_BY",
            }

            for _, v := range vars {
                fmt.Printf("%s: %s\n", v, os.Getenv(v))
            }

            item := Item{
                Swci:                   os.Getenv("SWCI"),
                Suffix:                 os.Getenv("SUFFIX"),
                Region:                 os.Getenv("REGION"),
                OpEnvironment:          os.Getenv("OP_ENVIRONMENT"),
            }

            var data []byte
            var err error
            // Construct the filename based on the region
            filename := fmt.Sprintf("../region/%s.env", item.Region)
            // filename := filename1
            // Read the .env file
            data, err = os.ReadFile(filename)
            if err != nil {
                fmt.Println("Error reading file:", err)
                return
            }

            // Split the file contents by line
            lines := strings.Split(string(data), "\n")

            // Iterate over the lines
            for _, line := range lines {
                // Split the line into a key and a value
                parts := strings.SplitN(line, "=", 2)
                if len(parts) != 2 {
                    fmt.Println("Invalid line:", line)
                    continue
                }

                // Set the environment variable
                key := parts[0]
                value := parts[1]
                os.Setenv(key, value)
            }
            clustername := os.Getenv("clustername")
            // Read the kustomization.yaml file
            data, err = os.ReadFile("../environment/" + item.OpEnvironment + "/" + item.Region + "/" + clustername + "/kustomization.yaml")
            // data, err = os.ReadFile("../environment/" + item.Region + "/" + clustername + "/kustomization.yaml")
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
            err = os.WriteFile("../environment/"+item.OpEnvironment+"/"+item.Region+"/"+clustername+"/kustomization.yaml", data, 0644)
            // err = os.WriteFile("../environment/"+item.Region+"/"+clustername+"/kustomization.yaml", data, 0644)
            if err != nil {
                log.Fatalf("Failed to write to kustomization.yaml: %v", err)
            }
        }