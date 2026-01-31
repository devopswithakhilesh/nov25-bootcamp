# data soiurce to pull dns public zones

# create one route -> ALB



# certificat manage request


# create one acm certs cname records in domain


# validation (dns type)

# either create a public hosted zone/ or import one
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}


# create a dns record
# subdomain -> load balancer dns name

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}



# request ssl cert from crtificat manager
resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.subdomain}.${var.domain_name}"
  validation_method = "DNS"
}
# class11.livingdevops.com
# class12.livingdevops.com
# *.livingdevops.com




# create a dns record for validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}
# validate the certificate

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}