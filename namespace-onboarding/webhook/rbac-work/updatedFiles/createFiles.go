package main

import (
    "crypto/rand"
    "encoding/hex"
    "fmt"
    "io/ioutil"
    "log"
    "os"
    "path/filepath"
    "reflect"
    "strings"
    "text/template"
)

const (
    environmentDir = "../environment"
    kustomizeDir   = "../kustomize/overlay"
)

type Config struct {
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
    Sub                    string
    Rg                     string
    ClusterName            string
    ID                     string
}

func main() {
    config, err := loadConfig()
    if err != nil {
        log.Fatalf("Failed to load configuration: %v", err)
    }

    switch strings.ToLower(config.Action) {
    case "add", "modify":
        err = handleAddOrModify(config)
    case "remove":
        err = handleRemove(config)
    default:
        log.Fatalf("Unknown action: %s", config.Action)
    }

    if err != nil {
        log.Fatalf("Operation failed: %v", err)
    }
}

func loadConfig() (*Config, error) {
    config := &Config{}
    v := reflect.ValueOf(config).Elem()

    for i := 0; i < v.NumField(); i++ {
        field := v.Type().Field(i)
        envVar := strings.ToUpper(field.Name)
        value := os.Getenv(envVar)
        v.Field(i).SetString(value)
    }

    // Generate random ID
    b := make([]byte, 16)
    if _, err := rand.Read(b); err != nil {
        return nil, fmt.Errorf("failed to generate random ID: %v", err)
    }
    config.ID = hex.EncodeToString(b)

    // Set default values and perform transformations
    if config.AppSubDomain == "" {
        config.AppSubDomain = fmt.Sprintf("%s-%s-%s", config.Swci, config.OpEnvironment, config.Suffix)
    }
    if config.ResourceQuotaCPU == "" {
        config.ResourceQuotaCPU = "4"
    }
    if config.ResourceQuotaMemoryGB == "" {
        config.ResourceQuotaMemoryGB = "8"
    }
    if config.ResourceQuotaStorageGB == "" {
        config.ResourceQuotaStorageGB = "0"
    }

    // Apply case transformations
    config.Action = strings.ToLower(config.Action)
    config.Swci = strings.ToLower(config.Swci)
    config.Suffix = strings.ToLower(config.Suffix)
    config.Region = strings.ToLower(config.Region)
    config.OpEnvironment = strings.ToLower(config.OpEnvironment)
    config.Sub = strings.ToLower(config.Sub)
    config.Rg = strings.ToLower(config.Rg)
    config.ClusterName = strings.ToLower(config.ClusterName)
    config.DataClassification = strings.ToLower(config.DataClassification)
    config.AppSubDomain = strings.ToLower(config.AppSubDomain)
    config.AllowAccessFromNS = strings.ToLower(config.AllowAccessFromNS)
    config.RequestedBy = strings.ToLower(config.RequestedBy)

    config.BillingReference = strings.ToUpper(config.BillingReference)
    config.Source = strings.ToUpper(config.Source)
    config.SwcID = strings.ToUpper(config.SwcID)

    return config, nil
}

func handleAddOrModify(config *Config) error {
    dir := filepath.Join(environmentDir, config.OpEnvironment, config.Region, config.ClusterName, 
                         fmt.Sprintf("%s-%s-%s", config.Swci, config.OpEnvironment, config.Suffix))

    if err := os.MkdirAll(dir, os.ModePerm); err != nil {
        return fmt.Errorf("failed to create directory %s: %v", dir, err)
    }

    files, err := filepath.Glob(filepath.Join(kustomizeDir, "*.yaml"))
    if err != nil {
        return fmt.Errorf("failed to glob files: %v", err)
    }

    for _, file := range files {
        if err := processFile(file, dir, config); err != nil {
            return err
        }
    }

    if !strings.HasPrefix(config.Suffix, "ob-test") {
        if err := os.Remove(filepath.Join(dir, "app.yaml")); err != nil && !os.IsNotExist(err) {
            return fmt.Errorf("failed to remove app.yaml: %v", err)
        }
        if err := os.Remove(filepath.Join(dir, "kustomization-apptest.yaml")); err != nil && !os.IsNotExist(err) {
            return fmt.Errorf("failed to remove kustomization-apptest.yaml: %v", err)
        }
    } else {
        if err := os.Rename(filepath.Join(dir, "kustomization-apptest.yaml"), filepath.Join(dir, "kustomization.yaml")); err != nil {
            return fmt.Errorf("failed to rename kustomization-apptest.yaml: %v", err)
        }
    }

    return nil
}

func handleRemove(config *Config) error {
    dir := filepath.Join(environmentDir, config.OpEnvironment, config.Region, config.ClusterName, 
                         fmt.Sprintf("%s-%s-%s", config.Swci, config.OpEnvironment, config.Suffix))

    deleteFile := filepath.Join(kustomizeDir, "kustomization-delete.yaml")
    if err := processFile(deleteFile, dir, config); err != nil {
        return err
    }

    if err := os.Rename(filepath.Join(dir, "kustomization-delete.yaml"), filepath.Join(dir, "kustomization.yaml")); err != nil {
        return fmt.Errorf("failed to rename kustomization-delete.yaml: %v", err)
    }

    files, err := filepath.Glob(filepath.Join(dir, "*.yaml"))
    if err != nil {
        return fmt.Errorf("failed to glob files: %v", err)
    }

    for _, file := range files {
        if filepath.Base(file) != "kustomization.yaml" {
            if err := os.Remove(file); err != nil {
                return fmt.Errorf("failed to remove file %s: %v", file, err)
            }
        }
    }

    return nil
}

func processFile(srcFile, destDir string, config *Config) error {
    content, err := ioutil.ReadFile(srcFile)
    if err != nil {
        return fmt.Errorf("failed to read file %s: %v", srcFile, err)
    }

    tmpl, err := template.New(filepath.Base(srcFile)).Parse(string(content))
    if err != nil {
        return fmt.Errorf("failed to parse template %s: %v", srcFile, err)
    }

    destFile := filepath.Join(destDir, filepath.Base(srcFile))
    file, err := os.Create(destFile)
    if err != nil {
        return fmt.Errorf("failed to create file %s: %v", destFile, err)
    }
    defer file.Close()

    if err := tmpl.Execute(file, config); err != nil {
        return fmt.Errorf("failed to execute template for %s: %v", destFile, err)
    }

    return nil
}