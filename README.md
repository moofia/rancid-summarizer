#RANCID Summarization

At the moment only routes are supported, currently its the default.

##routes

Outputs all connected and static routes

```
./bin/rancid-summarizer.rb --rancid_dir samples/rancid --filter bb1
connected route;bb1.moofia.net;Loopback197;197.68.22.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback197;197.68.21.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback197;197.68.5.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback197;197.68.4.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback197;197.68.1.254;255.255.255.0
connected route;bb1.moofia.net;Loopback199;199.172.16.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.15.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.14.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.13.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.12.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.11.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.10.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.9.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.8.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.7.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.6.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.5.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.4.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.3.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.2.254;255.255.255.0
connected route secondary;bb1.moofia.net;Loopback199;199.172.1.254;255.255.255.0
connected route;bb1.moofia.net;Ethernet0/0;150.1.6.254;255.255.255.0
static route;bb1.moofia.net;0.0.0.0/0.0.0.0 150.1.6.1
```

##TODO / BUGS

* juniper issue with not all interfaces being picked up
* juniper static routes not being picked up
