package main

// Import necessary packages
import (
	// "encoding/json" // For JSON processing
	"crypto/rand"
	"encoding/hex"
	"fmt" // For console output
	"io"
	"log"
	// "log"
	// "io"
	"os" // For filesystem operations
	// "os/exec"
	"path/filepath" // For file path manipulation
	"strings"       // For string manipulation
)

// Item represents the structure of the data in the JSON files
type Item struct {
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
		Action:                 os.Getenv("ACTION"),
		Swci:                   os.Getenv("SWCI"),
		Suffix:                 os.Getenv("SUFFIX"),
		Region:                 os.Getenv("REGION"),
		OpEnvironment:          os.Getenv("OP_ENVIRONMENT"),
		ResourceQuotaCPU:       os.Getenv("RESOURCE_QUOTA_CPU"),
		ResourceQuotaMemoryGB:  os.Getenv("RESOURCE_QUOTA_MEMORY_GB"),
		ResourceQuotaStorageGB: os.Getenv("RESOURCE_QUOTA_STORAGE_GB"),
		BillingReference:       os.Getenv("BILLING_REFERENCE"),
		Source:                 os.Getenv("SOURCE"),
		SwcID:                  os.Getenv("SWC_ID"),
		DataClassification:     os.Getenv("DATA_CLASSIFICATION"),
		AppSubDomain:           os.Getenv("APP_SUBDOMAIN"),
		AllowAccessFromNS:      os.Getenv("ALLOW_ACCESS_FROM_NS"),
		RequestedBy:            os.Getenv("REQUESTED_BY"),
	}

	// t.Logf("Action: %s\n", data.Action)
	// t.Logf("Swci: %s\n", data.Swci)
	// t.Logf("Suffix: %s\n", data.Suffix)
	// t.Logf("Region: %s\n", data.Region)
	// t.Logf("OpEnvironment: %s\n", data.OpEnvironment)
	// t.Logf("ResourceQuotaCPU: %s\n", data.ResourceQuotaCPU)
	// t.Logf("ResourceQuotaMemoryGB: %s\n", data.ResourceQuotaMemoryGB)
	// t.Logf("ResourceQuotaStorageGB: %s\n", data.ResourceQuotaStorageGB)
	// t.Logf("BillingReference: %s\n", data.BillingReference)
	// t.Logf("Source: %s\n", data.Source)
	// t.Logf("Swc: %s\n", data.SwcID)
	// t.Logf("DataClassification: %s\n", data.DataClassification)
	// t.Logf("AppSubdomain: %s\n", data.AppSubdomain)
	// t.Logf("AllowAccessFromNS: %s\n", data.AllowAccessFromNS)
	// t.Logf("RequestedBy: %s\n", data.RequestedBy)
	// item.Region = os.Getenv("REGION")
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
	// create unique idnetifier for each namepace
	// Create a byte slice with a length of 16
	b := make([]byte, 16)

	// Generate a random sequence of bytes
	_, err = rand.Read(b)
	if err != nil {
		fmt.Println(err)
		return
	}

	// Encode the byte slice as a hexadecimal string
	uniqueId := hex.EncodeToString(b)

	// fmt.Println(uniqueId)
	// if item is uppercase, convert to lowercase
	item.Action = strings.ToLower(item.Action)
	item.Swci = strings.ToLower(item.Swci)
	item.Suffix = strings.ToLower(item.Suffix)
	item.Region = strings.ToLower(item.Region)
	item.DataClassification = strings.ToLower(item.DataClassification)
	item.AppSubDomain = strings.ToLower(item.AppSubDomain)
	item.AllowAccessFromNS = strings.ToLower(item.AllowAccessFromNS)
	item.RequestedBy = strings.ToLower(item.RequestedBy)
	item.OpEnvironment = strings.ToLower(item.OpEnvironment)

	// if item is lowercase, convert to uppercase
	item.BillingReference = strings.ToUpper(item.BillingReference)
	item.Source = strings.ToUpper(item.Source)
	item.SwcID = strings.ToUpper(item.SwcID)

	// if
	// Print environment variables
	clustername := os.Getenv("clustername")
	domain := os.Getenv("domain")
		// fmt.Println(clustername)
		// fmt.Println(domain)

	// clustername := ""
	// switch item.Region {
	// case "westeurope":
	// 	clustername = "kd469b39473-we01"
	// case "eastus2":
	// 	clustername = "kd469b39473-eu01"
	// case "centralus":
	// 	clustername = "kd469b39473-cu01"
	// case "northeurope":
	// 	clustername = "kd469b39473crd01"
	// }
	// domain := "test-akseng-gitops.azpriv-cloud.ubs.net"
	if item.AppSubDomain == "" {
		item.AppSubDomain = item.Swci + "-" + item.OpEnvironment + "-" + item.Suffix
	}
	if item.Action == "add" || item.Action == "modify" {
		// Directory to create for the environment
		dir := fmt.Sprintf("../environment/%s/%s/%s-%s", item.Region, clustername, item.Swci, item.Suffix)

		// Create the directory
		err = os.MkdirAll(dir, os.ModePerm)
		if err != nil {
			fmt.Println("Error creating directory:", err)
			return
		}
		fmt.Println("Creating directory for", dir)

		files, _ := filepath.Glob("../kustomize/overlay/*.yaml")

		// Process each YAML file
		for _, file := range files {
			// Read the YAML file
			data, err := os.ReadFile(file)
			if err != nil {
				fmt.Println("Error reading file:", err)
				continue
			}

			content := string(data)
			// Replace placeholders in the content

			content = strings.Replace(content, "${swci}", item.Swci, -1)
			content = strings.Replace(content, "${suffix}", item.Suffix, -1)
			content = strings.Replace(content, "${region}", item.Region, -1)
			content = strings.Replace(content, "${clustername}", clustername, -1)
			content = strings.Replace(content, "${appSubDomain}", item.AppSubDomain, -1)
			content = strings.Replace(content, "${swcID}", item.SwcID, -1)
			content = strings.Replace(content, "${requestedBy}", item.RequestedBy, -1)
			content = strings.Replace(content, "${opEnvironment}", item.OpEnvironment, -1)
			content = strings.Replace(content, "${resourceQuotaCPU}", item.ResourceQuotaCPU, -1)
			content = strings.Replace(content, "${resourceQuotaMemoryGB}", item.ResourceQuotaMemoryGB, -1)
			content = strings.Replace(content, "${resourceQuotaStorageGB}", item.ResourceQuotaStorageGB, -1)
			content = strings.Replace(content, "${billingReference}", item.BillingReference, -1)
			// content = strings.Replace(content, "${ticketReference}", item.TicketReference, -1)
			content = strings.Replace(content, "${source}", item.Source, -1)
			content = strings.Replace(content, "${allowAccessFromNS}", item.AllowAccessFromNS, -1)
			content = strings.Replace(content, "${dataClassification}", item.DataClassification, -1)
			content = strings.Replace(content, "${domain}", domain, -1)
			content = strings.Replace(content, "${action}", item.Action, -1)
			content = strings.Replace(content, "${uniqueId}", uniqueId, -1)
			// Write the modified content to the destination file
			destFile := filepath.Join(dir, filepath.Base(file))
			err = os.WriteFile(destFile, []byte(content), os.ModePerm)
			if err != nil {
				fmt.Println("Error writing file:", err)
				continue
			}
			os.Remove(filepath.Join(dir, "kustomization-delete.yaml"))
			// os.Rename(filepath.Join(dir, "kustomization-apptest.yaml"), filepath.Join(dir, "kustomize.yaml"))
			// os.Rename(filepath.Join(dir, "kustomization-overlay.yaml"), filepath.Join(dir, "kustomization.yaml"))
			// os.Remove(filepath.Join(dir, "kustomize-overlay"))
			// os.Remove(filepath.Join(dir, "kustomize-testapp"))

		}
		if !strings.HasPrefix(item.Suffix, "ob-test") {
			os.Remove(filepath.Join(dir, "app.yaml"))
			// os.Rename(filepath.Join(dir, "kustomization-apptest.yaml"), filepath.Join(dir, "kustomize.yaml"))
			// os.Rename(filepath.Join(dir, "kustomization-overlay.yaml"), filepath.Join(dir, "kustomization.yaml"))
			os.Remove(filepath.Join(dir, "kustomize-apptest.yaml"))
		} else {
			os.Remove(filepath.Join(dir, "kustomize.yaml"))
			srcFile, err := os.Open(filepath.Join(dir, "kustomize-apptest.yaml"))
			if err != nil {
				log.Fatal(err)
			}
			defer srcFile.Close()

			dstFile, err := os.Create(filepath.Join(dir, "kustomize.yaml"))
			if err != nil {
				log.Fatal(err)
			}
			defer dstFile.Close()

			_, err = io.Copy(dstFile, srcFile)
			if err != nil {
				log.Fatal(err)
			}
			os.Remove(filepath.Join(dir, "kustomization-apptest.yaml"))
			//neeed to come back and ammend this to allow array of swci at12345, at98765, at55555
			// If access from NS is allowed and the action is not "Remove"
			// if item.AllowAccessFromNS != "null" {
			// // Create a namespace selector
			// data := []byte(fmt.Sprintf("\n\n- namespaceSelector:\n\n    matchLabels:\n\n      namespace: %s\n\n", item.AllowAccessFromNS))
			// // Write the namespace selector to a file
			// err = os.WriteFile(filepath.Join(dir, "network-policy-ns.yaml"), data, os.ModeAppend)
			// }
		}

		// cmd := exec.Command("./kustomize/updateAppsKust.sh", "environment/"+item.Region+"/"+clustername, "at")
		// err := cmd.Run()
		// if err != nil {
		// 	log.Fatalf("cmd.Run() failed with %s\n", err)
		// }
	} else if item.Action == "remove" {
		// Directory for the environment to be removed
		dir := fmt.Sprintf("../environment/%s/%s/%s-%s", item.Region, clustername, item.Swci, item.Suffix)

		// Read the delete kustomization file
		data, _ := os.ReadFile("../kustomize/overlay/kustomization-delete.yaml")
		content := string(data)

		// Replace placeholders in the content
		content = strings.Replace(content, "${swci}", item.Swci, -1)
		content = strings.Replace(content, "${suffix}", item.Suffix, -1)
		content = strings.Replace(content, "${region}", item.Region, -1)
		content = strings.Replace(content, "${clustername}", clustername, -1)
		content = strings.Replace(content, "${appSubDomain}", item.AppSubDomain, -1)
		content = strings.Replace(content, "${swcID}", item.SwcID, -1)
		content = strings.Replace(content, "${requestedBy}", item.RequestedBy, -1)
		content = strings.Replace(content, "${opEnvironment}", item.OpEnvironment, -1)
		content = strings.Replace(content, "${resourceQuotaCPU}", item.ResourceQuotaCPU, -1)
		content = strings.Replace(content, "${resourceQuotaMemoryGB}", item.ResourceQuotaMemoryGB, -1)
		content = strings.Replace(content, "${resourceQuotaStorageGB}", item.ResourceQuotaStorageGB, -1)
		content = strings.Replace(content, "${billingReference}", item.BillingReference, -1)
		// content = strings.Replace(content, "${ticketReference}", item.TicketReference, -1)
		content = strings.Replace(content, "${source}", item.Source, -1)
		content = strings.Replace(content, "${allowAccessFromNS}", item.AllowAccessFromNS, -1)
		content = strings.Replace(content, "${dataClassification}", item.DataClassification, -1)
		content = strings.Replace(content, "${domain}", domain, -1)
		content = strings.Replace(content, "${action}", item.Action, -1)
		content = strings.Replace(content, "${uniqueId}", uniqueId, -1)
		// Write the modified content to the kustomization file in the directory
		os.WriteFile(filepath.Join(dir, "kustomization-delete.yaml"), []byte(content), os.ModePerm)

		// os.Remove(filepath.Join(dir, "kustomize.yaml"))
		srcFile, err := os.Open(filepath.Join(dir, "kustomization-delete.yaml"))
		if err != nil {
			log.Fatal(err)
		}
		defer srcFile.Close()

		dstFile, err := os.Create(filepath.Join(dir, "kustomize.yaml"))
		if err != nil {
			log.Fatal(err)
		}
		defer dstFile.Close()

		_, err = io.Copy(dstFile, srcFile)
		if err != nil {
			log.Fatal(err)
		}
		// os.Remove(filepath.Join(dir, "kustomization-delete.yaml"))
		// Find all YAML files in the directory
		files, _ := filepath.Glob(filepath.Join(dir, "*.yaml"))

		// Delete each file
		for _, file := range files {
			// Skip the kustomization.yaml file
			if filepath.Base(file) != "kustomize.yaml" {
				os.Remove(file)
			}
		}
		// Log the deletion
		fmt.Println("Deleting swci and np for", dir)
		fmt.Println("action == ", item.Action)
	} else {
		// If the action is not recognized, log an error and exit
		fmt.Println("Unknown action operation:", item.Action)
		os.Exit(1)
	}

}

