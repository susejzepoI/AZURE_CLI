#Interactive lab
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-03-2024
#Modified date:     August-05-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/host-domain-azure-dns/4-exercise-create-dns-zone-a-record

#JLopez-05082024: Creating the DNS zone.
az network dns zone create `
    --name wideworldimports05082024.com `
    --resource-group "learn-384103b5-6a70-427a-8d4d-ff79c400a2d4" `
    --subscriptio "Concierge Subscription"

#JLopez-05082024: Adding the A record set to the DNS zone.
az network dns record-set a add-record `
    --record-set-name "www" `
    --resource-group "learn-384103b5-6a70-427a-8d4d-ff79c400a2d4" `
    --subscriptio "Concierge Subscription" `
    --ttl 3600 `
    --zone-name wideworldimports05082024.com `
    --ipv4-address 10.10.10.10
