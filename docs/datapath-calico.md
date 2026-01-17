# Calico

Pod → pod (no Service)

- Same node:
  1. pod veth → host veth peer
  2. cali\* host routing to dest pod
  3. dest pod veth
  4. No kube-proxy; no encap
- Cross node:
  1. pod veth → host veth peer
  2. cali\* host routing selects remote node
  3. forward routed or encapsulated (VXLAN device, or IPIP via tunl0)
  4. remote node decaps (if used), host route to dest pod veth
  5. No kube-proxy

Pod → ClusterIP Service

- Same node:
  1. pod veth → host veth peer
  2. kube-proxy iptables/IPVS DNATs ClusterIP → pod IP
  3. if backend local: hairpin via host netns back to dest pod veth
  4. Calico just routes locally
- Cross node:
  1. pod veth → host veth peer
  2. kube-proxy DNATs to chosen backend IP
  3. Calico sends toward remote node (routed, VXLAN device, or IPIP via tunl0)
  4. remote node decap (if encap), host route to dest pod veth

Summary: Without a Service, Calico routes directly; cross-node may use VXLAN or IPIP (tunl0). Adding ClusterIP introduces kube-proxy DNAT on the source node; Calico still handles the transport (routed or encapsulated) after the service translation.
