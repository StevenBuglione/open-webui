output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC identifier."
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "List of public subnet IDs."
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "List of private subnet IDs."
}

output "public_route_table_ids" {
  value       = [for rt in aws_route_table.public : rt.id]
  description = "Public route table IDs."
}

output "private_route_table_ids" {
  value       = [for rt in aws_route_table.private : rt.id]
  description = "Private route table IDs."
}

output "nat_gateway_ids" {
  value       = var.enable_nat_gateway ? [for nat in aws_nat_gateway.this : nat.id] : []
  description = "NAT gateway IDs."
}
