# Iperf Benchmarks: Summary and Conclusions

## What was run
- Automated loop creating Kind clusters for: `default` (kindnet+kube-proxy), `calico`, `cilium`.
- Deployed iperf3 client/server pods on two workers; ran full suite: same-node (w1→w1) and cross-node (w1→w2), P4, ~30s.
- Saved outputs per run in repo root (and eBPF calico in `benchmark/iperf/results/eBPF/calico`).

## Tunings applied
- Calico: eBPF dataplane, kube-proxy disabled in Kind config, encapsulation off (`CALICO_IPV4POOL_IPIP=Never`, `CALICO_IPV4POOL_VXLAN=Never`, CIDR 192.168.0.0/16), BPF kube-proxy cleanup enabled.
- Cilium: kube-proxy replacement, BPF masquerade, native routing; autoDirectNodeRoutes on (tunnel removed); ipv4NativeRoutingCIDR=10.244.0.0/16.
- Default: no tuning (kindnet + kube-proxy).

## Results (latest full runs, P4 ~30s)
- Default: same-node ~13.0 Gbps (retrans ~0.9k); cross-node ~9.6 Gbps (retrans ~1.0k).
- Calico eBPF (no encap): same-node ~12.2 Gbps (retrans ~1.0k); cross-node ~7.8 Gbps (retrans ~1.4k).
- Cilium (native, BPF LB): same-node ~13.3 Gbps (retrans ~64); cross-node ~7.8 Gbps (retrans ~0.95k).

## Conclusions
- On Kind, the simple kindnet+kube-proxy path wins cross-node throughput; eBPF dataplanes add service LB/policy overhead that shows up on single-host Kind.
- Cilium tuning improved same-node throughput and lowered loss, but cross-node still trails default. Calico eBPF improved slightly cross-node but remains behind.
- For fairer comparisons on real hardware, consider MTU/offload tuning and verifying host support; on Kind, expect the lightweight default to be faster in raw iperf.
