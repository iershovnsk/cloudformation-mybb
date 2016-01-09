# MyBBAWS Infrastructure

## Considerations

- This file is written in [Markdown format](https://daringfireball.net/projects/markdown/syntax).

- This project deploys a Multi-Tier Architecture on a single AWS region; the region is
intentionally not explicitly specified in the template so the region in which the stack is launched
will be used.

- I assumed an externally registered domain name (not via Route53); the automation template outputs
the AWS-generated DNSName of the main (WWW) load balancer and a CNAME record should be defined to
point to this name.

## Completion overview

Layer                  | Scalability | Availability | Security | Monitoring | Automation
-----------------------|-------------|--------------|----------|------------|------------
Web service            |             |              |          |            |
Database               |             |              |          |            |
File storage           |             |              |          |            |
Networking & Balancing | Done        | Done         | Done     | (n/a)      | Done

## Brief structure listing

The broad view of the most significant design components in this infrastructure is as follows:

1. **CloudFormation automation**: A CloudFormation template describes and launches all resources
and sub-components described below.

2. **VPC encapsulation**:

    - Subnets in distinct availability zones:
        - **PublicSubnetA/B**: web servers stack, the subnets are publicly accessible.
        - **HiddenSubnetA/B**: database stack, the subnets are not publicly accessible.

    - Security groups:
        - **PublicScurityGroup**: HTTP/HTTPS/SSH access permitted from outside.
        - **HiddenSecurityGroup**: Database, access permitted only from web stack to DB stack.

    - RouteTables:
        - **PublicRouteTable**: opens traffic from the public subnets to the Internet.
        - **HiddenRouteTable**: ensures privacy for the hidden subnets.

    - Gateways:
        - **VPCInternetGateway**: gateway to Internet for VPC components (PublicSubnet).
        - **VPCNATGateway**: NAT proxy for outbound traffic from hidden subnets to the Internet.

3. **AutoScaling**: An ASG (auto scaling group) spanning multiple availability zones for running
the Apache2/PHP5 (incl. dependencies) and the MyBB web application itself. The ASG scales up/down
based on the level of CPU usage (90/50) on the working machines (monitored by CloudWatch).

4. **Balancing**: (A) An ELB (elastic load balancer) deployment in front of the WWW ASG (public
facing) for ensuring load-balancing and high-availability (fail-over) for web-service nodes.
(B) The Database tier is based on an Aurora DBCluster which has a self-contained balancing (and
fail-over) mechanism.

5. **Storage and CDN**: MyBB is configured to store files in a automatically provided S3 bucket;
these files will be accessed by the end-users via the CloudFront CDN; a browser-specific caching
policy is also configured into the system to refine this setup.

6. **Database**: I decided to implement the MySQL database as a Multi-AZ RDS Aurora cluster since
this provides better availability and scaling compared to a classic RDS/MySQL setup.

7. **Monitoring and Alerting**: Implemented via CloudWatch and used as basic mechanism for scaling
up/down and also sending operational notifications on events (see "OperationalEMailParameter").
Additionally, the ELB which spreads load over the web server ASG commits it's logs every 5 minutes
into an S3 Bucket.

## Design details (diagrams)

(TODO)

## Security considerations

(TODO)

## Monitoring and alerts

(TODO)

## Template configuration variables

(TODO)

## Further improvements

This is only an initial version of the automation template, which what I could build in the time
constraints I had, and so there are a few aspects in which this work could (and probably should) be
improved before actually going live with it:

- **Split template** into two separate stacks, database and web service.

- **Tag everything**.

- The automation template (along with this documentation) are revision-controlled on a public
**GitHub repository**; this repository is also used (for simplicity) to host the Bash installation
script for MyBB 1.8.6 (including MyBB sources). It would be preferable that this would be turned
into a new AMI instance.

- **Availability-Zones**: For increased availability subnets should be created in all availability
zones; currently I only targeted two AZs.

- Define **Network ACLs** for subnets.

- **Remove Public IPs in PublicSubnets**: Currently I set "MapPublicIpOnLaunch" to true on public
subnets for a quick way to debug the launch configuration; a bastion server should be used.

- **Outbound access for DB servers via NAT** (optional): It could be useful to allow outbound
access to the Internet for the machines residing in the private subnet of the VPC (for updates and
such) by using a **NAT Gateway**.

- Define clear **Stack update and delete policies** to avoid downtimes during updates and to retain data (logs, databases etc.) after stack operations.

- **Time-based scaling**: Currently, the Auto-Scaling Groups resize solely based on CloudWatch
performance metrics; rules for timed scaling could be defined to optimize costs.

- **Track CloudFormation calls via CloudTrail**: For additional security and as a measure of
historical reference, CloudTrail should be used to log all CloudFormation API calls into a selected
S3 bucket. The benefit is good and the costs should be negligible.

- **Restrict SSH access**: By default the "SSHAllowedSources" parameter is set to "0.0.0.0/0" to
allow any SSH connections to the nodes from any public IP address; this setting should be
considerably more restrictive.

- **HTTPS support**: For a production environment I would enable HTTPS support and even try to
force traffic through it (redirect via HTTP 301).

## Evaluation Access

(TODO) Observer account.

- MyBB application Administrator Account:
    - Username: admin
    - Password: 1234