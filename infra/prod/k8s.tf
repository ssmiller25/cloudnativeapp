data "civo_instances_size" "small" {
    filter {
        key = "name"
        values = ["g3.k3s.small"]
        match_by = "re"
    }

    filter {
        key = "type"
        values = ["Kubernetes"]
    }

}


resource "civo_kubernetes_cluster" "prod-boutique" {
    name = "prod-boutique"
    applications = "cert-manager, prometheus-operator, loki-stack"
    num_target_nodes = 3
    target_nodes_size = element(data.civo_instances_size.small.sizes, 0).name
}
