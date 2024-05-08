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
}

func checkHttpResponse(url string, item Item) error {
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("Failed to send request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("URL %s did not return status code 200, got: %d", url, resp.StatusCode)
	}

	return nil
}

func main() {
	vars := []string{
		"ACTION",
		"SWCI",
		"SUFFIX",
		"REGION",
		"OP_ENVIRONMENT",
	}

	for _, v := range vars {
		fmt.Printf("%s: %s\n", v, os.Getenv(v))
	}

	item := Item{
		Action:        os.Getenv("ACTION"),
		Swci:          os.Getenv("SWCI"),
		Suffix:        os.Getenv("SUFFIX"),
		Region:        os.Getenv("REGION"),
		OpEnvironment: os.Getenv("OP_ENVIRONMENT"),
	}

	filename := fmt.Sprintf("../region/%s.env", item.Region)
	fileContent, err := os.ReadFile(filename)
	if err != nil {
		log.Fatalf("Error reading file: %v", err)
	}

	lines := strings.Split(string(fileContent), "\n")
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

	domain := os.Getenv("domain")
	url := "http://example.com"
	fmt.Printf("Suffix: %s\n", item.Suffix)
	if strings.HasPrefix(item.Suffix, "ob-test") && (item.Action == "add") {
		for i := 0; i < 10; i++ {
			url = fmt.Sprintf("https://%s.%s.%s.%s", item.Swci, item.OpEnvironment, item.Suffix, domain)
			log.Printf("checking https Response from URL: %s", url)
			err = checkHttpResponse(url, item)
			if err == nil {
				break
			}

			time.Sleep(30 * time.Second)
		}

		if err != nil {
			log.Fatal(err)
		} else {
			log.Printf("App on %s, url up and running", url)
		}
	} else {
		fmt.Println("Suffix and Action do not equal 'ob-test*' and 'add' respectively, therefore test has not been run")
	}
}
