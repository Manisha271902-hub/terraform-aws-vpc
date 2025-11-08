output "my_vpc_id" {
  value = aws_vpc.main
}

# output "azs"{
#     value = data.aws_availability_zones.available
# }


output "default_output" {
  value = data.aws_vpc.default_id.id
}


output "public_subnet_ids"{
  value = aws_subnet.public_subs[*].id
}

# output "private_subnet_ids"{
#   value = aws_subnet.private_subs.id
# }


# output "database_subnet_ids"{
#   value = aws_subnet.database_subs.id
# }


#outputs ikad nundi pampistadi, manam module use chesteapud receive cheskovali