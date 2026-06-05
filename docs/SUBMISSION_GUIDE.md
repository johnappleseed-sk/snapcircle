# SnapCircle GitHub Submission Guide

## Check Git Status

```bash
git status
```

Review changed files before committing:

```bash
git diff
```

## Commit Changes

```bash
git add .
git commit -m "Describe the completed work"
```

Use clear commit messages, for example:

```bash
git commit -m "Prepare assignment submission documentation"
```

## Push to GitHub

```bash
git push origin main
```

## Verify GitHub Repository

After pushing:

1. Open the GitHub repository.
2. Confirm the latest commit is visible.
3. Confirm `backend/`, `frontend/`, `docs/`, and `README.md` are present.
4. Confirm documentation files render correctly.

## Files That Should Not Be Committed

- `.env`
- `backend/.env`
- `backend/vendor/`
- `frontend/build/`
- `frontend/.dart_tool/`
- `node_modules/`
- IDE temporary files
- OS temporary files

## Final Submission Checklist

- [ ] Backend tests pass
- [ ] Frontend analyze passes
- [ ] README is complete
- [ ] API documentation is complete
- [ ] Setup guide is complete
- [ ] Testing checklist is complete
- [ ] Screenshots are added
- [ ] Code is pushed to GitHub
- [ ] No secrets are committed
