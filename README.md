#RANCID Summarizer

Extracting your data from your network.

## History

Having been fortunate to have worked for UUNET MCI/WorldCom for 8 years in the emerging markets of Africa we had to smart about operational resources. 
Our primary focus on was on provisioning systems for the network. 

This project aims to bridge the gap between provisioned networks and those configured manually enabling systems that rely on network data to be automated.

##routes

Outputs all connected and static routes

```
./bin/rancid-summarizer.rb --rancid_dir samples/rancid --filter bb1 --mode routes
connected route;bb1.moofia.net;Loopback197;197.68.22.254;/24
connected route secondary;bb1.moofia.net;Loopback197;197.68.21.254;/24
connected route secondary;bb1.moofia.net;Loopback197;197.68.5.254;/24
connected route secondary;bb1.moofia.net;Loopback197;197.68.4.254;/24
connected route secondary;bb1.moofia.net;Loopback197;197.68.1.254;/24
connected route;bb1.moofia.net;Loopback199;199.172.16.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.15.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.14.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.13.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.12.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.11.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.10.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.9.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.8.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.7.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.6.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.5.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.4.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.3.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.2.254;/24
connected route secondary;bb1.moofia.net;Loopback199;199.172.1.254;/24
connected route;bb1.moofia.net;Ethernet0/0;150.1.6.254;/24
static route;bb1.moofia.net;0.0.0.0/0 150.1.6.1

```

Currently collects the following

* connected routes
* static routes
* static routes vrf
 
##TODO / BUGS

* juniper : when a physical interface has a single unit of zero the unit will be referenced as the physical interface

