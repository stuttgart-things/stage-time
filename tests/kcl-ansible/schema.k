schema PipelineOverrides:
    """
    Schema for pipeline parameter overrides
    """
    ansibleWorkingImage?: str
    gitRepoUrl?: str
    gitRevision?: str
    inventory?: str
    ansibleExtraRoles?: [str]

    check:
        # Validate image format - use boolean OR
        ansibleWorkingImage.startswith("ghcr.io/") or \
        ansibleWorkingImage.startswith("docker.io/") or \
        ansibleWorkingImage.startswith("quay.io/") \
        if ansibleWorkingImage, "ansibleWorkingImage must be from ghcr.io, docker.io, or quay.io"

        # Validate git URL format
        gitRepoUrl.startswith("https://github.com/") if gitRepoUrl, "gitRepoUrl must be a valid GitHub HTTPS URL"

        # Validate revision is not empty
        len(gitRevision) > 0 if gitRevision, "gitRevision cannot be empty"

        # Validate inventory is base64 (basic check)
        len(inventory) > 0 if inventory, "inventory cannot be empty"

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