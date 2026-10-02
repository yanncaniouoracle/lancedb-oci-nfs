resource "oci_queue_queue" "lancedb_events" {
  count                 = var.enable_lancedb_dataplane ? 1 : 0
  compartment_id        = var.compartment_ocid
  display_name          = "${local.cluster_name}-lancedb-events"
  retention_in_seconds  = 345600
  visibility_in_seconds = 120
  timeout_in_seconds    = 30
}

resource "oci_functions_application" "lancedb_event_router" {
  count          = var.enable_lancedb_dataplane ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${local.cluster_name}-lancedb-event-router"
  subnet_ids     = [local.storage_subnet_id]
}

resource "oci_functions_function" "lancedb_event_router" {
  count              = var.enable_lancedb_dataplane ? 1 : 0
  application_id     = oci_functions_application.lancedb_event_router[0].id
  display_name       = "${local.cluster_name}-lancedb-event-router"
  memory_in_mbs      = var.lancedb_function_memory_mbs
  timeout_in_seconds = 30
  image              = var.lancedb_ingestion_function_image
  config = {
    QUEUE_ENDPOINT = oci_queue_queue.lancedb_events[0].messages_endpoint
    QUEUE_ID       = oci_queue_queue.lancedb_events[0].id
  }
  lifecycle {
    precondition {
      condition     = trimspace(var.lancedb_ingestion_function_image) != ""
      error_message = "lancedb_ingestion_function_image is required when enable_lancedb_dataplane is true."
    }
  }
}

resource "oci_events_rule" "lancedb_object_changes" {
  count          = var.enable_lancedb_dataplane ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${local.cluster_name}-lancedb-object-changes"
  description    = "Object Storage changes routed to the HA-NFS LanceDB table."
  is_enabled     = true
  condition_details {
    event_types = ["com.oraclecloud.objectstorage.createobject", "com.oraclecloud.objectstorage.updateobject", "com.oraclecloud.objectstorage.deleteobject"]
    data        = jsonencode({})
  }
  actions {
    action {
      action_type = "FAAS"
      is_enabled  = true
      function_id = oci_functions_function.lancedb_event_router[0].id
    }
  }
}

resource "oci_identity_policy" "lancedb_function_queue_push" {
  count          = var.enable_lancedb_dataplane && var.create_lancedb_function_queue_policy ? 1 : 0
  compartment_id = var.compartment_ocid
  name           = "${local.cluster_name}-lancedb-function-queue-push"
  description    = "Allow only the event-router Function to publish to its Queue."
  statements     = ["Allow any-user to use queue-push in compartment id ${var.compartment_ocid} where all {request.principal.type = 'fnfunc', target.queue.id = '${oci_queue_queue.lancedb_events[0].id}'}"]
}

resource "oci_identity_policy" "lancedb_storage_access" {
  count          = var.enable_lancedb_dataplane && var.create_lancedb_instance_policy ? 1 : 0
  compartment_id = var.compartment_ocid
  name           = "${local.cluster_name}-lancedb-storage-access"
  description    = "Read Object Storage and consume the HA-NFS LanceDB event Queue."
  statements = [
    "Allow dynamic-group ${var.lancedb_dynamic_group_name} to read buckets in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${var.lancedb_dynamic_group_name} to read objects in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${var.lancedb_dynamic_group_name} to use queue-pull in compartment id ${var.compartment_ocid} where target.queue.id = '${oci_queue_queue.lancedb_events[0].id}'",
  ]
  lifecycle {
    precondition {
      condition     = trimspace(var.lancedb_dynamic_group_name) != ""
      error_message = "lancedb_dynamic_group_name is required when create_lancedb_instance_policy is true."
    }
  }
}
