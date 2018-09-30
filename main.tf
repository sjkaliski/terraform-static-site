provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "www" {
  bucket = "www.${var.domain}"

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "www" {
  bucket = "${aws_s3_bucket.www.id}"
  policy = "${data.aws_iam_policy_document.www.json}"
}

data "aws_iam_policy_document" "www" {
  statement = {
    sid = "PublicRead"

    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_s3_bucket.www.arn}/*",
    ]
  }
}

resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = "${aws_s3_bucket.www.website_endpoint}"
    origin_id   = "www.${var.domain}"
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "www.${var.domain}"
    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 31536000

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }
  aliases = ["www.${var.domain}"]
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = "${var.certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "www" {
  zone_id = "${var.zone_id}"
  name    = "www.${var.domain}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.www_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.www_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket" "root" {
  bucket = "${var.domain}"

  website {
    redirect_all_requests_to = "https://www.${var.domain}"
  }
}

resource "aws_s3_bucket_policy" "root" {
  bucket = "${aws_s3_bucket.root.id}"
  policy = "${data.aws_iam_policy_document.root.json}"
}

data "aws_iam_policy_document" "root" {
  statement = {
    sid = "PublicRead"

    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_s3_bucket.root.arn}/*",
    ]
  }
}

resource "aws_cloudfront_distribution" "root_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = "${aws_s3_bucket.root.website_endpoint}"
    origin_id   = "${var.domain}"
  }

  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.domain}"
    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 31536000

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }
  aliases = ["${var.domain}"]
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = "${var.certificate_arn}"
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_route53_record" "root" {
  zone_id = "${var.zone_id}"

  name = ""
  type = "A"

  alias = {
    name                   = "${aws_cloudfront_distribution.root_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.root_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}
