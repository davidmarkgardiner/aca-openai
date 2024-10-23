func processFile(srcFile, destDir, destFileName string, config *Config) error {
	log.Printf("Processing file %s as %s", srcFile, destFileName)

	// Read the source file
	content, err := os.ReadFile(srcFile)
	if err != nil {
		return fmt.Errorf("failed to read file %s: %v", srcFile, err)
	}

	// Get namespace parts for swci and environment values
	nameParts := strings.Split(config.NamespaceName, "-")
	if len(nameParts) < 3 {
		return fmt.Errorf("invalid namespace format: %s", config.NamespaceName)
	}

	// Replace placeholders in the content
	replacedContent := string(content)

	// First replace swci and openvironment from namespace parts
	swci := nameParts[0]
	environment := nameParts[1]
	if environment == "test" {
		environment = "dev"
	}

	replacedContent = strings.ReplaceAll(replacedContent, "${swci}", swci)
	replacedContent = strings.ReplaceAll(replacedContent, "${openvironment}", environment)

	// Then handle the rest of the config fields
	v := reflect.ValueOf(*config)
	t := v.Type()

	for i := 0; i < v.NumField(); i++ {
		fieldName := t.Field(i).Name
		fieldValue := v.Field(i).String()
		placeholder := "${" + strings.ToLower(fieldName) + "}"
		replacedContent = strings.ReplaceAll(replacedContent, placeholder, fieldValue)
	}

	// Create the destination file
	destFile := filepath.Join(destDir, destFileName)
	if err := os.WriteFile(destFile, []byte(replacedContent), 0644); err != nil {
		return fmt.Errorf("failed to write file %s: %v", destFile, err)
	}

	log.Printf("Successfully processed and wrote file: %s", destFile)
	return nil
}
