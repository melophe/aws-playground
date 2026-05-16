# AWS X-Ray Terraform

This directory creates basic AWS X-Ray resources for hands-on tracing.

## Resources

- `aws_xray_sampling_rule.api_errors`
  - Samples matching requests with a small fixed reservoir and rate.
  - Applies to all services by default so it can be reused with Lambda, API Gateway, ECS, or other instrumented workloads.
- `aws_xray_group.api_errors`
  - Groups traces that contain errors, faults, or throttling.
  - Enables X-Ray Insights for the group.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Override defaults when needed:

```bash
terraform plan -var="env=dev" -var="aws_region=ap-northeast-1"
```

## Notes

X-Ray resources only define sampling and grouping behavior. Your application or AWS service still needs tracing enabled and must send trace data to X-Ray.
