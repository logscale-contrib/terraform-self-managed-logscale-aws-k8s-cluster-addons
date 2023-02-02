


resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.23.0"
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

resource "kubectl_manifest" "karpenter_provisioner_general_amd64" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: general-amd64
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
          values: ["m"]
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
      weight: 100
      limits:
        resources:
          cpu: 1000
      providerRef:
        name: default
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
      labels:
          workloadClass: general
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_template
  ]
}
resource "kubectl_manifest" "karpenter_provisioner_general_arm64" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: general-arm64
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
          values: ["m"]
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - arm64
      limits:
        resources:
          cpu: 1000
      # weight: 1
      providerRef:
        name: default
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
      labels:
          workloadClass: general
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_template
  ]
}
resource "kubectl_manifest" "karpenter_provisioner_compute_amd64" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: compute-amd64
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
          values: ["c"]
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64          
      limits:
        resources:
          cpu: 1000
      weight: 51
      providerRef:
        name: default
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
      labels:
          workloadClass: compute      
      taints:
        - key: workloadClass
          value: compute
          effect: NoSchedule
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_template
  ]
}
resource "kubectl_manifest" "karpenter_provisioner_compute_arm64" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: compute-arm64
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
          values: ["c"]
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - arm64          
      limits:
        resources:
          cpu: 1000
      weight: 50
      providerRef:
        name: default
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
      labels:
          workloadClass: compute
      taints:
        - key: workloadClass
          value: compute
          effect: NoSchedule
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_template
  ]
}
resource "kubectl_manifest" "karpenter_provisioner_storage_amd64" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: storage-amd64
    spec:
      requirements:
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "karpenter.k8s.aws/instance-local-nvme"
          operator: Exists
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot","on-demand"]
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["i"]
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64          
      limits:
        resources:
          cpu: 1000
      weight: 61
      providerRef:
        name: default
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
      labels:
          workloadClass: nvme
      taints:
        - key: workloadClass
          value: nvme
          effect: NoSchedule
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_template
  ]
}
resource "kubectl_manifest" "karpenter_provisioner_storage_arm64" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: storage-arm64
    spec:
      requirements:
        - key: "karpenter.k8s.aws/instance-hypervisor"
          operator: In
          values: ["nitro"]
        - key: "karpenter.k8s.aws/instance-local-nvme"
          operator: Exists
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot","on-demand"]
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["i"]
        - key: kubernetes.io/os
          operator: In
          values:
          - linux
        - key: kubernetes.io/arch
          operator: In
          values:
          - arm64          
      limits:
        resources:
          cpu: 1000
      weight: 60
      providerRef:
        name: default
      consolidation:
        enabled: true
      ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
      labels:
          workloadClass: nvme
      taints:
        - key: workloadClass
          value: nvme
          effect: NoSchedule
  YAML

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_template
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
    helm_release.karpenter,
  ]
}
