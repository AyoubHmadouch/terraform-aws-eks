variable "cluster_name" {
  description = "(Optional) EKS Cluster Name"
  type        = string
  default     = "default"
}

variable "cluster_version" {
  description = "(Optional) EKS Cluster Version"
  type        = string
  default     = "1.31"
}

variable "subnet_ids" {
  description = "(Required) List of subnet IDs where control plane will deploy ENIs"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "(Optional) Enable private access to the EKS control plane"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "(Optional) Enable public access to the EKS control plane"
  type        = bool
  default     = true
}

variable "access_entries" {
  description = "(Optional) Map of EKS access entries and policy associations"
  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string))
    type              = optional(string, "STANDARD")
    user_name         = optional(string)
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string))
      })
    })), {})
  }))
  default = {}
}

variable "managed_node_group" {
  description = "(Optional) Configuration of the EKS Node Group"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    max_size       = number
    min_size       = number
  }))
  default = {}
}

variable "eks_addons" {
  description = "(Optional) Map of EKS addons to install"
  type = map(object({
    addon_version = string
  }))
  default = {}
}

variable "fargate_profile" {
  description = "(Optional) Map of Fargate profiles to create"
  type = map(object({
    namespace = string
    labels    = optional(map(string), {})
  }))
  default = {}
}
