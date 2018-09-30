# terraform-static-site

Deploy a Static Site served over HTTPS via AWS S3 and CloudFront.

## Usage

```hcl
module "s3site" {
  source = "github.com/sjkaliski/terraform-static-site"

  region          = "us-east-1"
  domain          = "mysite.com"
  zone_id         = "route53_zone_id"
  certificate_arn = "cert_arn"
}
```

## Notes

- This module currently assumes that the site is to be accessible via `www.*.*`.
