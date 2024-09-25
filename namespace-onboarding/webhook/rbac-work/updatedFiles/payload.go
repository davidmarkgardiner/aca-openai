package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v2"
)

type Kustomization struct {
	CommonLabels struct {
		OpEnvironment string `yaml:"opEnvironment"`
		Action        string `yaml:"action"`
	} `yaml:"commonLabels"`
	CommonAnnotations struct {
		AksResourceID     string `yaml:"aksresourceid"`
		FullNamespaceName string `yaml:"fullnamespacename"`
	} `yaml:"commonAnnotations"`
}

func main() {
	// Base directory
	baseDir := "environment"

	// Walk through the directory structure
	err := filepath.Walk(baseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Check if the file is kustomization.yaml
		if info.IsDir() || filepath.Base(path) != "kustomization.yaml" {
			return nil
		}

		// Read and parse the kustomization.yaml file
		data, err := ioutil.ReadFile(path)
		if err != nil {
			log.Printf("Error reading file %s: %v", path, err)
			return nil
		}

		var kustomization Kustomization
		err = yaml.Unmarshal(data, &kustomization)
		if err != nil {
			log.Printf("Error unmarshaling YAML in file %s: %v", path, err)
			return nil
		}

		// Check if the file should be skipped
		if kustomization.CommonLabels.Action == "remove" {
			log.Printf("Skipping file %s due to 'action: remove' label", path)
			return nil
		}

		// Extract required information
		openEnvironment := kustomization.CommonLabels.OpEnvironment
		aksResourceID := kustomization.CommonAnnotations.AksResourceID
		fullNamespaceName := kustomization.CommonAnnotations.FullNamespaceName

		// Prepare and send payload
		payload := map[string]string{
			"aksresourceid":  aksResourceID,
			"openvironment":  openEnvironment,
			"namespacename":  fullNamespaceName,
		}

		sendPayloadToPipeline(payload)

		return nil
	})

	if err != nil {
		log.Fatalf("Error walking through directory: %v", err)
	}
}

func sendPayloadToPipeline(payload map[string]string) {
	// This is a placeholder function. Implement the actual logic to send the payload to your pipeline.
	fmt.Printf("Sending payload to pipeline: %v\n", payload)
}