resource "azurerm_service_plan" "temp" {
  name                = var.ServicePlanFEName
  resource_group_name = var.ResourceGroupName
  location            = var.location

  os_type  = "Windows"
  sku_name = "B1"
}

resource "azurerm_windows_web_app" "this" {
  name                = var.WebAppName
  resource_group_name = var.ResourceGroupName
  location            = var.location
  service_plan_id     = azurerm_service_plan.temp.id

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

data "archive_file" "frontend_app_code" {
  type        = "zip"
  source_dir  = "../App/FrontendPortal"
  output_path = "../Temp/frontendportal.zip"
  excludes    = ["build", "node_modules", ".env", ".env.development"]
}

resource "null_resource" "frontend_publish" {
  provisioner "local-exec" {
    command = <<-EOT
    cd ../App/FrontendPortal
    New-Item -Path .env -force
    Add-Content -Path .env -Value "REACT_APP_redirectUri=https://${azurerm_windows_web_app.this.default_hostname}"
    Add-Content -Path .env -Value "REACT_APP_clientID=${var.FrontendAppID}"
    Add-Content -Path .env -Value "REACT_APP_TenantID=${var.AzureADTenantID}"
    Add-Content -Path .env -Value "REACT_APP_SandboxSubscription=${var.SandboxSubID}"
    Add-Content -Path .env -Value "REACT_APP_APIMName=${var.APIMGatewayURL}"
    Add-Content -Path .env -Value "REACT_APP_APIName=${var.APIName}"
    Add-Content -Path .env -Value "REACT_APP_APICreate=${var.APICreateURL}"
    Add-Content -Path .env -Value "REACT_APP_APIList=${var.APIListURL}"
    Add-Content -Path .env -Value "REACT_APP_APIDelete=${var.APIDeleteURL}"
    Add-Content -Path .env -Value "REACT_APP_APIReset=${var.APIResetURL}"

    npm install
    npm run build
    Compress-Archive -Path build\* -DestinationPath ../../Temp/frontendbuild.zip -force
    az webapp deployment source config-zip --resource-group ${var.ResourceGroupName} --name ${azurerm_windows_web_app.this.name} --src ../../Temp/frontendbuild.zip --only-show-errors > ../../Temp/frontendoutput.txt
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
  triggers = {
    input_json     = filemd5(data.archive_file.frontend_app_code.output_path)
    deploy_target  = azurerm_windows_web_app.this.id
    webapphostname = azurerm_windows_web_app.this.default_hostname
    clientid       = var.FrontendAppID
    APIMName       = var.APIMGatewayURL
    tenantid       = var.AzureADTenantID
    sandboxsubid   = var.SandboxSubID
    APIName        = var.APIName
    createurl      = var.APICreateURL
    listurl        = var.APIListURL
    deleteurl      = var.APIDeleteURL
    reseturl       = var.APIResetURL
  }
}
