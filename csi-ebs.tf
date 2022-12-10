module "irsa_csi_ebs" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.uniqueName}_kube-system_ebs-csi-controller-sa"


  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}


module "release_csi_ebs" {
  source  = "terraform-module/release/helm"
  version = "2.8.0"

  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"


  app = {
    name             = "ebs-csi"
    version          = "2.10.*"
    chart            = "aws-ebs-csi-driver"
    create_namespace = false
    wait             = true
    deploy           = 1
  }

  values = [<<EOF
controller:
    topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
storageClasses: 
- name: ebs-gp3-enc
  volumeBindingMode: WaitForFirstConsumer
  reclaimPolicy: Delete
  parameters:
    encrypted: "true"
    type: gp3
    csi.storage.k8s.io/fstype: "ext4" 
    allowautoiopspergbincrease: "true"
- name: ebs-gp3-noenc
  volumeBindingMode: WaitForFirstConsumer
  reclaimPolicy: Delete
  parameters:
    encrypted: "false"
    type: gp3
    csi.storage.k8s.io/fstype: "ext4" 
    allowautoiopspergbincrease: "true"
node:
    tolerations:
    - key: CriticalAddonsOnly
      operator: Exists    
    #Any tolerations used to control pod deployment should be here
    #- operator: "Exists"
EOF 
  ]
  set = [
    {
      "name"  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      "value" = module.irsa_csi_ebs.iam_role_arn
    }
  ]
}



