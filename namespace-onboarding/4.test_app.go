package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
	// "testing"
)

type Data struct {
	Region        string `json:"region"`
	Suffix        string `json:"suffix"`
	Swci          string `json:"swci"`
	OpEnvironment string `json:"opEnvironment"`
	Action        string `json:"action"`
}

var domain string

func processFile(jsonFile string) (Data, error) {
	data, err := os.ReadFile(jsonFile)
	if err != nil {
		log.Printf("Error reading file: %v", err)
		return Data{}, err
	}

	var item Data
	err = json.Unmarshal(data, &item)
	if err != nil {
		log.Printf("Error unmarshalling JSON: %v", err)
		return Data{}, err
	}

	filename := fmt.Sprintf("region/%s.env", item.Region)
	data, err = os.ReadFile(filename)
	if err != nil {
		fmt.Println("Error reading file:", err)
		return Data{}, err
	}

	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			fmt.Println("Invalid line:", line)
			continue
		}

		key := parts[0]
		value := parts[1]
		os.Setenv(key, value)
	}

	domain = os.Getenv("domain")
	// fmt.Println(domain)
	return item, nil
}

func checkHttpResponse(url string, item Data) error {
	// url = fmt.Sprintf("https://%s.%s", item.Suffix, domain) // include http://
	url = fmt.Sprintf("https://%s.%s.%s.%s", item.Swci, item.OpEnvironment, item.Suffix, domain)
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("Failed to send request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("URL %s did not return status code 200, got: %d", url, resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("Failed to read response body: %v", err)
	}

	if !strings.Contains(string(body), "This is the Kubernetes Hello Whisky page.") {
		return fmt.Errorf("URL %s did not return the expected string", url)
	}

	return nil
}

// // url := fmt.Sprintf("%s.%s", item.Suffix, domain)
// func TestHttpResponse(t *testing.T) {
// 	item := Data{Suffix: "test", Region: "test"} // replace with your actual data
// 	err := checkHttpResponse("http://example.com", item)
// 	if err != nil {
// 		t.Fatal(err)
// 	}
// }


func main() {
	dataDir := "data2"
	files, err := os.ReadDir(dataDir)
	if err != nil {
		log.Fatalf("Failed to read directory: %v", err)
	}

	for _, f := range files {
		if filepath.Ext(f.Name()) == ".json" {
			item, err := processFile(filepath.Join(dataDir, f.Name()))
			if err != nil {
				log.Fatalf("Failed to process file: %v", err)
			}

			// Check if suffix starts with "onboarding-test"
			if strings.HasPrefix(item.Suffix, "onboarding-test") && (item.Action == "Add") {
				// Try for 5 minutes
				for i := 0; i < 10; i++ {
					// log.Printf("checking https Response from URL: https://%s.%s.%s.%s", item.Swci, item.OpEnvironment, item.Suffix, domain)
					url := fmt.Sprintf("https://%s.%s.%s.%s", item.Swci, item.OpEnvironment, item.Suffix, domain)
					log.Printf("checking https Response from URL: %s", url)
					err = checkHttpResponse("https://example.com", item)
					if err == nil {
						break
					}

					// Wait for 30 seconds before trying again
					time.Sleep(30 * time.Second)
				}

				if err != nil {
					log.Fatal(err)
				} else {
					log.Printf("App on %s, url up and running")
				}
			}
		}
	}
}
