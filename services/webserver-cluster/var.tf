

variable "cluster_name" {
    description = "The name to use for all the cluster resources"
    type = string
}

variable "db_remote_state_bucket" {
    description = "the name of the s3 bucket for the database remote state"
    type = string
}

variable "db_remote_state_key" {
    description = "the path for the datases's remote state in s3"
    type = string
}

variable "instance_type" {
    description = "the instance type to use in the launch config of the load balancer"
    type = string
}

variable "min_size" {
    description = "min size of the ASG"
    type = number
}

variable "max_size" {
    description = "max size of the ASG"
    type = number
}

variable "asg_custom_tags" {
    type = map(string)
    description = "custom tags to add to the ASG"
    default = {}
}

variable "webserver_ami" {
    description = "the ami id to use to create the webserver instance"
    type = string
}