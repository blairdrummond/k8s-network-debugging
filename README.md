# K8s Network Debugging

Learning about tcpdump, wireshark, and other fun things.

Based on https://faun.pub/capturing-container-traffic-on-kubernetes-ee4a49b833b7

Specifically, we're going to use the approach where we enter the node and use `nsenter` to pop into the networking namespace of the pod, where we'll then use `tcpdump`.

We're going to debug gatekeeper in this case, to make things realistic (also because I have run into this situation before).

# TODO:

I have the k3d cluster configured with `nerdctl` and the `cni` plugins for manipulating the network. I need to:

- Copy down the certificates in the gatekeeper pod
- Execute a `netshoot` container in the same networking namespace as gatekeeper
- Figure out how to use `tcpdump` (or a similar tool) against the data **While using the certificates!**


