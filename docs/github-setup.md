# Connect Project 3 to GitHub

Run in a terminal, one block at a time. Keep authentication in GitHub's browser flow; do not paste tokens into chat or files.

```bash
cd ~/Projects/aws-enterprise-hybrid-migration
git status --short
git log -1 --oneline
git remote -v
gh auth login --hostname github.com --git-protocol https --web
gh api user --jq .login
```

The account must be `g-agor`. If it is another account, stop and select the correct login; do not remove existing authentication or modify global Git settings.

Check whether the remote repository already exists:

```bash
gh repo view g-agor/aws-enterprise-hybrid-migration --json nameWithOwner,isPrivate,url
```

If GitHub specifically reports that it does not exist (not a network or permission error), create a private repository and push the existing initial commit:

```bash
gh repo create g-agor/aws-enterprise-hybrid-migration --private --source=. --remote=origin --push
```

If it already exists, inspect it first. Only for the intended, empty repository, with no existing local origin:

```bash
git remote add origin https://github.com/g-agor/aws-enterprise-hybrid-migration.git
git ls-remote origin
git push -u origin main
```

If remote refs already exist, stop and compare histories before pushing. Never force-push or replace a remote to bypass an error.

Review the prepared changes before the second commit:

```bash
git diff --check
git diff --stat
git diff
```

Stage only reviewed project files; check `git diff --cached` for secrets before committing. The initial commit remains unchanged. After review:

```bash
git add README.md .gitignore docs/github-setup.md docs/terraform-workflow.md docs/adr/001-project-isolation.md terraform/bootstrap/main.tf terraform/environments/network/main.tf terraform/environments/network/backend.tf.example terraform/environments/development/README.md
git diff --cached --stat
git diff --cached
# Run only after reviewing the staged diff:
git commit -m "feat: add isolated Terraform foundation and project runbooks"
git push
```
