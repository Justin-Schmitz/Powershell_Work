# ShowCase
This is to showcase my previous work with automating daily life with Powershell and other languages
These are only a few examples of what I can create, due to the nature of the business I work in, I cannot show any examples of scripts written on the company premises due to Intellectual property (IP)
## The New User Creation is my oldest work
### This was my first "major" script written to automate a task I had to repeat day in and out before I decided to give it a bash at automating the job.
- This will Create a new user from a template user created before hand
- Connect to Exchange and ask you what mailbox database you would like them to be in
- Create a network share drive for all their documents
- Create a roaming profile drive
- Give them an email address
- And all the way through prompt the administrator to fill in specific about the user, eg. Name, Password etc.

## A10 Automation script
### This is a part of a greater script I use in conjunction with Team City for our CI/CD deployments
This will let you
- Allow self signed Certs sessions to the A10 via Powershell
- Get a token for the API session
- Get you a session ID
- choose an Active Partition on the A10 Load Balancer
- Choose the service group
- Get you the servers within the Service Group
- Choose the server(s) to disable
- I would have Team City setup to use parameters that would choose the specific server to remove upon running.

## The Mass VM Build Script
### I use this as part of a bigger project to query the connections to the A10 load balancer. 
If a specific threshold is reached I would have it scale out and spawn more Servers and have them install either applications or websites to help manage the load. Once the connections drop, the servers would be destroyed and a min amount of them would be there to run the sites/applications.

 Workings:
   - You choose to build a single or multiple servers
   - You choose the location of the sysprep Windows server image to use
   - If you choose single server mode, you will be prompted for all input
   - If you choose for many server mode, you will have to locate the .csv to use
   - Basic .csv with the columns:
   - VMName | Memory | VLAN | Esize | Fsize | CPU
   - Memory is in MB, eg. 1GB will be 1024 in the above column for the CSV

### Basic Logging Functions:
I have these here for anyone trying to create basic logging functions for their applications, who dont feel like going through the effort of creating these, themselves.

## Authors

* **Justin Schmitz** - *Initial work* - [Justin-Schmitz](https://github.com/Justin-Schmitz)
