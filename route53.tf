data "aws_route53_zone" "junliang" {
  zone_id = var.route53_zone_id
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.junliang.zone_id
  name    = data.aws_route53_zone.junliang.name
  type    = "A"
  ttl     = 60
  records = [aws_instance.ec2_instance.public_ip]
}