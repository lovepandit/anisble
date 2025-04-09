#!/bin/bash

# Google Chat Webhook URL
GCHAT_WEBHOOK="your webhook here"

# Full list of domains and subdomains (for SSL check)
DOMAINS=(
    ""
    ""
    ""
)

# Extract only top-level domains (TLDs) for domain expiry check
TOP_LEVEL_DOMAINS=(
    ""
    ""
    ""
    ""
    ""
    ""
)

# Threshold for triggering alert (in days)
THRESHOLD_DAYS=30

# Function to send alert to Google Chat
send_gchat_alert() {
    local message=$1
    curl -X POST -H "Content-Type: application/json" -d "{\"text\": \"$message\"}" "$GCHAT_WEBHOOK"
}

# Function to check SSL certificate expiration
check_ssl_expiry() {
    local domain=$1
    local expiry_date_str
    local expiry_timestamp
    local current_timestamp

    expiry_date_str=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [[ -n "$expiry_date_str" ]]; then
        expiry_timestamp=$(date -d "$expiry_date_str" +%s 2>/dev/null)
        current_timestamp=$(date +%s)
        
        if [[ -n "$expiry_timestamp" ]]; then
            days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

            echo "SSL Expiry for $domain: $expiry_date_str ($days_left days left)"

            if (( days_left > 0 && days_left < THRESHOLD_DAYS )); then
                formatted_date=$(date -d "$expiry_date_str" "+%Y-%m-%d")
                alert_message="*🔒 SSL Certificate Expiration Alert*\n\n"
                alert_message+="• *Domain*: \`$domain\`\n"
                alert_message+="• *Expiration Date*: \`$formatted_date\`\n"
                alert_message+="• *Days Remaining*: \`$days_left\`\n\n"
                alert_message+="*Action Required*: Renew certificate to avoid service disruption"
                echo "$alert_message"
                send_gchat_alert "$alert_message"
            fi
        else
            echo " Error parsing SSL expiry date for $domain"
        fi
    else
        echo " Failed to retrieve SSL expiry for $domain"
    fi
}

# Function to check domain expiration (only for top-level domains)
check_domain_expiry() {
    local domain=$1
    local expiry_date_str=""
    local expiry_timestamp
    local current_timestamp

    expiry_date_str=$(whois "$domain" 2>/dev/null | grep -iE "Expiry Date|Expiration Date|paid-till" | head -1 | awk '{print $NF}')

    if [[ -n "$expiry_date_str" && "$expiry_date_str" =~ [0-9] ]]; then
        expiry_timestamp=$(date -d "$expiry_date_str" +%s 2>/dev/null)
        current_timestamp=$(date +%s)

        if [[ -n "$expiry_timestamp" ]]; then
            days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

            echo "Domain Expiry for $domain: $expiry_date_str ($days_left days left)"

            if (( days_left > 0 && days_left < THRESHOLD_DAYS )); then
                formatted_date=$(date -d "$expiry_date_str" "+%Y-%m-%d")
                alert_message="*🌐 Domain Registration Expiration Alert*\n\n"
                alert_message+="• *Domain*: \`$domain\`\n"
                alert_message+="• *Expiration Date*: \`$formatted_date\`\n"
                alert_message+="• *Days Remaining*: \`$days_left\`\n\n"
                alert_message+="*Action Required*: Renew domain registration to prevent DNS failure"
                echo "$alert_message"
                send_gchat_alert "$alert_message"
            fi
        else
            echo " Error parsing domain expiry date for $domain"
        fi
    else
        echo " Failed to retrieve domain expiry for $domain"
    fi
}

# Function to check SonarQube License expiry
check_sonarqube_license() {
    echo " Checking SonarQube License Expiry..."
    
    local response
    local expiry_date
    local expiry_timestamp
    local current_timestamp
    local SONARQUBE_TOKEN="sonar-access-token"
    local SONARQUBE_URL="sonarurl"

   # Fetch license data from SonarQube API
    response=$(curl -s -u "$SONARQUBE_TOKEN:" "$SONARQUBE_URL/api/editions/show_license")

    if [[ "$response" == *"expiresAt"* ]]; then
        expiry_date=$(echo "$response" | grep -oP '"expiresAt":"\K[^"]+')
        expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
        current_timestamp=$(date +%s)

        if [[ -n "$expiry_timestamp" ]]; then
            days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

            echo "SonarQube License Expiry: $expiry_date ($days_left days left)"

            if (( days_left > 0 && days_left < THRESHOLD_DAYS )); then
                formatted_date=$(date -d "$expiry_date" "+%Y-%m-%d")
                alert_message="*📜 SonarQube License Expiration Alert*\n\n"
                alert_message+="• *Service*: \`SonarQube\`\n"
                alert_message+="• *Expiration Date*: \`$formatted_date\`\n"
                alert_message+="• *Days Remaining*: \`$days_left\`\n\n"
                alert_message+="*Action Required*: Contact vendor to renew license"
                echo "$alert_message"
                send_gchat_alert "$alert_message"
            fi
        else
            echo "Error parsing SonarQube license expiry date"
        fi
    else
        echo "Failed to retrieve SonarQube license expiry date"
    fi
}

# Main script execution
echo "Checking SSL and Domain Expiration Dates..."
echo "-------------------------------------------"

# Check SSL for all domains and subdomains
for domain in "${DOMAINS[@]}"; do
    echo " Checking SSL for $domain..."
    check_ssl_expiry "$domain"
    echo "-------------------------------------------"
done

# Check domain expiry only for top-level domains
for domain in "${TOP_LEVEL_DOMAINS[@]}"; do
    echo " Checking domain expiry for $domain..."
    check_domain_expiry "$domain"
    echo "-------------------------------------------"
done

# Check SonarQube License expiry
check_sonarqube_license
echo "-------------------------------------------"
