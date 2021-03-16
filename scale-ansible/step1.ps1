---
- hosts: localhost
  vars_files:
  - '.secrets.yml'

  collections:
    - netapp.elementsw
    - community.vmware.vmware_cluster


vars:
  datacenter_name: ansibledc
  cluster_name: ansiblecluster

  

- name: Create Datacenter
  community.vmware.vmware_datacenter:
    hostname: '{{ vcenter_hostname }}'
    username: '{{ vcenter_username }}'
    password: '{{ vcenter_password }}'
    datacenter_name: '{{ datacenter_name }}'
    state: present
  delegate_to: localhost




- name: Delete Datacenter
  community.vmware.vmware_datacenter:
    hostname: '{{ vcenter_hostname }}'
    username: '{{ vcenter_username }}'
    password: '{{ vcenter_password }}'
    datacenter_name: '{{ datacenter_name }}'
    state: absent
  delegate_to: localhost
  register: datacenter_delete_result


 - name: Create Cluster with additional changes
   community.vmware.vmware_cluster:
     hostname: "{{ vcenter_hostname }}"
     username: "{{ vcenter_username }}"
     password: "{{ vcenter_password }}"
     datacenter_name: "{{ datacenter_name }}"
     cluster_name: "{{ cluster_name }}"
     enable_ha: True
     ha_vm_monitoring: vmMonitoringOnly
     enable_drs: True
     drs_default_vm_behavior: fullyAutomated
     enable_vsan: False
   register: cl_result
   delegate_to: localhost

 - name: Delete Cluster
   community.vmware.vmware_cluster:
     hostname: "{{ vcenter_hostname }}"
     username: "{{ vcenter_username }}"
     password: "{{ vcenter_password }}"
     datacenter_name: "{{ datacenter_name }}"
     cluster_name: cluster
     enable_ha: true
     enable_drs: true
     enable_vsan: true
     state: absent
   delegate_to: localhost
