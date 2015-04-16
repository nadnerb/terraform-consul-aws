Consul cluster on AWS using Terraform
=============

Modified and unfinished from the consul examples.

## Using Terraform

Execute the plan to see if everything works as expected.

```
terraform plan -var-file '~/.aws/default.tfvars'
```

Apply

```
terraform apply -var-file '~/.aws/default.tfvars'
```

## TODO

* multi AZ
