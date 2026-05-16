# Lambda + API Gateway X-Ray

This directory creates a minimal REST API and Lambda function with X-Ray enabled only through AWS resource settings.

## What is enabled

- Lambda active tracing
  - `tracing_config { mode = "Active" }`
- Lambda IAM permission to send trace data
  - `AWSXRayDaemonWriteAccess`
- API Gateway REST API stage tracing
  - `xray_tracing_enabled = true`

No X-Ray SDK, OpenTelemetry SDK, CloudWatch Agent, ADOT Collector, or X-Ray daemon is installed in this example.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Call the endpoint from the output:

```bash
curl "$(terraform output -raw api_endpoint)"
```

After a request, open CloudWatch > X-Ray traces or the X-Ray console and search for traces from the API Gateway and Lambda service graph.

## Notes

API Gateway active X-Ray tracing is for REST APIs. HTTP APIs do not expose the same stage-level X-Ray tracing setting.
