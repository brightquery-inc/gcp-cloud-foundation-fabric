/**
 * Copyright 2025 Google LLC
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

# tfdoc:file:description Workforce Identity Federation provider definitions.

locals {
  workforce_identity_providers = {
    for k, v in var.workforce_identity_providers : k => merge(
      v,
      lookup(local.workforce_identity_providers_defs, v.issuer, {})
    )
  }
}

resource "google_iam_workforce_pool" "default" {
  count    = length(local.workforce_identity_providers) > 0 ? 1 : 0
  parent   = "organizations/${var.organization.id}"
  location = "global"
  workforce_pool_id = templatestring(
    var.resource_names["wf-bootstrap"], { prefix = var.prefix }
  )
}

resource "google_iam_workforce_pool_provider" "default" {
  for_each            = local.workforce_identity_providers
  attribute_condition = each.value.attribute_condition
  attribute_mapping   = each.value.attribute_mapping
  description         = each.value.description
  disabled            = each.value.disabled
  display_name        = each.value.display_name
  location            = google_iam_workforce_pool.default[0].location
  provider_id = templatestring(var.resource_names["wf-provider_template"], {
    prefix = var.prefix
    key    = each.key
  })
  workforce_pool_id = google_iam_workforce_pool.default[0].workforce_pool_id
  saml {
    idp_metadata_xml = each.value.saml.idp_metadata_xml
  }
}
