# terraform SSL certificate example when using external DNS

Much of this is borrowed from this URL: https://shocksolution.com/2021/09/30/define-a-google-load-balancer-and-cloud-storage-bucket-with-terraform/

Create a secret.tfvars file containing something similar to the following:

```
credentials_file  = "wibbly-flibble-stuff-morestuff.json"
project           = "wibble-flibble-numbers"
region            = "europe-west2"
project_lifecycle = "development"
```

Create the   wibbly-flibble-stuff-morestuff.json from :
```
$ gcloud iam service-accounts keys create wibbly-flibble-stuff-morestuff.json \
    --iam-account=SA_NAME@PROJECT_ID.iam.gserviceaccount.com 
```
##Applying

```
$ terraform init -var-file=secret.tfvars
$ terraform plan -var-file=secret.tfvars
$ terraform apply -var-file=secret.tfvars
```

Create a DNS authorization for a wildcard domain in gcp
Create a DNS authorization for the top level domain (not wildcard):


```
% gcloud certificate-manager dns-authorizations create wildcard-chegwin-org --domain="chegwin.org"
gcloud certificate-manager dns-authorizations create wildcard-chegwin-org --domain="chegwin.org"
API [certificatemanager.googleapis.com] not enabled on project [<numberstring>]. Would you like to enable and retry (this will take a 
few minutes)? (y/N)?  y

Enabling service [certificatemanager.googleapis.com] on project [<numberstring>]...
Operation "operations/acat.p2-<numberstring>-<morenumbers>" finished successfully.
Create request issued for: [wildcard-chegwin-org]
Waiting for operation [projects/<project>/locations/global/operations/operation-<morenumbers>] to complete...done.                                                                                                            
Created dnsAuthorization [wildcard-chegwin-org].

```
Find the record which needs adding into DNS as a CNAME:

```
gcloud certificate-manager dns-authorizations describe wildcard-chegwin-org
createTime: '2022-12-29T15:02:46.835874955Z'
dnsResourceRecord:
  data: <unique_id>.<integer>.authorize.certificatemanager.goog.
  name: _acme-challenge.chegwin.org.
  type: CNAME
domain: chegwin.org
name: projects/<project>/locations/global/dnsAuthorizations/wildcard-chegwin-org
updateTime: '2022-12-29T15:02:48.395653444Z'
```

Add a CNAME entry in for the following: - Record: _acme-challenge - Type: CNAME - TTL: 300 - Alias: <longstring>.<integer>.authorize.certificatemanager.goog.

Create the wildcard certificate which references the dns-authorization:

```
gcloud certificate-manager certificates create wildcard-chegwin-org --domains="*.chegwin.org" --dns-authorizations="wildcard-chegwin-org"
Create request issued for: [wildcard-chegwin-org]
Waiting for operation [projects/<project-id>/locations/global/operations/operation-<unique-id>
9dda] to complete...done.                                                                                                            
Created certificate [wildcard-chegwin-org].
```

Check that the certificate has been generated - this can take a few minutes: 

```
$ gcloud certificate-manager certificates describe wildcard-chegwin-org
createTime: '2022-12-29T17:15:24.721492506Z'
managed:
  authorizationAttemptInfo:
  - domain: '*.chegwin.org'
    state: AUTHORIZED
  dnsAuthorizations:
  - projects/<projectid>/locations/global/dnsAuthorizations/wildcard-chegwin-org
  domains:
  - '*.chegwin.org'
  state: PROVISIONING
name: projects/<projectid>/locations/global/certificates/wildcard-chegwin-org
sanDnsnames:
- '*.chegwin.org'
updateTime: '2022-12-29T17:15:26.232869386Z'
```



There is no data source for google_certificate_manager_certificates, so this needs importing as a resource

```
terraform import -var-file=secret.tfvars google_certificate_manager_certificate.default "wildcard-chegwin-org"
```
