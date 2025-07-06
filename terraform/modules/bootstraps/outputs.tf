output "test_rendering" {
  value = file("${path.module}/../../../scripts/bootstrap/helm-deploy-eks.sh")
}