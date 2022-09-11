set -ex

DBName=$(echo "$1" | tr '-' '_')
DBPass=$(openssl rand -base64 48 | tr '+/' '-_')-Xx1
AppServicePlanId=$(az webapp show --ids $2 --query appServicePlanId -o tsv)
DB_URL_FORMAT=$(az appservice plan show --ids $AppServicePlanId --query tags.DB_URL_FORMAT -o tsv)
DATABASE_URL=$(echo "$DB_URL_FORMAT" | sed -e "s,{0},$DBName,g;s,{1},$DBPass,g;s,{2},$DBName,g")
az webapp config appsettings set --ids $2 --settings "DATABASE_URL=$DATABASE_URL"

SECRET_KEY_BASE=$(openssl rand -base64 96 | tr -d '\n' | tr '+/' '-_')-Xx1
az webapp config appsettings set --ids $2 --settings "SECRET_KEY_BASE=$SECRET_KEY_BASE"
