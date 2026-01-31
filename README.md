# Kubernetes Networking Performance

Personal lab to compare Kubernetes CNI dataplanes (kindnet, Calico, Cilium) on a repeatable Kind setup. Spins up clusters, deploys Fortio/iperf, runs same-node vs cross-node vs service-path tests, and saves results plus packet captures.

Highlights

- One-liners to create Kind clusters per CNI and deploy test workloads.
- Benchmarks: HTTP (Fortio) and TCP throughput (iperf), summaries in `benchmark/`.
- Captures: pcap traces to inspect encap vs eBPF vs kube-proxy paths.
- Small, readable scripts and kustomize overlays—easy to tweak or extend.

Overall outcomes (Kind lab)

- Fortio (HTTP): Cilium/Calico’s eBPF paths beat kindnet for pod-pod. For service traffic, Cilium and kindnet are about the same; sometimes kindnet gets a few more qps.
- iperf (TCP): On this single-host Kind setup, kindnet wins cross-node throughput, Cilium takes same-node, and Calico trails. Kind’s overhead makes the simple default path hard to beat for raw iperf.
