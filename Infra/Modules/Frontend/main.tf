resource "azurerm_linux_web_app" "this" {
  name                = var.web_app_frontend_name
  location            = var.region
  resource_group_name = var.resource_group_name

  service_plan_id = var.app_service_plan_id
  https_only      = true

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  site_config {
    ftps_state                  = "Disabled"
    minimum_tls_version         = "1.2"
    vnet_route_all_enabled      = true
    scm_use_main_ip_restriction = true
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "../App/FrontendPortal"
  output_path = "../Temp/frontendportal.zip"
  excludes    = ["build", "node_modules", ".env", ".env.development", ".next"]
}

resource "null_resource" "this" {
  provisioner "local-exec" {
    command = templatefile("Modules/Frontend/deploy.tftpl",
      {
        azurerm_linux_web_app_default_hostname = "${azurerm_linux_web_app.this.default_hostname}"
        frontend_app_id                        = "${var.frontend_app_id}"
        azuread_tenant_id                      = "${var.azuread_tenant_id}"
        sandbox_azure_subscription_id          = "${var.sandbox_azure_subscription_id}"
        api_management_gateway_url             = "${var.api_management_gateway_url}"
        api_name                               = "${var.api_name}"
        api_create_url                         = "${var.api_create_url}"
        api_list_url                           = "${var.api_list_url}"
        api_delete_url                         = "${var.api_delete_url}"
        api_reset_url                          = "${var.api_reset_url}"
        resource_group_name                    = "${var.resource_group_name}"
        azurerm_linux_web_app_name             = "${azurerm_linux_web_app.this.name}"
    })

    interpreter = ["PowerShell", "-Command"]
  }
  triggers = {
    input_json                    = filemd5(data.archive_file.this.output_path)
    deployscript                  = filemd5("Modules/Frontend/deploy.tftpl")
    deploy_target                 = azurerm_linux_web_app.this.id
    clientid                      = var.frontend_app_id
    api_management_name           = var.api_management_gateway_url
    tenantid                      = var.azuread_tenant_id
    sandbox_azure_subscription_id = var.sandbox_azure_subscription_id
    APIName                       = var.api_name
    createurl                     = var.api_create_url
    listurl                       = var.api_list_url
    deleteurl                     = var.api_delete_url
    reseturl                      = var.api_reset_url
  }
}
