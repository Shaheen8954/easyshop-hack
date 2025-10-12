module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "5.18.1" # Using a version that is compatible with AWS provider 5.x

    # Local variables are into provider.tfstate

    name              = local.name
    cidr              = local.vpc_cidr
    azs               = local.azs
    private_subnets   = local.private_subnets
    public_subnets    = local.public_subnets
    intra_subnets     = local.intra_subnets

    enable_nat_gateway      = true
    single_nat_gateway      = true
    one_nat_gateway_per_az  = false

    public_subnet_tags       = {
        "kubernetes.io/role/elb" = 1
    }

    private_subnet_tags   = {
        "kubernetes.io/role/internal-elb" = 1
    }

    # ensure public subnet auto-assign public instance_type

    map_public_ip_on_launch = true
}
