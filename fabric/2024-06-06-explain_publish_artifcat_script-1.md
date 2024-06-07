---
generation_date: 2024-06-06 11:58
tags:  explain_publish_artifcat_script nexus
---
ONE SENTENCE SUMMARY:
A Bash script that packages and publishes artefacts to Nexus based on command line arguments and predefined conditions.

MAIN POINTS:
1. Script requires two positional parameters: folder location and a boolean for release artefact.
2. Checks for the presence of required positional parameters at the start.
3. Parses command line arguments for folder location, release flag, and Nexus credentials.
4. Validates the existence of the specified folder location.
5. Dynamically sets the artefact name based on the folder name.
6. Reads artefact version from a file and constructs artefact ID.
7. Creates a tar.gz artefact file, excluding specific files and directories for non-env folders.
8. Determines Nexus repository URL based on whether the artefact is a release or snapshot.
9. Uploads the artefact to Nexus using curl, with success or error logs.
10. Handles errors gracefully, including missing folder and failed tar or curl commands.

TAKEAWAYS:
1. The script supports both release and snapshot artefact publishing with conditional logic.
2. Artefact naming convention includes versioning and differentiation between config and infra types.
3. Exclusion rules in tar command prevent unnecessary files from being packaged into the artefact.
4. Script usage is clearly defined for users, with debug information for incorrect usage.
5. Error handling and logging are integral parts of the script's execution flow.