resource "aws_route53_record" "www" {
  zone_id = var.route53_zone_id
  name    = "aws_route53_zone_name"
  type    = "A"
  #  ttl     = 60
  #  records = [aws_instance.ec2_instance.public_ip]
  alias {
    evaluate_target_health = true
    name                   = aws_lb.lb.name
    zone_id                = aws_lb.lb.zone_id
  }
}