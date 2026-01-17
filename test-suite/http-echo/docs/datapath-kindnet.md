# Kindnet (default kind CNI)

Pod → pod (no Service)

- Same node:
  1. pod veth → bridge → host
  2. host route to dest pod
  3. bridge → dest pod veth
  4. No kube-proxy; no encap
- Cross node:
  1. pod veth → bridge → host
  2. host route to remote node (added by kind)
  3. packet forwarded to remote node
  4. remote host route to dest pod, bridge → dest pod veth
  5. No kube-proxy

Pod → ClusterIP Service

- Same node:
  1. pod veth → bridge → host
  2. kube-proxy iptables/IPVS DNATs ClusterIP → pod IP
  3. hairpin via host netns; bridge → dest pod veth
- Cross node:
  1. pod veth → bridge → host
  2. kube-proxy DNATs to backend IP
  3. host routes toward remote node
  4. remote host delivers to dest pod via bridge

Summary: Without a Service, kindnet uses simple bridge + host routing; no kube-proxy, no encapsulation. Adding ClusterIP inserts kube-proxy DNAT on the source node; the rest follows the same bridge/host routing, with hairpin for local endpoints.
