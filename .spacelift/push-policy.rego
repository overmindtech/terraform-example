package spacelift

# Push policy for Spacelift stack
# This policy ensures that Spacelift only runs for:
# 1. Direct pushes to the demo/spacelift branch
# 2. Pull requests targeting the demo/spacelift branch

# Track runs for direct pushes to demo/spacelift branch
track {
    input.push.branch == "demo/spacelift"
    affected
}

# Propose runs for PRs targeting demo/spacelift branch
propose {
    input.pull_request.base_ref == "demo/spacelift"
    affected_pr
}

# Ignore all other pushes and PRs
ignore {
    not track
    not propose
}

# Helper: Check if files in the push are within the project root
affected {
    filepath := input.push.affected_files[_]
    startswith(normalize_path(filepath), normalize_path(input.stack.project_root))
}

# Helper: Check if files in the PR diff are within the project root
affected_pr {
    filepath := input.pull_request.diff[_]
    startswith(normalize_path(filepath), normalize_path(input.stack.project_root))
}

# Helper function to normalize paths by removing leading slashes
normalize_path(path) = trim(path, "/")

