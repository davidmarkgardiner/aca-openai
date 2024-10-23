	// Check if namespace contains "test" and replace with "dev"
	if strings.Contains(config.NamespaceName, "-test-") {
		config.NamespaceName = strings.Replace(config.NamespaceName, "-test-", "-dev-", 1)
		log.Printf("Modified namespace to: %s", config.NamespaceName)
	}

	// Construct the target directory path
	dir := filepath.Join(environmentDir, config.OpEnvironment, config.Region, config.ClusterName, config.NamespaceName)
	log.Printf("Target directory: %s", dir)
