# Umami on Azure 🚀

[![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/Bicep-0078D4?style=flat&logo=microsoft-azure&logoColor=white)](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
[![Umami](https://img.shields.io/badge/Umami-FF6B35?style=flat&logo=umami&logoColor=white)](https://umami.is/)

## 📋 Overview

This repository provides a complete, automated infrastructure-as-code solution for hosting **Umami**, a privacy-focused, open-source web analytics platform, in Microsoft Azure.
Designed as a modern alternative to Google Analytics, this setup prioritizes data privacy, security, and full organizational control over analytics data.

The entire deployment is orchestrated using **Azure Bicep templates**, ensuring reproducible, maintainable, and scalable infrastructure provisioning.

### 🏗️ Architecture Highlights

- **🔧 Infrastructure as Code**: All resources defined using Azure Bicep for maintainable, version-controlled infrastructure
- **🐳 Containerized Deployment**: Umami runs on Azure App Service with Linux containers for optimal performance and scalability  
- **🔒 Network Security**: Isolated deployment using Azure Virtual Networks with private DNS and secure connectivity
- **📊 Privacy-First Analytics**: Complete data ownership with GDPR-compliant analytics platform

This solution is perfect for organizations seeking enterprise-grade analytics without compromising on data privacy or control.

## 🚀 Quick Start

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- Active Azure subscription with appropriate permissions

### Deployment Steps

1. **Authenticate with Azure**

   ```pwsh
   az login
   ```

2. **Deploy the Infrastructure**

   ```pwsh
   az deployment sub create --location <your-azure-region> -f ./deployUmami.bicep -p ./parameters/local.bicepparam
   ```

   > Replace `<your-azure-region>` with your preferred Azure region (e.g., `swedencentral`)

3. **Resource Provisioning**

   The deployment automatically provisions:
   - Azure App Service with Linux container
   - PostgreSQL Flexible Server database
   - Virtual Network with private endpoints
   - Supporting networking infrastructure

> ⚠️ **Environment Notice**: This configuration currently deploys a local/development environment. Production and staging environments will be supported in future releases.

## 🐳 Local Development with Docker Compose

For local development and testing, you can run Umami using Docker Compose. The Docker Compose configuration is based on the official Umami repository with minor modifications for increased reusability and flexibility.

### Prerequisites

- [Docker](https://www.docker.com/get-started) and Docker Compose installed
- Git for cloning the repository

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/Physer/umami-setup
   cd umami-setup
   ```

2. **Configure environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit the `.env` file with your configuration:
   - Set database credentials
   - Configure application settings
   - Adjust any other environment-specific variables

3. **Start the services**

   ```bash
   docker compose up -d
   ```

4. **Access Umami**

   Once started, Umami will be available at `http://localhost:3000`

5. **Stop the services**

   ```bash
   docker compose down
   ```

## ✨ Current Features

- ✅ **Automated Infrastructure Provisioning** - Complete resource deployment using Bicep templates
- ✅ **Azure CLI Integration** - Streamlined deployment via command-line interface with parameter files  
- ✅ **Virtual Network Security** - Isolated network architecture with private endpoint connectivity
- ✅ **Container-Based Hosting** - Modern Linux container deployment on Azure App Service
- ✅ **Local Development Setup** - Docker Compose configuration for streamlined local development and testing
- ✅ **Application Monitoring** - Azure Application Insights integration for comprehensive observability

## 🛣️ Roadmap

The following enhancements are planned to expand and improve the platform:

### 🔧 Development & Operations

- **🔄 CI/CD Automation** - Automated deployment pipelines for staging and production environments

### 🔐 Security & Configuration  

- **🔑 Secrets Management** - Azure Key Vault integration for secure credential handling
- **🌐 Custom Domains** - Support for custom domain configuration via Bicep automation
- **🛡️ Access Control** - IP whitelisting and Entra ID managed identity integration

### 🚀 Advanced Deployment

- **⚡ Zero-Downtime Updates** - Sidecar deployment pattern implementation
- **🔒 Enhanced Security** - Advanced network isolation and access restrictions

---

## 📞 Support

For questions, issues, or contributions, please open an issue in this repository.

## 📄 License

This project is open-source. Please review the license file for details.
