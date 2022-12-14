


resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.20.0"
  timeout    = 600
  values = [<<YAML
tolerations:
  - key: CriticalAddonsOnly
    operator: Exists
  - key: "eks.amazonaws.com/compute-type"
    operator: "Equal"
    value: "fargate"
YAML
  ]

  set {
    name  = "settings.aws.clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = var.eks_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.karpenter_irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = var.karpenter_instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = var.karpenter_queue_name
  }
}

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "karpenter.k8s.aws/instance-local-nvme"
          operator: DoesNotExist
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot","on-demand"]
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["c", "m", "r"]
      limits:
        resources:
          cpu: 1000
      providerRef:
        name: default
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;

  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${var.eks_cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${var.eks_cluster_name}
      tags:
        karpenter.sh/discovery: ${var.eks_cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}
