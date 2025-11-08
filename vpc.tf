resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  

  tags = merge(
    var.vpc_tags,
    local.common_tags,
    {
      Name= local.common_name_suffix
    }
  )

  enable_dns_hostnames = true
}


###########################################################################################################
#create IGW

resource "aws_internet_gateway" "vpcmod" {
  vpc_id = aws_vpc.main.id

 tags = merge(
    var.igw_tags,
    local.common_tags,
    {
      Name= local.common_name_suffix
    }
  )
}

###########################################################################################################
#subnet creation 

resource "aws_subnet" "public_subs" {
  count=length(var.public_sub_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_sub_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.pub_sub_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-public-${local.az_names[count.index]}"
    }
  )

}
###########################################################################################################
# #subnet creation private

resource "aws_subnet" "private_subs" {
  count=length(var.private_sub_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_sub_cidrs[count.index]
  availability_zone =local.az_names[count.index]
 tags = merge(
    var.priv_sub_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-private-${local.az_names[count.index]}"
    }
  )
}

###########################################################################################################
#database subnets

resource "aws_subnet" "database_subs" {
  count=length(var.database_sub_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_sub_cidrs[count.index]
  availability_zone = local.az_names[count.index]
 tags = merge(
    var.database_sub_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-database-${local.az_names[count.index]}"
    }
  )
}




#create route tables

###########################################################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.public_route_table_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-public"
    }
  )
}
###########################################################################################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.public_route_table_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-private"
    }
  )
}
###########################################################################################################
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.private_route_table_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-database"
    }
  )
}

###########################################################################################################
#add routes


resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.vpcmod.id
  
}


###########################################################################################################
#create elastic ip
resource "aws_eip" "nat" {
  domain = "vpc"

  # instance                  = aws_instance.foo.id
  # associate_with_private_ip = "10.0.0.12"
  # depends_on                = [aws_internet_gateway.gw]

  tags = merge(
    var.eip_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-nat"
    }
  )
}

###########################################################################################################
#create nat gateway

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subs[0].id #terraform nat gateways must be created in excatly one subnet

  tags =  merge(
    var.natgw_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-nat"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.vpcmod]   #batwork avvadaniki internet gateway avasaram, create avasaraniki avsaram
                                              #le , but work avvadaniki run time lo dependency undhi
                                              #tf only creation time dpeendenices matrame resolve chestadi, run time kaadh
                                              #so adhi entante internet gateway create ayi undhi pakka ga ani ensure chestadi
}


###########################################################################################################
resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
  # vpc_peering_connection_id = "pcx-45ff3dc1"
}

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}


###########################################################################################################
#associate subnets to these route tables

resource "aws_route_table_association" "public" {
  count = length(var.public_sub_cidrs)
  subnet_id      = aws_subnet.public_subs[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_sub_cidrs)
  subnet_id      = aws_subnet.private_subs[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_sub_cidrs)
  subnet_id      = aws_subnet.database_subs[count.index].id
  route_table_id = aws_route_table.database.id
}

###########################################################################################################

#create peering connection


resource "aws_vpc_peering_connection" "default" {
  
  count= var.is_peering_required ? 1:0
  #peer oenwe id required if anotehr account, default mana account
  peer_vpc_id   = data.aws_vpc.default_id.id
  vpc_id        = aws_vpc.main.id
  
  auto_accept = true  #same account kabatti

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }


  tags =  merge(
    var.peering_tags,
    local.common_tags,
    {
      Name= "${local.common_name_suffix}-default"
    }
  )
}



resource "aws_route" "public_peering" {
  count= var.is_peering_required ? 1:0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default_id.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}


resource "aws_route" "default_peering" {
  count= var.is_peering_required ? 1:0
  # route_table_id            = aws_route_table.main_route_table_id 
  route_table_id            = data.aws_route_table.default.id
  destination_cidr_block    = aws_vpc.main.cidr_block  
  # destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}