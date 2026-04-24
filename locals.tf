locals {
  common_tags = {
    ManagedBy = "Terraform"
    Module    = "eks"
  }

  access_policy_associations = {
    for association in flatten([
      for entry_key, entry in var.access_entries : [
        for policy_key, policy_association in entry.policy_associations : {
          key           = "${entry_key}-${policy_key}"
          principal_arn = entry.principal_arn
          policy_arn    = policy_association.policy_arn
          access_scope  = policy_association.access_scope
        }
      ]
    ]) : association.key => association
  }
}
