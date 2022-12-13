

module "cert_manager_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.uniqueName}_cert-manager_cw-aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cw-cert-manager"]
    }
  }


}

resource "helm_release" "cert-manager" {
  depends_on = [
    helm_release.promcrds
  ]
  namespace        = "cert-manager"
  create_namespace = true

  name       = "cw"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.9.*"


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
    
installCRDs: true

replicaCount: 2
webhook:
  replicaCount: 2
cainjector:
  replicaCount: 2
serviceAccount:
  create: true
  name: cw-cert-manager
  annotations:
    eks.amazonaws.com/role-arn: ${module.cert_manager_irsa.iam_role_arn}

admissionWebhooks:
  certManager:
    enabled: true

prometheus:
  enabled: true
  servicemonitor:
    enabled: true

webhook:
    securePort: 8443
EOF 
  ]

}
