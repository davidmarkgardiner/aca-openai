package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

type Item struct {
	Action        string
	Swci          string
	Suffix        string
	Region        string
	OpEnvironment string
	Domain        string
}

func checkHTTPResponse(url string) error {
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("URL %s returned status code %d, expected 200", url, resp.StatusCode)
	}

	return nil
}

func getEnvVars() Item {
	vars := []string{
		"ACTION",
		"SWCI",
		"SUFFIX",
		"REGION",
		"OP_ENVIRONMENT",
		"DOMAIN",
	}

	item := Item{}

	for _, v := range vars {
		value := os.Getenv(v)
		fmt.Printf("%s: %s\n", v, value)

		switch v {
		case "ACTION":
			item.Action = value
		case "SWCI":
			item.Swci = value
		case "SUFFIX":
			item.Suffix = value
		case "REGION":
			item.Region = value
		case "OP_ENVIRONMENT":
			item.OpEnvironment = value
		case "DOMAIN":
			item.Domain = value
		}
	}

	return item
}

func main() {
	item := getEnvVars()

	url := fmt.Sprintf("https://%s-%s-%s.%s", item.Swci, item.OpEnvironment, item.Suffix, item.Domain)
	fmt.Printf("Suffix: %s\n", item.Suffix)

	if strings.HasPrefix(item.Suffix, "ob-test") && item.Action == "add" {
		const maxRetries = 10
		const retryDelay = 5 * time.Second

		log.Printf("Checking HTTP response from URL: %s", url)

		var err error
		for i := 0; i < maxRetries; i++ {
			err = checkHTTPResponse(url)
			if err == nil {
				log.Printf("App on %s is up and running", url)
				return
			}
			log.Printf("Attempt %d failed: %v. Retrying in %v...", i+1, err, retryDelay)
			time.Sleep(retryDelay)
		}

		log.Fatalf("Failed to get a successful response after %d attempts: %v", maxRetries, err)
	} else {
		log.Println("Suffix and Action do not meet the criteria for running the test")
	}
}