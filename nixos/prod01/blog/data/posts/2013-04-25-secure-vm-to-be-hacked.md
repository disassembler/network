{---
title = "How to secure a VM to be hacked";
tags = [ "content" ];
uid = "secure-vm-hacked";
---}

Using FreeBSD jails to secure a VM to be hacked

>>>

Several of us from AppliedTrust (Chris, Tyler and I) volunteered with the Boulder OWASP chapter to help create and run the Capture the Flag Event at SnowFROC this year. A Capture the Flag (CTF) is a competition where teams get points by finding flags hidden in hacking challenges. The hardest task in preparing a CTF event is preventing cheating, as you can imagine when you have a room full of skilled IT Security and hacking specialists, competing for prizes. I think we came up with some pretty interesting ways of thwarting attempts to cheat, and I’m going to walk you through some of the efforts we took to prevent it.

First, lets start with the technologies we used for this event. Most CTF events involve attacking a central server, which presents many challenges of its own. We wanted to do something different, so we built individual virtual machines (VM) for each competitor. This ensured that the competitors were not able to disrupt each other’s competition environment. The difficult part was preventing the participant from getting into the filesystem using an off-line method, such as booting off of a live CD. To mitigate that concern, we split the drive into 5 parts; the main OS and 4 encrypted partitions. Each encrypted partitionwould be used for one of the 4 acts of the competition.In order to obtain complete isolation between each partition, we chose to use FreeBSD jails. A FreeBSD jail isolates connections and services by IP address from other jails on the same system and the host system. This means if an attacker gains root access in a FreeBSD jail, they cannot gain access to the host or other jails on the server. For the encryption piece, we used a program called geli. Geli is a tool that encrypts a file. In UNIX systems, devices are files, so geli can encrypt a disk partition, which is what we used it for. We also had a separate server, the scoreboard, that the user created an account on and added any flags they found.

One of the more difficult aspects was automating the unlocking of the next act once a user had obtained the required number of flags to move on. To do this, we created a special user that had sudo privileges to only run the commands it needed to unlock the act. We then setup the scoreboard that was tracking the progress of each of the individuals and teams to remotely ssh into the VM and unlock the partition.

To give you a better idea of how this worked, I’ve broken the process out into steps below:

1. Competitor boots their competitor VM.
2. The Competitor VM bootup message provides the competitor with the URL to the scoreboard, as well as the VMs IP address (the scoreboard needs this information to identify the VM).
3. The competitor registers an account on the scoreboard. One of the parameters the competitor inputs is the IP of competitor VM.
4. The scoreboard securely logs into the competitor VM using a special unlock account, and runs the geli commands to attach the key to the volume of the first act, unlocking the device.
5. The scoreboard imports the unlocked ZFS pool and runs ezjailadmin to start the jail. The competitor must also add entries to their local /etc/hosts for the host-only network adapter on the host computer. (We are planning to simplify this process for next year). The competitor then interacts with links on the scoreboard that redirect to exercises on the competitor VM.
6. The competitor submits flags found to the scoreboard.
7. Once the competitor reaches the flag threshold for the next act, repeat steps 4-6 for acts 2, 3, and 4.
8. Time runs out and the total scores are tallied on the scoreboard to identify winners.
 
This jail unlock process prevents the competitor from being able to access the individual acts directly. There are ways to indirectly access the individual acts that we are aware of, such as creating an account on the VM via a boot CD and walking through the directories after the unlock happens. We did not address these situations in this post, but using a tool like radmind to manage the /etc directory and requiring it to be running/functioning prior to unlocking the device could mitigate this risk. Our goal for next year is to improve on the security of both the VM as well as the scoreboard, and we’ve identified many ways to do so! Everyone at the competition had a great time,and we had several competitors comment on how they enjoyed the unique VM/scoreboard configuration. All of the documentation/code for this will be public soon, so stay tuned!
