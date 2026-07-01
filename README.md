# Static Site CI/CD — GitHub Actions → AWS (S3 + CloudFront)

A GitHub Actions workflow that builds, tests, and deploys a static site to a
private S3 bucket served through CloudFront. Deploys authenticate to AWS via
GitHub's OIDC identity token — no long-lived AWS access keys stored in
GitHub.

## Layout

```
site/                          demo static site (index.html, 404.html, style.css, script.js)
terraform/                     S3 bucket, CloudFront distribution, GitHub OIDC provider, IAM role
.github/workflows/deploy.yml   build -> test -> deploy workflow
```

## Workflow

| Job    | Runs on              | What it does                                                    |
|--------|-----------------------|-------------------------------------------------------------------|
| build  | every PR + push       | `html-validate` on `site/`, uploads `public/` as an artifact     |
| test   | every PR + push       | `linkinator` recursively checks all links in `public/` for 404s  |
| deploy | push to `main` only   | assumes AWS role via OIDC, `aws s3 sync`, invalidates CloudFront |

## 1. Provision AWS infrastructure

```bash
cd terraform
terraform init
terraform apply \
  -var="bucket_name=your-globally-unique-bucket-name" \
  -var="github_repository=Hardikrepo/ci-cd"
```

`github_repository` must match `owner/repo` exactly — the IAM trust policy
only allows `sts:AssumeRoleWithWebIdentity` from that repo on the `main`
branch (see `allowed_ref` to change).

Note the outputs:

```bash
terraform output
```

## 2. Configure GitHub repository variables

In your GitHub repo: **Settings → Secrets and variables → Actions →
Variables tab**, add (these are repo *variables*, not secrets — none of
these values are sensitive):

| Variable                     | Value                                       |
|-------------------------------|---------------------------------------------|
| `AWS_ROLE_ARN`                 | `deploy_role_arn` output                    |
| `AWS_REGION`                   | e.g. `us-east-1`                            |
| `S3_BUCKET`                    | `bucket_name` output                        |
| `CLOUDFRONT_DISTRIBUTION_ID`   | `cloudfront_distribution_id` output         |
| `CLOUDFRONT_DOMAIN_NAME`       | `cloudfront_domain_name` output (used for the environment URL link) |

No `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` needed — the `deploy` job
has `permissions: id-token: write`, and
`aws-actions/configure-aws-credentials` exchanges GitHub's OIDC token for
short-lived AWS credentials via `role-to-assume`.

## 3. Push

- Open a PR: `build` and `test` run.
- Merge to `main`: `build`, `test`, then `deploy` runs and publishes to
  `https://<cloudfront_domain_name>`.

## Local validation

```bash
npx html-validate "site/**/*.html"
mkdir -p public && cp -r site/* public/
npx linkinator public --recurse
```

## Notes

- The S3 bucket has all public access blocked; only the CloudFront
  distribution (via Origin Access Control) can read objects.
- `404.html` is wired as CloudFront's custom error response for 404s.
- Cache invalidation on every deploy (`/*`) is simplest for a low-traffic
  static site; for higher traffic, switch to versioned asset filenames plus
  a short-TTL invalidation of `index.html` only.
- The `deploy` job's `if:` restricts it to `push` events on `main` — it
  intentionally does not run on PRs, since the IAM trust policy also only
  trusts `refs/heads/main`.
