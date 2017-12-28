# Customizing node bringup sequence

## Use cases
Some of the needs for such customization can be to:
- Install prerequisite drivers/plugins/libraries like GPU drivers/CUDA Libraries (NOTE: The hooks mechanism described [here](https://github.com/kubernetes/kops/blob/master/docs/gpu.md) can be used to bring up GPU nodes, however the resources exposed by the drivers need to be available before the kubelet comes up on the node. The hooks mechanism requires a relaunch of the kubelet after the hook completes running to discover the resources. The method described here helps with this scenario and avoids a reload of the kubelet.)
- Have post-bringup scripts to process logs/status of the nodes. (A more elegant solution for this would be to use daemonsets on the nodes)
- Here's an extensive list of other use-cases - [use-case examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)

Until a solution like [kops plugin library](https://github.com/kubernetes/kops/issues/958) is provided, the recommendation provided here can be used to customize the boot sequence.

## Understanding node bringup sequence
Kops uses nodeup to install necessary packages and bringup kubelet on the node. This is achieved by downloading the nodeup binary from the NODEUP_URL and launching it via systemd service `(kops-configuration.service)`.
The actual download of the nodeup binary is done by cloud-init script which is configured as path of the Launch configuration of the instance-group's ASG.

## Customizing via AdditionalUserData
As mentioned [here](https://github.com/kubernetes/kops/blob/master/docs/instance_groups.md#additional-user-data-for-cloud-init), addtionalUserData can be used to pass additional commands/scripts to configure the host. Note that the cloud-config scripts are executed in the order returned by python's sorted() function. So, paying attention to the naming of the scripts will help in ordering of the scripts.

## Further customization with systemd units
The procedure described above should work for scenarios that does not require strict ordering with the nodeup sequence. The reason for this is that the nodeup script just downloads the nodeup binary and finally launches it via a systemd unit, which could be happening in parallel to your custom scripts. To enforce proper ordering of the scripts, customize the kops-configuration.service system unit as shown below:

```
spec:
  additionalUserData:
  - name: custom-install-sequence.txt
    type: text/cloud-config
    content: |
      #cloud-config
      write_files:
        - path: /var/cache/custom-install/log-time.sh
          permissions: "0755"
          content: |
            #!/bin/bash
	    echo "Hello World.  The time is now $(date -R)!" | tee /root/output.txt
      bootcmd:
        - mkdir -p /lib/systemd/system/kops-configuration.service.d
        - echo [Service] >> /lib/systemd/system/kops-configuration.service.d/custom-setup.conf
        - echo ExecStartPre=/bin/bash /var/cache/custom-install/log-time.sh >> /lib/systemd/system/kops-configuration.service.d/custom-setup.conf
	- echo ExecStopPost=/bin/touch /var/cache/kubernetes-install/nodeup_script_launch_done >> /lib/systemd/system/kops-configuration.service.d/custom-setup.conf
        - echo TimeoutSec=infinity # Might be required for scripts that install a lot of drivers/libraries >> /lib/systemd/system/kops-configuration.service.d/custom-setup.conf
        - systemd daemon-reload
```

Here the sequence would be run `/var/cache/custom-install/log-time.sh -> /var/cache/kubernetes-install/nodeup.sh -> touch /var/cache/kubernetes-install/nodeup_script_launch_done`.

### NOTES:
- `bootcmd`  is run in very early stages of the node bringup. Commands that require any kind of network access would fail at this stage as the node does not have any networking setup yet.
- Refer to cloud-init sequences [here](https://cloudinit.readthedocs.io/en/latest/topics/boot.html) and [here](https://git.launchpad.net/cloud-init/tree/config/cloud.cfg.tmpl) to better customize the node setup sequence.
