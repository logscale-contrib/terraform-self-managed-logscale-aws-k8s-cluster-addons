data "aws_route53_zone" "selected" {
  zone_id = var.zone_id
}


module "irsa_edns" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.uniqueName}_external-dns_external-dns"


  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.selected.arn]

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }
}


module "release_edns" {
  depends_on = [
    kubectl_manifest.karpenter_provisioner_general_amd64,
    kubectl_manifest.karpenter_provisioner_general_arm64
  ]  
  source  = "terraform-module/release/helm"
  version = "2.8.0"

  namespace  = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"


  app = {
    name             = "cw"
    version          = "6.5.*"
    chart            = "external-dns"
    create_namespace = true
    wait             = true
    deploy           = 1
  }

  values = [<<EOF
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
tolerations:
  - key: CriticalAddonsOnly
    operator: Exists
  - key: "eks.amazonaws.com/compute-type"
    operator: "Equal"
    value: "fargate"
    
replicaCount: 2
serviceAccount:
  name: external-dns
txtOwnerId: "${var.uniqueName}"

EOF 
  ]
  set = [
    {
      "name"  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      "value" = module.irsa_edns.iam_role_arn
    }
  ]
}



