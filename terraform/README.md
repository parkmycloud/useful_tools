# ParkMyCloud Terraform Setup


### Purpose

ParkMyCloud is SaaS application which allows users to schedule on/off times for their non-production EC2 instances, without having to do scripting. For more details on the application and company, you can go here [http://www.parkmycloud.com].

The purpose of this set of Terraform scripts is to allow users to easily create an IAM Role in AWS that will enable ParkMyCloud to manage their resources.

### How to use

- Install and configure Terraform
- Set your AWS Access Key and Secret Key (if necessary)
- Run "terraform apply" from within the directory containing these files
- Keep the ARN string from the output
- Log in to ParkMyCloud, click on "Cloud Credentials", and click on "Add Cloud Credential"
- Click on "IAM Role" and click Next
- Paste the ARN string from the terraform output and fill out remaining fields, then click "Save"
- Start scheduling resources to save money!