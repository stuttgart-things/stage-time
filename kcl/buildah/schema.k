schema PipelineOverrides:
    """
    Schema for pipeline parameter overrides
    """
    gitUrl?: str
    branchName?: str
    verifySsl?: str
    imageName?: str
    context?: str

    check:
        # Validate git URL format
        gitUrl.startswith("https://github.com/") if gitUrl, "gitUrl must be a valid GitHub HTTPS URL"

        # Validate branch is not empty
        len(branchName) > 0 if branchName, "branchName cannot be empty"

        # Validate SSL verification is boolean string - be more lenient
        verifySsl in ["true", "false", "True", "False", "TRUE", "FALSE"] if verifySsl, "verifySsl must be 'true' or 'false'"

        # Validate image name is not empty
        len(imageName) > 0 if imageName, "imageName cannot be empty"

        # Validate context is not empty
        len(context) > 0 if context, "context cannot be empty"

schema StorageConfig:
    """
    Schema for storage configuration
    """
    storageClass?: str
    storageSize?: str
    storageAccessModes?: str

    check:
        # Validate storage size format (e.g., "20Mi", "1Gi")
        storageSize.endswith("Mi") or storageSize.endswith("Gi") \
        if storageSize, "storageSize must end with 'Mi' or 'Gi'"

        # Validate access modes
        storageAccessModes in ["ReadWriteOnce", "ReadWriteMany", "ReadOnlyMany"] \
        if storageAccessModes, "Invalid storage access mode"

schema GitConfig:
    """
    Schema for Git pipeline reference configuration
    """
    url?: str
    revision?: str
    pathInRepo?: str

    check:
        url.startswith("https://") if url, "Git URL must use HTTPS"
        len(revision) > 0 if revision, "Git revision cannot be empty"
