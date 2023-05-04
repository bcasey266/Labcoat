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
    command = <<-EOT
    cd ../App/FrontendPortal
    New-Item -Path .env -force
    Add-Content -Path .env -Value "NEXT_PUBLIC_redirectUri=https://${azurerm_linux_web_app.this.default_hostname}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_clientID=${var.frontend_app_id}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_TenantID=${var.azuread_tenant_id}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_SandboxSubscription=${var.sandbox_azure_subscription_id}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_api_management_name=${var.api_management_gateway_url}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_APIName=${var.api_name}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_APICreate=${var.api_create_url}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_APIList=${var.api_list_url}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_APIDelete=${var.api_delete_url}"
    Add-Content -Path .env -Value "NEXT_PUBLIC_APIReset=${var.api_reset_url}"

    npm install
    npm run build
    Compress-Archive -Path build\* -DestinationPath ../../Temp/frontendbuild.zip -force
    az webapp deployment source config-zip --resource-group ${var.resource_group_name} --name ${azurerm_linux_web_app.this.name} --src ../../Temp/frontendbuild.zip --only-show-errors > ../../Temp/frontendoutput.txt
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
  triggers = {
    input_json                    = filemd5(data.archive_file.this.output_path)
    deploy_target                 = azurerm_linux_web_app.this.id
    webapphostname                = azurerm_linux_web_app.this.default_hostname
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
