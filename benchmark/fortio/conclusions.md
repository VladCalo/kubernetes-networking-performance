# Fortio Benchmarks — scratch notes (Kind)

What I ran

- For each CNI: spin up Kind, drop Fortio client/server on two workers, hit same-node, cross-node, and service, then tear it down.

Raw numbers (qps / p99)

- Default (kindnet + kube-proxy): same 3172.7 / 90.4 ms; cross 2676.3 / 103.4 ms; svc 4489.6 / 87.5 ms.
- Calico eBPF (kube-proxy off, no encap): same 3536.8 / 92.6 ms; cross 2884.9 / 100.0 ms; svc 4069.1 / 83.9 ms.
- Cilium eBPF: same 3741.1 / 91.2 ms; cross 3212.4 / 100.0 ms; svc 4417.7 / 85.2 ms.


- Cilium wins pod-to-pod (highest same/cross qps, p99 in the pack).
- Default sneaks the top service qps this run; Cilium is basically tied within noise and has slightly better p99; Calico is lower on service qps but keeps tails decent.
- Overall pick: Cilium feels best balanced; Default is fine if you only care about service path; Calico sits between for pod-to-pod and behind on service qps.
- Kind overhead (nested net + CPU contention) keeps absolute numbers lower than “real” clusters, but the ordering should still be directionally valid.

remember: this is Kind, not bare metal/EKS