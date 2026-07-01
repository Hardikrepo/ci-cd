# Static Site CI/CD — GitLab → AWS (S3 + CloudFront)

A GitLab CI pipeline that builds, tests, and deploys a static site to a
private S3 bucket served through CloudFront. Deploys authenticate to AWS via
GitLab's OIDC identity token — no long-lived AWS access keys stored in
GitLab.

## Layout

```
site/           demo static site (index.html, 404.html, style.css, script.js)
terraform/      S3 bucket, CloudFront distribution, GitLab OIDC provider, IAM role
.gitlab-ci.yml  build -> test -> deploy pipeline
```

## Pipeline

| Stage  | Runs on           | What it does                                                      |
|--------|--------------------|---------------------------------------------------------------------|
| build  | every MR + main    | `html-validate` on `site/`, copies files into `public/` artifact   |
| test   | every MR + main    | `linkinator` recursively checks all links in `public/` for 404s    |
| deploy | push to `main` only | assumes AWS role via OIDC, `aws s3 sync`, invalidates CloudFront   |

## 1. Provision AWS infrastructure

```bash
cd terraform
terraform init
terraform apply \
  -var="bucket_name=your-globally-unique-bucket-name" \
  -var="gitlab_project_path=your-group/your-project"
```

`gitlab_project_path` must match your GitLab namespace/project exactly — the
IAM trust policy only allows `sts:AssumeRoleWithWebIdentity` from that
project on the `main` branch (see `allowed_ref` to change).

If you're on self-managed GitLab, also pass
`-var="gitlab_oidc_url=https://gitlab.yourcompany.com"` and update `aud` in
`.gitlab-ci.yml`'s `id_tokens` block to match.

Note the outputs:

```bash
terraform output
```

## 2. Configure GitLab CI/CD variables

In your GitLab project: **Settings → CI/CD → Variables**, add (as plain,
non-masked variables — none of these are secret):

| Variable                     | Value                                       |
|-------------------------------|---------------------------------------------|
| `AWS_ROLE_ARN`                 | `deploy_role_arn` output                    |
| `S3_BUCKET`                    | `bucket_name` output                        |
| `CLOUDFRONT_DISTRIBUTION_ID`   | `cloudfront_distribution_id` output         |
| `CLOUDFRONT_DOMAIN_NAME`       | `cloudfront_domain_name` output (optional, only used for the environment URL link) |

No `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` needed — the `deploy` job
requests a short-lived GitLab OIDC token, writes it to a file, and the AWS
CLI automatically exchanges it for temporary credentials via
`AWS_ROLE_ARN` + `AWS_WEB_IDENTITY_TOKEN_FILE`.

## 3. Push

- Open an MR: `build` and `test` run.
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
