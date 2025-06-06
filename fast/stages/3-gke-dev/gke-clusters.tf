/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# tfdoc:file:description GKE clusters.

locals {
  nodepools = merge([
    for cluster, nodepools in var.nodepools : {
      for nodepool, config in nodepools :
      "${cluster}/${nodepool}" => merge(config, {
        name    = nodepool
        cluster = cluster
      })
    }
  ]...)
  subnet_self_links = try(
    var.subnet_self_links[var.vpc_config.vpc_self_link], {}
  )
  vpc_self_link = lookup(
    var.vpc_self_links,
    var.vpc_config.vpc_self_link,
    var.vpc_config.vpc_self_link
  )
}

module "gke-cluster" {
  source                   = "../../../modules/gke-cluster-standard"
  for_each                 = var.clusters
  name                     = each.key
  project_id               = module.gke-project-0.project_id
  access_config            = each.value.access_config
  cluster_autoscaling      = each.value.cluster_autoscaling
  description              = each.value.description
  enable_features          = each.value.enable_features
  enable_addons            = each.value.enable_addons
  issue_client_certificate = each.value.issue_client_certificate
  labels                   = each.value.labels
  location                 = each.value.location
  logging_config           = each.value.logging_config
  maintenance_config       = each.value.maintenance_config
  max_pods_per_node        = each.value.max_pods_per_node
  min_master_version       = each.value.min_master_version
  monitoring_config        = each.value.monitoring_config
  node_locations           = each.value.node_locations
  release_channel          = each.value.release_channel
  vpc_config = merge(each.value.vpc_config, {
    network = try(
      var.vpc_self_links[each.value.vpc_config.network],
      each.value.vpc_config.network,
      local.vpc_self_link
    )
    subnetwork = try(
      local.subnet_self_links[each.value.vpc_config.subnetwork],
      each.value.vpc_config.subnetwork,
      null
    )
  })
  deletion_protection = var.deletion_protection
}

module "gke-nodepool" {
  source               = "../../../modules/gke-nodepool"
  for_each             = local.nodepools
  name                 = each.value.name
  project_id           = module.gke-project-0.project_id
  cluster_name         = module.gke-cluster[each.value.cluster].name
  location             = module.gke-cluster[each.value.cluster].location
  gke_version          = each.value.gke_version
  k8s_labels           = each.value.k8s_labels
  max_pods_per_node    = each.value.max_pods_per_node
  node_config          = each.value.node_config
  node_count           = each.value.node_count
  node_locations       = each.value.node_locations
  nodepool_config      = each.value.nodepool_config
  network_config       = each.value.network_config
  reservation_affinity = each.value.reservation_affinity
  service_account = (
    each.value.service_account == null
    ? { email = module.gke-nodes-service-account.email }
    : each.value.service_account
  )
  sole_tenant_nodegroup = each.value.sole_tenant_nodegroup
  tags                  = each.value.tags
  taints                = each.value.taints
}
