package main

import (
	"fmt"
	"os"
	"regexp"
	"testing"
)

type Data struct {
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
	AppSubdomain           string
	AllowAccessFromNS      string
	RequestedBy            string
}

func TestJsonValidationAllFiles(t *testing.T) {

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

	data := Data{
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
		AppSubdomain:           os.Getenv("APP_SUBDOMAIN"),
		AllowAccessFromNS:      os.Getenv("ALLOW_ACCESS_FROM_NS"),
		RequestedBy:            os.Getenv("REQUESTED_BY"),
	}

	if !isValidAction(data.Action) || !isValidSwci(data.Swci) || !isValidSuffix(data.Suffix) ||
		!isValidRegion(data.Region) || !isValidOpEnvironment(data.OpEnvironment) ||
		!isValidResourceQuota(data.ResourceQuotaCPU) || !isValidBillingReference(data.BillingReference) ||
		!isValidRequestedBy(data.RequestedBy) || !isValidAllowAccessFromNS(data.AllowAccessFromNS) ||
		!isValidDataClassification(data.DataClassification) {
		t.Fail()
	}
	t.Logf("Action: %s\n", data.Action)
	t.Logf("Swci: %s\n", data.Swci)
	t.Logf("Suffix: %s\n", data.Suffix)
	t.Logf("Region: %s\n", data.Region)
	t.Logf("OpEnvironment: %s\n", data.OpEnvironment)
	t.Logf("ResourceQuota: %s\n", data.ResourceQuotaCPU)
	t.Logf("BillingReference: %s\n", data.BillingReference)
	t.Logf("Source: %s\n", data.Source)
	t.Logf("Swc: %s\n", data.SwcID)
	t.Logf("DataClassification: %s\n", data.DataClassification)
	t.Logf("AppSubdomain: %s\n", data.AppSubdomain)
	t.Logf("AllowAccessFromNS: %s\n", data.AllowAccessFromNS)
	t.Logf("RequestedBy: %s\n", data.RequestedBy)
}

// verify that data.Action is one of the allowed values ("Add", "Remove", or "Update")
func isValidAction(action string) bool {
	switch action {
	case "Add", "Remove", "Update":
		return true
	default:
		fmt.Printf("Invalid action: %s. Allowed values are Add, Remove, Update.\n", action)
		return false
	}
}

// verify that data.Swci starts with "at" and is followed by exactly 5 numbers,
func isValidSwci(swci string) bool {
	match, err := regexp.MatchString(`^at\d{5}$`, swci)
	if err != nil {
		fmt.Println("Error while matching regex:", err)
		return false
	}
	if match {
		return true
	} else {
		fmt.Printf("Invalid Swci: %s. It should start with 'at' followed by exactly 5 numbers.\n", swci)
		return false
	}
}

// verify that data.Suffix is a maximum of 8 characters and contains only numbers, letters, and hyphens
func isValidSuffix(suffix string) bool {
	match, _ := regexp.MatchString(`^[a-zA-Z0-9-]{1,8}$`, suffix)
	if match {
		fmt.Printf("Suffix: %s\n", suffix)
		return true
	} else {
		fmt.Printf("Invalid Suffix: %s. It should be a maximum of 8 characters and contain only numbers, letters, and hyphens.\n", suffix)
		return false
	}
}

// verify that data.Region is one of the allowed values ("westeurope", "eastus2", or "centralus")
func isValidRegion(region string) bool {
	switch region {
	case "westeurope", "eastus2", "centralus":
		fmt.Printf("Region: %s\n", region)
		return true
	default:
		fmt.Printf("Invalid region: %s. Allowed values are westeurope, eastus2, centralus.\n", region)
		return false
	}
}
func isValidOpEnvironment(opEnvironment string) bool {
	// verify that data.OPEnvironment is one of the allowed values ("dev", "prod", "te1", or "te2"),
	switch opEnvironment {
	case "dev", "prod", "te1", "te2":
		fmt.Printf("OPEnvironment: %s\n", opEnvironment)
		return true
	default:
		fmt.Printf("Invalid OPEnvironment: %s. Allowed values are dev, prod, te1, te2.\n", opEnvironment)
		return false
	}
}

// data.ResourceQuota is one of the allowed values ("small", "medium", or "large")
func isValidResourceQuota(resourceQuota string) bool {
	switch resourceQuota {
	case "small", "medium", "large":
		fmt.Printf("ResourceQuota: %s\n", resourceQuota)
		return true
	default:
		fmt.Printf("Invalid ResourceQuota: %s. Allowed values are small, medium, large.\n", resourceQuota)
		return false
	}
}

// verify that data.BillingReference is in the format "AB-BC-ABCDE-ABCDE" and contains only letters,
func isValidBillingReference(billingReference string) bool {
	match, _ := regexp.MatchString(`^[A-Za-z]{2}-[A-Za-z]{2}-[A-Za-z]{5}-[A-Za-z]{5}$`, billingReference)
	if match {
		fmt.Printf("BillingReference: %s\n", billingReference)
		return true
	} else {
		fmt.Printf("Invalid BillingReference: %s. It should be in the format AB-BC-DEPT-ABCDE and contain only letters.\n", billingReference)
		return false
	}
}

// verify that data.RequestedBy is an email like "david.gardiner@ubs.com", a GPN like "43709651", or a T number like "t69332"
func isValidRequestedBy(requestedBy string) bool {
	emailMatch, _ := regexp.MatchString(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`, requestedBy)
	gpnMatch, _ := regexp.MatchString(`^[0-9]{8}$`, requestedBy)
	tNumberMatch, _ := regexp.MatchString(`^t[0-9]{5}$`, requestedBy)

	if emailMatch || gpnMatch || tNumberMatch {
		fmt.Printf("RequestedBy: %s\n", requestedBy)
		return true
	} else {
		fmt.Printf("Invalid RequestedBy: %s. It should be an email like david.gardiner@ubs.com, a GPN like 43709651, or a T number like t69332.\n", requestedBy)
		return false
	}
}

// verify that data.AllowAccessFromNS starts with  "at" and is followed by exactly 5 numbers only if it is not empty
func isValidAllowAccessFromNS(allowAccessFromNS string) bool {
	if allowAccessFromNS == "" {
		fmt.Println("AllowAccessFromNS: <empty>")
		return true
	}
	match, _ := regexp.MatchString(`^at[0-9]{5}$`, allowAccessFromNS)
	if match {
		fmt.Printf("AllowAccessFromNS: %s\n", allowAccessFromNS)
		return true
	} else {
		fmt.Printf("Invalid AllowAccessFromNS: %s. It should start with 'at' and be followed by exactly 5 numbers.\n", allowAccessFromNS)
		return false
	}
}

// verify that data.DataClassification is one of the allowed values ("public", "internal", "confidential", or "restricted"
func isValidDataClassification(dataClassification string) bool {
	switch dataClassification {
	case "public", "internal", "confidential", "restricted":
		fmt.Printf("DataClassification: %s\n", dataClassification)
		return true
	default:
		fmt.Printf("Invalid DataClassification: %s. Allowed values are public, internal, confidential, restricted.\n", dataClassification)
		return false
	}
}
