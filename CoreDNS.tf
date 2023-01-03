
################################################################################
# Modify EKS CoreDNS Deployment
################################################################################

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}



# # Separate resource so that this is only ever executed once
# resource "null_resource" "remove_default_coredns_deployment" {
#   triggers = {}

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]

#     # We are removing the deployment provided by the EKS service and replacing it through the self-managed CoreDNS Helm addon
#     # However, we are maintaing the existing kube-dns service and annotating it for Helm to assume control
#     command = <<-EOT
#       kubectl --namespace kube-system delete deployment coredns
#     EOT
#   }
# }

# resource "null_resource" "modify_kube_dns" {
#   triggers = {}

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     # We are maintaing the existing kube-dns service and annotating it for Helm to assume control
#     command = <<-EOT
#       kubectl --namespace kube-system annotate --overwrite service kube-dns meta.helm.sh/release-name=coredns
#       kubectl --namespace kube-system annotate --overwrite service kube-dns meta.helm.sh/release-namespace=kube-system
#       kubectl --namespace kube-system label --overwrite service kube-dns app.kubernetes.io/managed-by=Helm
#     EOT
#   }

#   depends_on = [
#     null_resource.remove_default_coredns_deployment
#   ]
# }

# ################################################################################
# # CoreDNS Helm Chart (self-managed)
# ################################################################################

# data "aws_eks_addon_version" "this" {
#   for_each = toset(["coredns"])

#   addon_name         = each.value
#   kubernetes_version = var.cluster_version
#   most_recent        = true
# }

# resource "helm_release" "coredns" {
#   name             = "coredns"
#   namespace        = "kube-system"
#   create_namespace = false
#   description      = "CoreDNS is a DNS server that chains plugins and provides Kubernetes DNS Services"
#   chart            = "coredns"
#   version          = "1.19.4"
#   repository       = "https://coredns.github.io/helm"

#   # For EKS image repositories https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
#   values = [
#     <<-EOT
#       replicaCount: 2
#       image:
#         repository: 602401143452.dkr.ecr.eu-west-1.amazonaws.com/eks/coredns
#         tag: ${data.aws_eks_addon_version.this["coredns"].version}
#       deployment:
#         name: coredns
#         annotations:
#           eks.amazonaws.com/compute-type: fargate
#       service:
#         name: kube-dns
#         annotations:
#           eks.amazonaws.com/compute-type: fargate
#       podAnnotations:
#         eks.amazonaws.com/compute-type: fargate
#       EOT
#   ]

#   depends_on = [
#     # Need to ensure the CoreDNS updates are peformed before provisioning
#     null_resource.modify_kube_dns
#   ]
# }
