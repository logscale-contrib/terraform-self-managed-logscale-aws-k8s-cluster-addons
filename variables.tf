variable "uniqueName" {
  type        = string
  description = "(optional) describe your variable"
}
variable "eks_cluster_name" {
  type        = string
  description = "(optional) describe your variable"
}
variable "eks_endpoint" {
  type        = string
  description = "(optional) describe your variable"
}
variable "eks_cluster_certificate_authority_data" {
  type = string
  description = "(optional) describe your variable"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "(optional) describe your variable"
}

variable "cluster_version" {
  type = string
  description = "(optional) describe your variable"
}

variable "karpenter_queue_name" {
  type = string
  description = "(optional) describe your variable"
}
variable "karpenter_instance_profile_name" {
  type = string
  description = "(optional) describe your variable"
}
variable "karpenter_irsa_arn" {
  type = string
  description = "(optional) describe your variable"
}
variable "vpc_id" {
  type = string
  description = "(optional) describe your variable"
}
variable "region" {
  type = string
  description = "(optional) describe your variable"
}