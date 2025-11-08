variable "vpc_cidr" {
  # default = "10.0.12.0/16"
  type = string

}


variable "project_name" {
  type=string
}

variable "environment" {
  type = string
}


variable "vpc_tags" {
  type = map
  # default = {}
}


variable "igw_tags" {
  default = {
    # Name = "IGW created by terraform"
  }
}


variable "public_sub_cidrs" {
  type = list
}

variable "pub_sub_tags" {
  type = map
  default = {}
}



variable "private_sub_cidrs" {
  type = list
}

variable "priv_sub_tags" {
  type=map
  default = {}
}


variable "database_sub_cidrs" {
  type = list
}

variable "database_sub_tags" {
  type=map
  default = {}
}


variable "public_route_table_tags" {
  default = {}
}

variable "private_route_table_tags" {
  default = {}
}

variable "database_route_table_tags" {
  default = {}
}

variable "eip_tags" {
  type = map
  default = {}
}

variable "natgw_tags" {
  type = map
  default = {}
}

variable "is_peering_required" {
  type=bool
  # default = true
}

variable "peering_tags" {
  type=map
  default = {}
}


#info
##ikada ee file lo variable optional ivvakunte main.tf file lo variable pakka define cheyali
#ikada defalut - variable value ichesthe, main.tf lo define cheyakapoyna it worked.


#using module
#here manam module variables - ante akada mandatory ani mention chesinavani anni ikada main.tf file or define chesi undali
#or else as i said above varibles.tf lo default value ichesi ah variable ki , main.tf lo define cheyakapoyna ok

