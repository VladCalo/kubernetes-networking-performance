# Cilium

Pod → pod (no Service)

- Same node:
  1. pod veth → host veth peer
  2. node BPF (bypass kube-proxy) routes directly
  3. cilium_host → dest pod veth
  4. No encap
- Cross node:
  1. pod veth → host veth peer
  2. node BPF selects remote node, encapsulates (VXLAN/Geneve)
  3. remote node decaps, routes via BPF
  4. cilium_host → dest pod veth
  5. No kube-proxy

Pod → ClusterIP Service

- Same node:
  1. pod veth → host veth peer
  2. node BPF service LB DNATs ClusterIP → pod IP (no iptables)
  3. if backend local: stays on node, cilium_host → dest pod veth (hairpin handled in BPF)
  4. if backend remote: encapsulated to remote node
- Cross node:
  1. pod veth → host veth peer
  2. node BPF LB DNATs to chosen backend pod IP
  3. encapsulate (VXLAN/Geneve) to remote node
  4. remote node decap, cilium_host → dest pod veth

Summary: Without a Service, Cilium stays in BPF for routing (no kube-proxy) and encapsulates only cross-node. With ClusterIP, the BPF service LB DNATs early; packets still use the same BPF datapath, with encapsulation only when the chosen backend is remote.
