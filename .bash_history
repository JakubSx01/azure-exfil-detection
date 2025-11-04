mkdir .github/workflows
mkdir .github
cd .github/
mkdir workflows
cd workflows/
vi validate.yml
vi deploy-dev.yml
cd ..
az ad app create --display-name "github-actions-exfil-detection"
APP_ID=$(az ad app list --display-name "github-actions-exfil-detection" --query [0].appId -o tsv)
az ad sp create --id $APP_ID
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)
az role assignment create   --assignee $APP_ID   --role Contributor   --scope /subscriptions/1c7ecdfb-e278-4f70-8a4b-a015466c7cdf/resourceGroups/rg-exfil-lab-dev
az account show --query id -o tsv
[200~az ad app federated-credential create   --id $APP_ID   --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:JakubSx01/azure-exfil-detection:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
# 6. Pobierz Tenant ID i Subscription ID
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $(az account show --query id -o tsv)"
~
az ad app federated-credential create   --id $APP_ID   --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:JakubSx01/azure-exfil-detection:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
git init
git add .
git commit -m "Initial commit: Bicep IaC + GitHub Actions"
git branch -M main
git remote add origin https://github.com/JakubSx01/azure-exfil-detection.git
git push -u origin main
# Opcja 1: Pull + merge (jeśli repo ma README)
git pull origin main --allow-unrelated-histories
git push -u origin main
# Opcja 2: Force push (jeśli repo puste/nic nie stracisz)
git push -u origin main --force
# Opcja 3: Sprawdź co jest w repo
git remote -v
git fetch origin
git branch -a
git config --global user.email "171193@stud.prz.edu.pl"
git config --global user.name "JakubSx01"
ls
ls -la
cd /home/jakub/
ls
cd ..
ls
cd ..
ls
find infra
cd home/
cd jakub/
ls
cd mi
cd Microsoft/
ls
cd ..
cd /home/jakub  # lub gdzie masz folder z infra/
ls -la
find ~ -name "*.bicep" -type f 2>/dev/null
mkdir infra
cd infra/
mkdir modules
cd. .
cd ..
vi infra/modules/network.bicep
cd infra/modules/
vi storage.bicep
vi monitoring.bicep
vi ../main.bicep
cd. .
cd ..
ls
vi main.bicep
az ad signed-in-user show --query id -o tsv
vi dev.bicepparam
vi prod.bicepparam
vi modules/monitoring.bicep 
ls
ls -la
ls modules/
vi modules/keyvault.bicep
cd ..
az deployment group create   --resource-group rg-exfil-lab-dev   --template-file infra/main.bicep   --parameters infra/dev.bicepparam   --name "deploy-exfil-$(date +%Y%m%d-%H%M%S)"
# Opcja 1: Pull + merge (jeśli repo ma README)
git pull origin main --allow-unrelated-histories
git push -u origin main
# Opcja 2: Force push (jeśli repo puste/nic nie stracisz)
git push -u origin main --force
# Opcja 3: Sprawdź co jest w repo
git remote -v
git fetch origin
git branch -a
ls
ls -la
