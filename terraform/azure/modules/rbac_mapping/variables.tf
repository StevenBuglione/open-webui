variable "group_lookup" {
  description = "Map of group display names to metadata (typically from the groups module output)."
  type = map(object({
    object_id = string
    mail      = optional(string)
  }))
}

variable "mappings" {
  description = "Desired OpenWebUI role and LiteLLM budget mappings keyed by group display name."
  type = map(object({
    openwebui_role = string
    lite_llm_team  = string
    description    = optional(string)
    environment    = optional(string)
  }))
}
